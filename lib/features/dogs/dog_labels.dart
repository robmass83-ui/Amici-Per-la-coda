import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';

String dogSexLabel(DogSex sex) {
  return switch (sex) {
    DogSex.F => 'Femmina',
    DogSex.M => 'Maschio',
  };
}

String dogStatoLabel(DogStato stato) {
  return switch (stato) {
    DogStato.inRifugio => 'In rifugio',
    DogStato.inStallo => 'In stallo',
    DogStato.preaffido => 'Preaffido',
    DogStato.adottato => 'Adottato',
    DogStato.inCura => 'In cura',
    DogStato.restituito => 'Restituito',
    DogStato.deceduto => 'Deceduto',
  };
}

MiniBadgeVariant dogStatoBadge(DogStato stato) {
  return switch (stato) {
    DogStato.inRifugio => MiniBadgeVariant.green,
    DogStato.inStallo => MiniBadgeVariant.blue,
    DogStato.preaffido => MiniBadgeVariant.orange,
    DogStato.adottato => MiniBadgeVariant.purple,
    DogStato.inCura => MiniBadgeVariant.red,
    DogStato.restituito => MiniBadgeVariant.neutral,
    DogStato.deceduto => MiniBadgeVariant.neutral,
  };
}

String dogListSubtitle(Dog dog, {required DateTime now}) {
  final parts = <String>[
    if (dog.razza.isNotEmpty) dog.razza,
    dogSexLabel(dog.sesso),
    ?dogAgeShortLabel(dog, now),
  ];
  return parts.join(' · ');
}

String dogSterilizedLabel(Dog dog) {
  return dog.sesso == DogSex.F ? 'Sterilizzata' : 'Sterilizzato';
}

String tagliaLabel(Taglia taglia) {
  return switch (taglia) {
    Taglia.piccola => 'Piccola',
    Taglia.media => 'Media',
    Taglia.grande => 'Grande',
  };
}

String yesNo(bool value) => value ? 'Sì' : 'No';

String dashIfEmpty(String value) => value.trim().isEmpty ? '—' : value.trim();

String dogDisplayName(String nome) {
  return nome.replaceFirst(RegExp(r'^\[PROVA\]\s*'), '').trim();
}

String carattereLabel(List<String> tags) {
  if (tags.isEmpty) {
    return '—';
  }
  return tags.join(', ');
}

String conPersoneLabel(ConPersone value) {
  return switch (value) {
    ConPersone.moltoSocievole => 'Molto socievole',
    ConPersone.selettivo => 'Selettivo',
    ConPersone.diffidente => 'Diffidente',
  };
}

String conCaniLabel(ConCani value) {
  return switch (value) {
    ConCani.si => 'Sì',
    ConCani.selettivo => 'Selettivo',
    ConCani.no => 'No',
    ConCani.daTestare => 'Da testare',
  };
}

String conGattiLabel(ConGatti value) {
  return switch (value) {
    ConGatti.si => 'Sì',
    ConGatti.no => 'No',
    ConGatti.daTestare => 'Da testare',
  };
}

String conBambiniLabel(ConBambini value) {
  return switch (value) {
    ConBambini.si => 'Sì',
    ConBambini.soloGrandi => 'Solo grandi',
    ConBambini.no => 'No',
    ConBambini.daTestare => 'Da testare',
  };
}

String iscrittoAnagrafeLabel(IscrittoAnagrafe value) {
  return switch (value) {
    IscrittoAnagrafe.si => 'Sì',
    IscrittoAnagrafe.no => 'No',
    IscrittoAnagrafe.daVerificare => 'Da verificare',
  };
}

String modalitaIngressoLabel(ModalitaIngresso value) {
  return switch (value) {
    ModalitaIngresso.vagante => 'Recupero cane vagante',
    ModalitaIngresso.sequestro => 'Sequestro',
    ModalitaIngresso.rinuncia => 'Rinuncia',
    ModalitaIngresso.natoInRifugio => 'Nato in rifugio',
    ModalitaIngresso.trasferimento => 'Trasferimento',
  };
}

String boxAssegnatoLabel(String settore, String box) {
  if (settore.trim().isEmpty && box.trim().isEmpty) {
    return 'Nessun box';
  }
  if (settore.trim().isEmpty) {
    return box.trim();
  }
  if (box.trim().isEmpty) {
    return settore.trim();
  }
  return '${settore.trim()} · ${box.trim()}';
}

String dogPesoLabel(double? pesoKg) {
  if (pesoKg == null) {
    return '—';
  }
  return 'Circa ${formatItalianNumber(pesoKg)} kg';
}

String dogRazzaTagliaLabel(Dog dog) {
  final taglia = 'Taglia ${tagliaLabel(dog.taglia).toLowerCase()}';
  if (dog.razza.isEmpty) {
    return taglia;
  }
  return '${dog.razza}  |  $taglia';
}

String dogAgeDetailLabel(Dog dog, DateTime now) {
  final age = dogAgeShortLabel(dog, now, compact: false);
  final birth = dog.dataNascita;
  if (age == null && birth == null) {
    return '—';
  }
  if (birth == null) {
    return age ?? '—';
  }
  final precision = dog.nascitaPresunta ? 'presunta' : 'certa';
  final birthBit = '(${formatItalianDate(birth)} $precision)';
  if (age == null) {
    return birthBit;
  }
  return '$age\n$birthBit';
}

String? dogAgeShortLabel(Dog dog, DateTime now, {bool compact = true}) {
  final birth = dog.dataNascita;
  if (birth == null) {
    return null;
  }
  final days = now.difference(birth).inDays;
  if (days < 0) {
    return null;
  }
  final prefix = dog.nascitaPresunta ? (compact ? '~' : 'Circa ') : '';
  if (days < 365) {
    final months = (days / 30).floor().clamp(1, 11);
    return months == 1 ? '${prefix}1 mese' : '$prefix$months mesi';
  }
  final years = days ~/ 365;
  final extraMonths = (days % 365) ~/ 30;
  final half = extraMonths >= 5 ? ' e mezzo' : '';
  if (years == 1) {
    return '${prefix}1 anno$half';
  }
  return '$prefix$years anni$half';
}
