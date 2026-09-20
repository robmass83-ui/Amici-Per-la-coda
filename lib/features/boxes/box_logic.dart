import '../../data/dog_archive.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/shelter_box.dart';
import '../../ui/components.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';

String boxTipoLabel(BoxTipo tipo) {
  return switch (tipo) {
    BoxTipo.normale => 'Normale',
    BoxTipo.degenza => 'Degenza',
    BoxTipo.isolamento => 'Isolamento',
    BoxTipo.quarantena => 'Quarantena',
  };
}

String boxCodice(ShelterBox box) {
  return '${box.settore.trim()}${box.numero.trim()}';
}

String settoreTitle(String settore) {
  final name = settore.trim();
  if (name.isEmpty) {
    return 'Senza settore';
  }
  return 'Settore $name';
}

AppIconSpec boxIcona(ShelterBox box) {
  return AppIcons.perBox(box.tipo.wire);
}

List<Dog> caniNelBox(ShelterBox box, List<Dog> dogs) {
  return [
    for (final dog in dogs)
      if (!dogEsclusoDaConteggiRifugio(dog) &&
          dog.settore == box.settore &&
          dog.box == box.numero)
        dog,
  ];
}

String boxOccupantiLabel(ShelterBox box, List<Dog> dogs) {
  if (box.inManutenzione) {
    return 'Manutenzione';
  }
  final names = [
    for (final dog in caniNelBox(box, dogs)) dogDisplayName(dog.nome),
  ].where((name) => name.isNotEmpty).toList();
  if (names.isEmpty) {
    return 'Libero';
  }
  return names.join(', ');
}

String boxFillLabel(ShelterBox box, List<Dog> dogs) {
  if (box.inManutenzione) {
    return '—';
  }
  return '${occupantiDelBox(box, dogs)}/${box.capienza}';
}

MiniBadgeVariant boxFillVariant(ShelterBox box, List<Dog> dogs) {
  if (box.inManutenzione) {
    return MiniBadgeVariant.neutral;
  }
  final n = occupantiDelBox(box, dogs);
  if (n <= 0) {
    return MiniBadgeVariant.green;
  }
  if (n >= box.capienza) {
    return MiniBadgeVariant.red;
  }
  return MiniBadgeVariant.orange;
}

int postiLiberiDelBox(ShelterBox box, List<Dog> dogs, {String? ignoreDogId}) {
  var n = occupantiDelBox(box, dogs);
  if (ignoreDogId != null) {
    for (final dog in dogs) {
      if (dog.id == ignoreDogId &&
          dog.settore == box.settore &&
          dog.box == box.numero) {
        n--;
        break;
      }
    }
  }
  final free = box.capienza - n;
  return free < 0 ? 0 : free;
}

bool boxPuoOspitare(
  ShelterBox box,
  List<Dog> dogs, {
  String? ignoreDogId,
}) {
  if (box.inManutenzione) {
    return false;
  }
  return postiLiberiDelBox(box, dogs, ignoreDogId: ignoreDogId) > 0;
}

String messaggioBoxPieno(ShelterBox box, List<Dog> dogs) {
  final n = occupantiDelBox(box, dogs);
  return 'Il box ${boxCodice(box)} è pieno ($n/${box.capienza}). '
      'Scegli un box con un posto libero.';
}

List<String> settoriNormaliDi(List<ShelterBox> boxes) {
  final seen = <String>{};
  final out = <String>[];
  for (final box in boxes) {
    if (box.tipo != BoxTipo.normale) {
      continue;
    }
    final name = box.settore.trim();
    if (name.isEmpty || seen.contains(name)) {
      continue;
    }
    seen.add(name);
    out.add(name);
  }
  out.sort();
  return out;
}

List<ShelterBox> boxesDelSettore(List<ShelterBox> boxes, String settore) {
  final out = [
    for (final box in boxes)
      if (box.tipo == BoxTipo.normale && box.settore.trim() == settore) box,
  ];
  out.sort((a, b) => a.numero.compareTo(b.numero));
  return out;
}

List<ShelterBox> boxesInfermeria(List<ShelterBox> boxes) {
  final out = [
    for (final box in boxes)
      if (box.tipo != BoxTipo.normale) box,
  ];
  out.sort((a, b) {
    final byTipo = a.tipo.index.compareTo(b.tipo.index);
    if (byTipo != 0) {
      return byTipo;
    }
    return boxCodice(a).compareTo(boxCodice(b));
  });
  return out;
}

String nuovoBoxId(String settore, String numero) {
  final raw = '${settore.trim()}_${numero.trim()}'
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  if (raw.isEmpty || raw == '_') {
    return 'box_${DateTime.now().microsecondsSinceEpoch}';
  }
  return raw;
}
