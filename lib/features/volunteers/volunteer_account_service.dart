import '../../core/auth_errors.dart';
import '../../core/firestore_codec.dart';
import '../../data/models/enums.dart';
import '../../data/models/volunteer.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/data_repositories.dart';
import '../dogs/edit_permissions.dart';
import 'volunteer_labels.dart';

class VolunteerAccountException implements Exception {
  const VolunteerAccountException(this.message, {this.inactiveVolunteer});

  final String message;
  final Volunteer? inactiveVolunteer;

  @override
  String toString() => message;
}

class VolunteerAccountService {
  VolunteerAccountService({
    required this.auth,
    required this.volunteers,
  });

  final AuthRepository auth;
  final VolunteerRepository volunteers;

  Future<Volunteer> createVolunteer({
    required String nome,
    required String cognome,
    required String email,
    required String password,
    required VolunteerRuolo ruolo,
    required DateTime now,
  }) async {
    final trimmedNome = nome.trim();
    final trimmedCognome = cognome.trim();
    final trimmedEmail = email.trim();
    if (trimmedNome.isEmpty || trimmedCognome.isEmpty) {
      throw const VolunteerAccountException('Nome e cognome sono obbligatori.');
    }
    if (!looksLikeEmail(trimmedEmail)) {
      throw AuthFailure(italianAuthMessage('invalid-email'));
    }
    if (password.length < 8) {
      throw AuthFailure(italianAuthMessage('weak-password'));
    }
    if (!isAssignableVolunteerRuolo(ruolo)) {
      throw const VolunteerAccountException(
        'Non si può creare un altro proprietario. Scegli Volontario o Responsabile.',
      );
    }
    final existing = await volunteers.watchAll().first;
    for (final volunteer in existing) {
      if (!sameEmail(volunteer.email, trimmedEmail)) {
        continue;
      }
      if (!volunteer.attivo) {
        throw VolunteerAccountException(
          'Il profilo di ${volunteerDisplayName(volunteer)} esiste già ma è '
          'disattivato. Riattivalo dalla scheda, oppure tocca Riattiva account.',
          inactiveVolunteer: volunteer,
        );
      }
      throw AuthFailure(italianAuthMessage('email-already-in-use'));
    }
    final creator = auth.currentUser;
    if (creator == null) {
      throw const VolunteerAccountException('Sessione scaduta. Accedi di nuovo.');
    }
    CreatedAuthUser createdAuth;
    try {
      createdAuth = await auth.createUserAccount(
        email: trimmedEmail,
        password: password,
      );
    } on AuthFailure catch (error) {
      if (!isEmailAlreadyInUse(error)) {
        rethrow;
      }
      createdAuth = await auth.reclaimDeletedAccount(
        email: trimmedEmail,
        password: password,
      );
    }
    final created = Volunteer(
      id: createdAuth.uid,
      nome: trimmedNome,
      cognome: trimmedCognome,
      email: trimmedEmail,
      ruolo: ruolo,
      attivo: true,
      coloreAvatar: nextAvatarColor(existing.length),
      mustChangePassword: true,
      audit: Audit.seed(now, by: creator.uid),
    );
    await volunteers.save(created);
    await _rememberRefreshToken(
      uid: created.id,
      token: createdAuth.refreshToken,
    );
    return created;
  }

  Future<void> saveVolunteer(Volunteer volunteer) {
    return volunteers.save(volunteer);
  }

  Future<void> setAttivo({
    required Volunteer volunteer,
    required bool attivo,
    required String editorUid,
    required DateTime now,
    required List<Volunteer> all,
  }) async {
    if (volunteer.id == editorUid) {
      throw const VolunteerAccountException(
        'Non puoi disattivare il tuo account.',
      );
    }
    if (wouldLeaveZeroActivePresidents(
      volunteers: all,
      id: volunteer.id,
      attivo: attivo,
    )) {
      throw const VolunteerAccountException(
        'Deve restare almeno un presidente attivo.',
      );
    }
    await volunteers.save(
      volunteer.copyWith(
        attivo: attivo,
        audit: volunteer.audit.touched(editorUid, now),
      ),
    );
  }

  Future<void> deleteVolunteer({
    required Volunteer volunteer,
    required String editorUid,
    required List<Volunteer> all,
  }) async {
    if (volunteer.id == editorUid) {
      throw const VolunteerAccountException(
        'Non puoi eliminare il tuo account.',
      );
    }
    if (wouldLeaveZeroActivePresidents(
      volunteers: all,
      id: volunteer.id,
      attivo: false,
    )) {
      throw const VolunteerAccountException(
        'Deve restare almeno un presidente attivo.',
      );
    }
    final token = await volunteers.getAuthRefreshToken(volunteer.id);
    await auth.deleteUserAccount(uid: volunteer.id, refreshToken: token);
    try {
      await volunteers.deleteAuthRefreshToken(volunteer.id);
    } catch (_) {
      // L'accesso Auth è già stato rimosso.
    }
    await volunteers.delete(volunteer.id);
  }

  Future<void> setRuolo({
    required Volunteer volunteer,
    required VolunteerRuolo ruolo,
    required String editorUid,
    required DateTime now,
    required List<Volunteer> all,
  }) async {
    if (volunteer.id == editorUid) {
      throw const VolunteerAccountException(
        'Non puoi cambiare il tuo ruolo.',
      );
    }
    if (!isAssignableVolunteerRuolo(ruolo)) {
      throw const VolunteerAccountException(
        'Non si può promuovere un account a proprietario.',
      );
    }
    if (wouldLeaveZeroActivePresidents(
      volunteers: all,
      id: volunteer.id,
      ruolo: ruolo,
    )) {
      throw const VolunteerAccountException(
        'Deve restare almeno un presidente attivo.',
      );
    }
    await volunteers.save(
      volunteer.copyWith(
        ruolo: ruolo,
        audit: volunteer.audit.touched(editorUid, now),
      ),
    );
  }

  Future<void> recordLogin({
    required String uid,
    required String email,
    required DateTime now,
    String? password,
  }) async {
    var all = await volunteers.watchAll().first;
    all = await _repairCrossedIdentity(
      all,
      uid: uid,
      email: email,
      now: now,
    );
    final volunteer = volunteerForAuth(all, uid: uid, email: email);
    if (volunteer == null || !volunteer.attivo) {
      return;
    }
    try {
      await volunteers.updateSelf(id: uid, ultimoAccesso: now);
    } catch (_) {
      // Offline o regole: il login resta valido.
    }
    if (password != null && password.isNotEmpty) {
      await _captureAndStoreRefreshToken(
        uid: uid,
        email: email,
        password: password,
      );
    }
  }

  /// Se `volunteers/{uid}` ha l'email di un altro e un altro doc ha la nostra,
  /// gli UID Auth sono incrociati: si scambiano le anagrafiche.
  Future<List<Volunteer>> _repairCrossedIdentity(
    List<Volunteer> all, {
    required String uid,
    required String email,
    required DateTime now,
  }) async {
    Volunteer? atUid;
    Volunteer? byEmail;
    for (final item in all) {
      if (item.id == uid) {
        atUid = item;
      }
      if (sameEmail(item.email, email)) {
        byEmail ??= item;
        if (item.id == uid) {
          byEmail = item;
        }
      }
    }
    if (atUid == null ||
        byEmail == null ||
        byEmail.id == uid ||
        sameEmail(atUid.email, email)) {
      return all;
    }
    final correctedAtUid = _anagrafeSu(atUid, byEmail, uid, now);
    final correctedOther = _anagrafeSu(byEmail, atUid, uid, now);
    try {
      await volunteers.save(correctedAtUid);
      await volunteers.save(correctedOther);
    } catch (_) {
      return all;
    }
    return [
      for (final item in all)
        if (item.id == correctedAtUid.id)
          correctedAtUid
        else if (item.id == correctedOther.id)
          correctedOther
        else
          item,
    ];
  }

  static Volunteer _anagrafeSu(
    Volunteer idHolder,
    Volunteer profile,
    String editorUid,
    DateTime now,
  ) {
    return Volunteer(
      id: idHolder.id,
      nome: profile.nome,
      cognome: profile.cognome,
      email: profile.email,
      ruolo: profile.ruolo,
      attivo: profile.attivo,
      coloreAvatar: profile.coloreAvatar,
      mustChangePassword: profile.mustChangePassword,
      ultimoAccesso: profile.ultimoAccesso,
      audit: idHolder.audit.touched(editorUid, now),
    );
  }

  Future<void> completePasswordChange(
    String newPassword, {
    String? currentPassword,
  }) async {
    if (newPassword.length < 8) {
      throw AuthFailure(italianAuthMessage('weak-password'));
    }
    final user = auth.currentUser;
    if (user == null) {
      throw const VolunteerAccountException(
        'Sessione scaduta. Accedi di nuovo.',
      );
    }
    final samePassword = currentPassword != null &&
        currentPassword.isNotEmpty &&
        currentPassword == newPassword;
    if (!samePassword) {
      await auth.updatePassword(
        newPassword,
        currentPassword: currentPassword,
      );
    }
    try {
      await volunteers.updateSelf(
        id: user.uid,
        mustChangePassword: false,
      );
    } on VolunteerAccountException {
      rethrow;
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const VolunteerAccountException(
        'Password aggiornata, ma il profilo non si è sbloccato. Riprova.',
      );
    }
    var updated = await volunteers.getById(user.uid);
    if (updated == null || updated.mustChangePassword) {
      final all = await volunteers.watchAll().first;
      updated = volunteerForAuth(all, uid: user.uid, email: user.email);
    }
    if (updated == null || updated.mustChangePassword) {
      throw const VolunteerAccountException(
        'Password aggiornata, ma il profilo non si è sbloccato. Riprova.',
      );
    }
    await _captureAndStoreRefreshToken(
      uid: user.uid,
      email: user.email,
      password: newPassword,
    );
  }

  Future<void> _rememberRefreshToken({
    required String uid,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await volunteers.saveAuthRefreshToken(id: uid, token: token);
    } catch (_) {
      // Offline o regole: l'account è creato comunque.
    }
  }

  Future<void> _captureAndStoreRefreshToken({
    required String uid,
    required String email,
    required String password,
  }) async {
    try {
      final token = await auth.captureRefreshToken(
        email: email,
        password: password,
      );
      await _rememberRefreshToken(uid: uid, token: token);
    } catch (_) {
      // Login o cambio password restano validi.
    }
  }
}
