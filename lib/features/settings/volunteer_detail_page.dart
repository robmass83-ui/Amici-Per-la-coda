import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_errors.dart';
import '../../core/format_it.dart';
import '../../data/models/enums.dart';
import '../../data/models/volunteer.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/record_actions.dart';
import '../volunteers/volunteer_account_service.dart';
import '../volunteers/volunteer_labels.dart';
import '../volunteers/volunteer_privilege_picker.dart';
import '../volunteers/volunteer_providers.dart';

// ── CONTRATTO DI LAYOUT · Modifica volontario (AppDialog) ─────────────────────
// Header  AppIcons.volontari  displayName
// Body  gap 8
// ├ FormRow2  NOME * | COGNOME *
// ├ EMAIL  sola lettura
// ├ VolunteerPrivilegePicker  se non è sé stesso né proprietario
// ├ AppButton ghost  Invia email di reset password
// ├ Disattiva / Riattiva  (assente sul proprio)
// ├ Elimina account  (assente sul proprio)
// └ Ultimo accesso  10sp muted
// Footer  Annulla | Salva
// ───────────────────────────────────────────────────────────────────────────

class VolunteerDetailPage extends ConsumerStatefulWidget {
  const VolunteerDetailPage({super.key, required this.volunteerId});

  final String volunteerId;

  static const nomeKey = Key('volunteer-detail-nome');
  static const cognomeKey = Key('volunteer-detail-cognome');
  static const emailKey = Key('volunteer-detail-email');
  static const ruoloKey = Key('volunteer-detail-ruolo');
  static const resetKey = Key('volunteer-detail-reset');
  static const disattivaKey = Key('volunteer-detail-disattiva');
  static const riattivaKey = Key('volunteer-detail-riattiva');
  static const eliminaKey = Key('volunteer-detail-elimina');
  static const salvaKey = Key('volunteer-detail-salva');
  static const ultimoAccessoKey = Key('volunteer-detail-ultimo-accesso');
  static const listKey = Key('volunteer-detail-list');

  static Future<void> show(BuildContext context, String volunteerId) {
    return AppDialog.show<void>(
      context: context,
      form: VolunteerDetailPage(volunteerId: volunteerId),
    );
  }

  @override
  ConsumerState<VolunteerDetailPage> createState() =>
      _VolunteerDetailPageState();
}

class _VolunteerDetailPageState extends ConsumerState<VolunteerDetailPage> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _email = TextEditingController();
  String? _loadedId;
  VolunteerRuolo _ruolo = VolunteerRuolo.volontario;
  String? _error;
  var _saving = false;
  String _initial = '';

  @override
  void initState() {
    super.initState();
    for (final controller in [_nome, _cognome]) {
      controller.addListener(_mark);
    }
  }

  @override
  void dispose() {
    for (final controller in [_nome, _cognome]) {
      controller.removeListener(_mark);
    }
    _nome.dispose();
    _cognome.dispose();
    _email.dispose();
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() => '${_nome.text}|${_cognome.text}|${_ruolo.wire}';

  @override
  Widget build(BuildContext context) {
    final volunteers = ref.watch(volunteersStreamProvider).maybeWhen(
      data: (items) => items,
      orElse: () => const <Volunteer>[],
    );
    Volunteer? volunteer;
    for (final item in volunteers) {
      if (item.id == widget.volunteerId) {
        volunteer = item;
        break;
      }
    }
    if (volunteer != null && _loadedId != volunteer.id) {
      _loadedId = volunteer.id;
      _nome.text = volunteer.nome;
      _cognome.text = volunteer.cognome;
      _email.text = volunteer.email;
      _ruolo = volunteer.ruolo;
      _initial = _snapshot();
    }
    final current = ref.watch(currentVolunteerProvider);
    final isSelf = current?.id == volunteer?.id;
    final title = volunteer == null
        ? 'Volontario'
        : volunteerDisplayName(volunteer);
    final canSave =
        volunteer != null &&
        _nome.text.trim().isNotEmpty &&
        _cognome.text.trim().isNotEmpty;

    return AppDialog(
      icon: AppIcons.volontari,
      title: title,
      canSave: canSave,
      isDirty: volunteer != null && _snapshot() != _initial,
      saving: _saving,
      saveKey: VolunteerDetailPage.salvaKey,
      onSave: volunteer == null
          ? () async {}
          : () => _save(volunteer!, volunteers, isSelf),
      body: volunteer == null
          ? const EmptyState(
              icon: IconBadge(AppIcons.volontari),
              message: 'Volontario non trovato.',
            )
          : Column(
              key: VolunteerDetailPage.listKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormRow2(
                  left: AppFormField(
                    key: VolunteerDetailPage.nomeKey,
                    label: 'Nome *',
                    controller: _nome,
                  ),
                  right: AppFormField(
                    key: VolunteerDetailPage.cognomeKey,
                    label: 'Cognome *',
                    controller: _cognome,
                  ),
                ),
                const DialogBodyGap(),
                AppFormField(
                  key: VolunteerDetailPage.emailKey,
                  label: 'Email',
                  controller: _email,
                  readOnly: true,
                ),
                if (!isSelf && volunteer.ruolo != VolunteerRuolo.presidente) ...[
                  const DialogBodyGap(),
                  VolunteerPrivilegePicker(
                    key: VolunteerDetailPage.ruoloKey,
                    selected: _ruolo,
                    onChanged: (ruolo) => setState(() => _ruolo = ruolo),
                  ),
                ],
                const DialogBodyGap(),
                AppButton(
                  key: VolunteerDetailPage.resetKey,
                  label: 'Invia email di reset password',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => unawaited(_reset(volunteer!)),
                ),
                if (!isSelf) ...[
                  const DialogBodyGap(),
                  if (volunteer.attivo)
                    AppButton(
                      key: VolunteerDetailPage.disattivaKey,
                      label: 'Disattiva account',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => unawaited(
                        _setAttivo(volunteer!, false, volunteers),
                      ),
                    )
                  else
                    AppButton(
                      key: VolunteerDetailPage.riattivaKey,
                      label: 'Riattiva account',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => unawaited(
                        _setAttivo(volunteer!, true, volunteers),
                      ),
                    ),
                  const DialogBodyGap(),
                  AppButton(
                    key: VolunteerDetailPage.eliminaKey,
                    label: 'Elimina account',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => unawaited(
                      _elimina(volunteer!, volunteers),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const DialogBodyGap(),
                  Text(
                    _error!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      color: AppColor.red,
                      height: AppDim.lineH,
                    ),
                  ),
                ],
                const SizedBox(height: AppDim.gapL),
                Text(
                  key: VolunteerDetailPage.ultimoAccessoKey,
                  volunteer.ultimoAccesso == null
                      ? 'Ultimo accesso: mai'
                      : 'Ultimo accesso: ${formatItalianDate(volunteer.ultimoAccesso!)}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _save(
    Volunteer volunteer,
    List<Volunteer> all,
    bool isSelf,
  ) async {
    final nome = _nome.text.trim();
    final cognome = _cognome.text.trim();
    if (nome.isEmpty || cognome.isEmpty) {
      setState(() => _error = 'Nome e cognome sono obbligatori.');
      return;
    }
    final service = ref.read(volunteerAccountServiceProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    if (service == null) {
      setState(() => _error = 'Archivio non disponibile.');
      return;
    }
    setState(() => _saving = true);
    try {
      final nextRuolo =
          isSelf || volunteer.ruolo == VolunteerRuolo.presidente
          ? volunteer.ruolo
          : _ruolo;
      if (volunteer.ruolo != VolunteerRuolo.presidente &&
          !isAssignableVolunteerRuolo(nextRuolo)) {
        throw const VolunteerAccountException(
          'Non si può promuovere un account a proprietario.',
        );
      }
      if (wouldLeaveZeroActivePresidents(
        volunteers: all,
        id: volunteer.id,
        ruolo: nextRuolo,
      )) {
        throw const VolunteerAccountException(
          'Deve restare almeno un presidente attivo.',
        );
      }
      await service.saveVolunteer(
        volunteer.copyWith(
          nome: nome,
          cognome: cognome,
          ruolo: nextRuolo,
          audit: volunteer.audit.touched(uid, now),
        ),
      );
      if (mounted) {
        setState(() {
          _error = null;
          _initial = _snapshot();
        });
        AppToast.show(context, 'Scheda aggiornata.');
        Navigator.of(context, rootNavigator: true).pop();
      }
    } on VolunteerAccountException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _reset(Volunteer volunteer) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: volunteer.email);
      if (mounted) {
        AppToast.show(context, 'Email di reimpostazione inviata.');
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _setAttivo(
    Volunteer volunteer,
    bool attivo,
    List<Volunteer> all,
  ) async {
    if (!attivo) {
      final ok = await confirmAction(
        context: context,
        title: 'Disattiva account',
        message: 'Disattivare l\'account di ${volunteerDisplayName(volunteer)}?',
        confirmLabel: 'Disattiva',
      );
      if (!ok) {
        return;
      }
    }
    final service = ref.read(volunteerAccountServiceProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (service == null) {
      setState(() => _error = 'Archivio non disponibile.');
      return;
    }
    try {
      await service.setAttivo(
        volunteer: volunteer,
        attivo: attivo,
        editorUid: uid,
        now: ref.read(dogListNowProvider),
        all: all,
      );
      if (mounted) {
        setState(() => _error = null);
        AppToast.show(
          context,
          attivo ? 'Account riattivato.' : 'Account disattivato.',
        );
      }
    } on VolunteerAccountException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _elimina(Volunteer volunteer, List<Volunteer> all) async {
    final nome = volunteerDisplayName(volunteer);
    final ok = await confirmAction(
      context: context,
      title: 'Elimina account',
      message: 'Eliminare definitivamente l\'account di $nome? Sparisce '
          'dall\'elenco, non potrà più accedere e l\'email potrà essere '
          'usata di nuovo.',
      confirmLabel: 'Elimina',
    );
    if (!ok) {
      return;
    }
    final service = ref.read(volunteerAccountServiceProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (service == null) {
      setState(() => _error = 'Archivio non disponibile.');
      return;
    }
    setState(() => _error = null);
    try {
      await service.deleteVolunteer(
        volunteer: volunteer,
        editorUid: uid,
        all: all,
      );
      if (!mounted) {
        return;
      }
      AppToast.show(context, 'Account di $nome eliminato.');
      Navigator.of(context, rootNavigator: true).pop();
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on VolunteerAccountException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }
}
