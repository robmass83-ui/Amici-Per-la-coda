import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/volunteer.dart';
import '../../ui/tokens.dart';

String capitalizePersonName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}

String volunteerDisplayName(Volunteer volunteer) {
  final nome = capitalizePersonName(volunteer.nome);
  final cognome = capitalizePersonName(volunteer.cognome);
  if (nome.isEmpty) {
    return cognome;
  }
  if (cognome.isEmpty) {
    return nome;
  }
  return '$nome $cognome';
}

String volunteerRuoloLabel(VolunteerRuolo ruolo) {
  return switch (ruolo) {
    VolunteerRuolo.presidente => 'Proprietario',
    VolunteerRuolo.referente => 'Responsabile',
    VolunteerRuolo.volontario => 'Volontario',
  };
}

/// Ruoli assegnabili dal proprietario quando crea o modifica un volontario.
/// Il ruolo proprietario non si concede dall'app: eviterebbe di creare
/// un secondo account con poteri su utenti e moduli.
const assignableVolunteerRuoli = <VolunteerRuolo>[
  VolunteerRuolo.volontario,
  VolunteerRuolo.referente,
];

bool isAssignableVolunteerRuolo(VolunteerRuolo ruolo) {
  return ruolo != VolunteerRuolo.presidente;
}

String volunteerRuoloPermessi(VolunteerRuolo ruolo) {
  return switch (ruolo) {
    VolunteerRuolo.presidente => 'Tutti i permessi',
    VolunteerRuolo.referente => 'Schede, salute, adozioni',
    VolunteerRuolo.volontario => 'Sola lettura + note',
  };
}

String volunteerRuoloHint(VolunteerRuolo ruolo) {
  return switch (ruolo) {
    VolunteerRuolo.volontario =>
      'Consulta le schede e scrive solo le proprie note. '
      'Non modifica anagrafica, salute, spese, foto né stato dei cani.',
    VolunteerRuolo.referente =>
      'Come il proprietario su cani, adozioni e calendario. '
      'Non gestisce gli utenti, i moduli, né può toccare l\'account del proprietario.',
    VolunteerRuolo.presidente =>
      'Gestisce utenti, moduli e l\'associazione. Non si assegna a un nuovo account.',
  };
}

String volunteerInitials(Volunteer volunteer) {
  final nome = volunteer.nome.trim();
  final cognome = volunteer.cognome.trim();
  if (nome.isNotEmpty && cognome.isNotEmpty) {
    return '${nome[0]}${cognome[0]}'.toUpperCase();
  }
  if (nome.length >= 2) {
    return nome.substring(0, 2).toUpperCase();
  }
  if (nome.isNotEmpty) {
    return nome[0].toUpperCase();
  }
  if (cognome.isNotEmpty) {
    return cognome[0].toUpperCase();
  }
  return '?';
}

Color volunteerAvatarColor(Volunteer volunteer) {
  if (!volunteer.attivo) {
    return AppColor.neutralSoft;
  }
  return parseAvatarColor(volunteer.coloreAvatar) ?? AppColor.green;
}

Color volunteerAvatarForeground(Volunteer volunteer) {
  if (!volunteer.attivo) {
    return AppColor.faint;
  }
  return AppColor.card;
}

Color? parseAvatarColor(String raw) {
  var hex = raw.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 3) {
    hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
  }
  if (hex.length != 6) {
    return null;
  }
  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(0xFF000000 | value);
}

int compareVolunteers(Volunteer a, Volunteer b) {
  if (a.attivo != b.attivo) {
    return a.attivo ? -1 : 1;
  }
  return volunteerDisplayName(
    a,
  ).toLowerCase().compareTo(volunteerDisplayName(b).toLowerCase());
}

bool wouldLeaveZeroActivePresidents({
  required List<Volunteer> volunteers,
  required String id,
  bool? attivo,
  VolunteerRuolo? ruolo,
}) {
  var count = 0;
  for (final volunteer in volunteers) {
    final nextAttivo = volunteer.id == id ? (attivo ?? volunteer.attivo) : volunteer.attivo;
    final nextRuolo = volunteer.id == id ? (ruolo ?? volunteer.ruolo) : volunteer.ruolo;
    if (nextAttivo && nextRuolo == VolunteerRuolo.presidente) {
      count += 1;
    }
  }
  return count == 0;
}

const passwordAlphabet =
    'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';

const avatarPalette = [
  '#157A3C',
  '#2E7FD6',
  '#7B4CC0',
  '#DE8A22',
  '#E04552',
];

String generateInitialPassword([Random? random]) {
  final rng = random ?? Random.secure();
  return String.fromCharCodes(
    List.generate(
      10,
      (_) => passwordAlphabet.codeUnitAt(rng.nextInt(passwordAlphabet.length)),
    ),
  );
}

String nextAvatarColor(int existingCount) {
  return avatarPalette[existingCount % avatarPalette.length];
}

bool looksLikeEmail(String value) {
  return value.contains('@') && value.contains('.');
}

String homeGreeting(String nome) {
  if (nome.isEmpty) {
    return 'Ciao 👋';
  }
  return 'Ciao $nome 👋';
}
