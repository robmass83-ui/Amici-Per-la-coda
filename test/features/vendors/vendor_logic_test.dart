import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/vendor.dart';
import 'package:amici_per_la_coda/features/vendors/vendor_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final audit = Audit.seed(DateTime.utc(2026, 1, 1));

  test('orfano da visita è Veterinario, da spesa è Altro', () {
    final list = mergeVendorList(
      vendors: const [],
      health: [testHealth(veterinario: 'Datena')],
      expenses: [testExpense(fornitore: 'Agraria')],
    );
    expect(list.map((e) => e.nome).toList()..sort(), ['Agraria', 'Datena']);
    expect(
      list.firstWhere((e) => e.nome == 'Datena').tipo,
      VendorTipo.veterinario,
    );
    expect(list.firstWhere((e) => e.nome == 'Datena').saved, isNull);
    expect(
      list.firstWhere((e) => e.nome == 'Agraria').tipo,
      VendorTipo.altro,
    );
  });

  test('nome già in vendors non è orfano', () {
    final saved = Vendor(
      id: 'v1',
      nome: 'Datena Anna Maria',
      tipo: VendorTipo.clinica,
      telefono: '1',
      email: '',
      indirizzo: '',
      convenzionato: false,
      note: '',
      audit: audit,
    );
    final list = mergeVendorList(
      vendors: [saved],
      health: [testHealth(veterinario: 'datena anna maria')],
      expenses: const [],
    );
    expect(list, hasLength(1));
    expect(list.single.saved?.id, 'v1');
    expect(list.single.tipo, VendorTipo.clinica);
  });
}
