import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/adoptions/adoption_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  test('avanzando a preaffido il cane passa in preaffido e non è adottabile', () {
    final dog = testDog(id: 'luna', adottabile: true);
    var adoption = testAdoption(
      id: 'ad1',
      dogId: 'luna',
      stato: AdoptionStato.visita,
    );

    final toColloquio = advanceAdoption(
      adoption: testAdoption(
        id: 'ad1',
        dogId: 'luna',
        stato: AdoptionStato.ricevuta,
      ),
      dog: dog,
      now: now,
      autoreId: 'uid-1',
    );
    expect(toColloquio.adoption.stato, AdoptionStato.colloquio);
    expect(toColloquio.dog.stato, DogStato.inRifugio);

    final toVisita = advanceAdoption(
      adoption: toColloquio.adoption,
      dog: toColloquio.dog,
      now: now,
      autoreId: 'uid-1',
    );
    expect(toVisita.adoption.stato, AdoptionStato.visita);

    final result = advanceAdoption(
      adoption: adoption,
      dog: dog,
      now: now,
      autoreId: 'uid-1',
    );
    expect(result.adoption.stato, AdoptionStato.preaffido);
    expect(result.dog.stato, DogStato.preaffido);
    expect(result.dog.adottabile, isFalse);
    expect(result.adoption.preaffidoDal, now);
    expect(
      result.adoption.preaffidoAl,
      now.add(const Duration(days: preaffidoDurataGg)),
    );
  });

  test('respingendo una richiesta in preaffido il cane torna adottabile', () {
    final dog = testDog(
      id: 'otto',
      stato: DogStato.preaffido,
      adottabile: false,
    );
    final adoption = testAdoption(
      id: 'ad1',
      dogId: 'otto',
      stato: AdoptionStato.preaffido,
    );
    final result = rejectAdoption(
      adoption: adoption,
      dog: dog,
      now: now,
      autoreId: 'uid-1',
    );
    expect(result.adoption.stato, AdoptionStato.respinta);
    expect(result.dog.adottabile, isTrue);
    expect(result.dog.stato, DogStato.inRifugio);
  });

  test('findMatchingAdopter trova per telefono o email', () {
    final marta = testAdopter(
      id: 'adp1',
      nome: 'Marta',
      telefono: '320 111 2233',
      email: 'marta@mail.it',
    );
    expect(
      findMatchingAdopter(
        [marta],
        telefono: '3201112233',
        email: '',
      )?.id,
      'adp1',
    );
    expect(
      findMatchingAdopter(
        [marta],
        telefono: '',
        email: 'MARTA@mail.it',
      )?.id,
      'adp1',
    );
    expect(
      findMatchingAdopter([marta], telefono: '111', email: 'altro@mail.it'),
      isNull,
    );
  });
}
