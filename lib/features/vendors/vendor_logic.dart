import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../data/models/vendor.dart';

class VendorEntry {
  const VendorEntry({required this.nome, required this.origine});

  final String nome;
  final String origine;
}

List<VendorEntry> vendorsFrom({
  required List<HealthRecord> health,
  required List<Expense> expenses,
}) {
  final map = <String, VendorEntry>{};
  for (final record in health) {
    final nome = record.veterinario.trim();
    if (nome.isEmpty) {
      continue;
    }
    map.putIfAbsent(
      nome.toLowerCase(),
      () => VendorEntry(nome: nome, origine: 'Veterinario'),
    );
  }
  for (final item in expenses) {
    final nome = item.fornitore.trim();
    if (nome.isEmpty) {
      continue;
    }
    map.putIfAbsent(
      nome.toLowerCase(),
      () => VendorEntry(nome: nome, origine: 'Fornitore'),
    );
  }
  final list = map.values.toList()
    ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  return list;
}

class VendorListItem {
  const VendorListItem({
    required this.nome,
    required this.tipo,
    this.saved,
  });

  final String nome;
  final VendorTipo tipo;
  final Vendor? saved;
}

String vendorTipoLabel(VendorTipo tipo) => switch (tipo) {
  VendorTipo.veterinario => 'Veterinario',
  VendorTipo.clinica => 'Clinica',
  VendorTipo.farmacia => 'Farmacia',
  VendorTipo.negozio => 'Negozio',
  VendorTipo.toelettatura => 'Toelettatura',
  VendorTipo.altro => 'Altro',
};

List<VendorListItem> mergeVendorList({
  required List<Vendor> vendors,
  required List<HealthRecord> health,
  required List<Expense> expenses,
}) {
  final map = <String, VendorListItem>{};
  for (final vendor in vendors) {
    final key = vendor.nome.trim().toLowerCase();
    if (key.isEmpty) {
      continue;
    }
    map[key] = VendorListItem(
      nome: vendor.nome,
      tipo: vendor.tipo,
      saved: vendor,
    );
  }
  for (final record in health) {
    final nome = record.veterinario.trim();
    if (nome.isEmpty) {
      continue;
    }
    map.putIfAbsent(
      nome.toLowerCase(),
      () => VendorListItem(nome: nome, tipo: VendorTipo.veterinario),
    );
  }
  for (final item in expenses) {
    final nome = item.fornitore.trim();
    if (nome.isEmpty) {
      continue;
    }
    map.putIfAbsent(
      nome.toLowerCase(),
      () => VendorListItem(nome: nome, tipo: VendorTipo.altro),
    );
  }
  final list = map.values.toList()
    ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  return list;
}
