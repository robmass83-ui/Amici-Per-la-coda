import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/documents/documenti_groups.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

AppDocument _doc({
  required String id,
  required String? dogId,
  required DateTime when,
  String nome = 'File',
}) {
  return AppDocument(
    id: id,
    dogId: dogId,
    adoptionId: null,
    adopterId: '',
    tipo: DocumentTipo.altro,
    nome: nome,
    mime: 'application/pdf',
    chunkCount: 0,
    contenutoB64: 'YQ==',
    caricatoIl: when,
    caricatoDa: 'uid-1',
  );
}

void main() {
  test('i documenti si raggruppano per cane, A-Z, più recenti prima', () {
    final groups = groupDocumentsByDog(
      dogs: [
        testDog(id: 'brando', nome: 'Brando'),
        testDog(id: 'fenice', nome: 'Fenice'),
      ],
      documents: [
        _doc(
          id: 'f-old',
          dogId: 'fenice',
          when: DateTime(2026, 9, 1),
          nome: 'Vecchio',
        ),
        _doc(
          id: 'f-new',
          dogId: 'fenice',
          when: DateTime(2026, 9, 10),
          nome: 'Nuovo',
        ),
        _doc(
          id: 'b1',
          dogId: 'brando',
          when: DateTime(2026, 9, 5),
          nome: 'Brando file',
        ),
        _doc(
          id: 'x',
          dogId: null,
          when: DateTime(2026, 9, 8),
          nome: 'Senza cane',
        ),
      ],
    );
    expect(groups, hasLength(3));
    expect(groups[0].dogName, 'Brando');
    expect(groups[1].dogName, 'Fenice');
    expect(groups[1].documents.map((d) => d.id), ['f-new', 'f-old']);
    expect(groups[2].dogName, 'Altri documenti');
    expect(groups[2].documents.single.nome, 'Senza cane');
  });
}
