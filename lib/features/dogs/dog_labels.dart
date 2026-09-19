import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';

String dogSexLabel(DogSex? sex) {
  return switch (sex) {
    DogSex.F => 'Femmina',
    DogSex.M => 'Maschio',
    null => '—',
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
    DogStato.trasferito => 'Trasferito',
  };
}

String dogStatoChoiceTitle(DogStato stato) {
  return switch (stato) {
    DogStato.inRifugio => 'In rifugio',
    DogStato.inStallo => 'In stallo',
    DogStato.preaffido => 'In preaffido',
    DogStato.adottato => 'Adottato',
    DogStato.inCura => 'In cura / degenza',
    DogStato.restituito => 'Restituito al proprietario',
    DogStato.deceduto => 'Deceduto',
    DogStato.trasferito => 'Trasferito ad altra struttura',
  };
}

String dogStatoChoiceSubtitle(DogStato stato) {
  return switch (stato) {
    DogStato.inRifugio => 'Presente in struttura',
    DogStato.inStallo => 'Ospitato da un volontario o famiglia',
    DogStato.preaffido => 'Periodo di prova 30 giorni',
    DogStato.adottato => 'Adozione definitiva conclusa',
    DogStato.inCura => 'Presso clinica veterinaria',
    DogStato.restituito => 'Cane smarrito ritrovato',
    DogStato.deceduto => 'Archivia la scheda con data',
    DogStato.trasferito => 'Lascia il rifugio per un\'altra struttura',
  };
}

String statoDalDettaglio(Dog dog, DateTime now) {
  final days = now.difference(dog.statoDal).inDays;
  final giorni = days == 1 ? '1 giorno' : '$days giorni';
  return [
    if (dog.settore.isNotEmpty) 'Settore ${dog.settore}',
    if (dog.box.isNotEmpty) 'Box ${dog.box}',
    'dal ${formatItalianDate(dog.statoDal)} ($giorni)',
  ].join(' · ');
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
    DogStato.trasferito => MiniBadgeVariant.neutral,
  };
}

String dogListSubtitle(Dog dog, {required DateTime now}) {
  final parts = <String>[
    if (dog.razza.isNotEmpty) dog.razza,
    'Taglia ${tagliaLabel(dog.taglia).toLowerCase()}',
    dogSexLabel(dog.sesso),
    ?dogAgeShortLabel(dog, now),
  ];
  return parts.join(' · ');
}

String dogSterilizedLabel(Dog dog) {
  return dogSituazioneValue(dog);
}

String dogSituazioneValue(Dog dog) {
  if (dog.sterilizzato == null) {
    return '—';
  }
  final female = dog.sesso == DogSex.F;
  if (dog.sterilizzato == true) {
    return female ? 'Sterilizzata' : 'Castrato';
  }
  return female ? 'Intera' : 'Intero';
}

String tagliaLabel(Taglia taglia) {
  return switch (taglia) {
    Taglia.piccola => 'Piccola',
    Taglia.media => 'Media',
    Taglia.grande => 'Grande',
  };
}

String yesNo(bool? value) => switch (value) {
  true => 'Sì',
  false => 'No',
  null => '—',
};

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

String conPersoneLabel(ConPersone? value) {
  return switch (value) {
    ConPersone.moltoSocievole => 'Molto socievole',
    ConPersone.selettivo => 'Selettivo',
    ConPersone.diffidente => 'Diffidente',
    null => '—',
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

String modalitaIngressoLabel(ModalitaIngresso? value) {
  return switch (value) {
    ModalitaIngresso.vagante => 'Recupero cane vagante',
    ModalitaIngresso.sequestro => 'Sequestro',
    ModalitaIngresso.rinuncia => 'Rinuncia',
    ModalitaIngresso.natoInRifugio => 'Nato in rifugio',
    ModalitaIngresso.trasferimento => 'Trasferimento',
    null => '—',
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

String dogIngressoLabel(Dog dog) {
  final date = formatItalianDate(dog.dataIngresso);
  return dog.dataIngressoStimata ? '$date (stimata)' : date;
}

String tipoPeloLabel(TipoPelo? value) {
  return switch (value) {
    TipoPelo.corto => 'Corto',
    TipoPelo.medio => 'Medio',
    TipoPelo.lungo => 'Lungo',
    TipoPelo.nonIndicato => 'Non indicato',
    null => '—',
  };
}

String purezzaLabel(Purezza? value) {
  return switch (value) {
    Purezza.meticcio => 'Meticcio',
    Purezza.inPurezza => 'In purezza',
    null => '—',
  };
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

String dogGalleryCountLabel(Dog dog) {
  final n = dog.fotoCount;
  if (n > 0) {
    return n == 1 ? '1 foto' : '$n foto';
  }
  if (dog.fotoCopertinaId != null && dog.fotoCopertinaId!.isNotEmpty) {
    return 'Foto';
  }
  return 'Nessuna copertina';
}
