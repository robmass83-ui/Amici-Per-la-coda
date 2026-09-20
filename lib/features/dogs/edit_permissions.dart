import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../../data/models/volunteer.dart';

String normalizeEmail(String? value) => value?.trim().toLowerCase() ?? '';

bool sameEmail(String? a, String? b) {
  final left = normalizeEmail(a);
  final right = normalizeEmail(b);
  return left.isNotEmpty && left == right;
}

/// Collega l'utente Auth al documento in `volunteers`.
/// L'identità è l'email di login: se `volunteers/{uid}` ha un'altra email
/// (UID incrociati), si usa il documento con l'email giusta, non quello
/// dell'UID. Poi UID coerente, poi parte locale unica (seed con altro dominio).
Volunteer? volunteerForAuth(
  List<Volunteer> volunteers, {
  required String uid,
  String? email,
}) {
  final needle = normalizeEmail(email);

  Volunteer? byUid;
  for (final item in volunteers) {
    if (item.id == uid) {
      byUid = item;
      break;
    }
  }

  if (needle.isNotEmpty) {
    Volunteer? byEmail;
    for (final item in volunteers) {
      if (normalizeEmail(item.email) != needle) {
        continue;
      }
      if (item.id == uid) {
        return item;
      }
      byEmail ??= item;
    }
    if (byEmail != null) {
      return byEmail;
    }
  }

  if (byUid != null) {
    final volEmail = normalizeEmail(byUid.email);
    if (needle.isEmpty || volEmail.isEmpty || volEmail == needle) {
      return byUid;
    }
  }

  if (needle.isEmpty) {
    return null;
  }
  final authLocal = needle.split('@').first;
  if (authLocal.isEmpty) {
    return null;
  }
  Volunteer? byLocal;
  var hits = 0;
  for (final item in volunteers) {
    final itemLocal = normalizeEmail(item.email).split('@').first;
    if (itemLocal.isNotEmpty && itemLocal == authLocal) {
      byLocal = item;
      hits++;
    }
  }
  if (hits == 1) {
    return byLocal;
  }
  return null;
}

/// Nome da mostrare in home: anagrafe volontario, altrimenti email.
String greetingName({Volunteer? volunteer, String? email}) {
  final fromVolunteer = capitalizeFirst(volunteer?.nome.trim() ?? '');
  if (fromVolunteer.isNotEmpty) {
    return fromVolunteer;
  }
  return greetingNameFromEmail(email);
}

String capitalizeFirst(String raw) {
  if (raw.isEmpty) {
    return '';
  }
  return '${raw[0].toUpperCase()}${raw.substring(1)}';
}

String greetingNameFromEmail(String? email) {
  final local = (email ?? '').trim().split('@').first;
  if (local.isEmpty) {
    return '';
  }
  final parts = local
      .split(RegExp(r'[._+\-]+'))
      .where((part) => part.isNotEmpty);
  final words = [
    for (final part in parts)
      '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
  ];
  if (words.isEmpty) {
    return '';
  }
  return words.join(' ');
}

/// Presidente e referente attivi scrivono anagrafe, salute, spese, foto, stato.
/// Senza documento in `volunteers` non c'è alcun diritto di scrittura.
bool canWriteRecords(Volunteer? volunteer) {
  if (volunteer == null || !volunteer.attivo) {
    return false;
  }
  final ruolo = volunteer.ruolo;
  return ruolo == VolunteerRuolo.presidente ||
      ruolo == VolunteerRuolo.referente;
}

/// Solo il presidente attivo modifica associazione, utenti, backup e switch.
bool canManageSettings(Volunteer? volunteer) {
  return volunteer != null &&
      volunteer.attivo &&
      volunteer.ruolo == VolunteerRuolo.presidente;
}

/// Qualunque volontario attivo in anagrafe può creare una nota; chi non c'è, no.
bool canCreateNotes(Volunteer? volunteer) {
  return volunteer != null && volunteer.attivo;
}

bool canEditNote(Volunteer? volunteer, Note note) {
  if (volunteer == null || !volunteer.attivo) {
    return false;
  }
  if (canWriteRecords(volunteer)) {
    return true;
  }
  return volunteer.ruolo == VolunteerRuolo.volontario &&
      note.autoreId == volunteer.id;
}
