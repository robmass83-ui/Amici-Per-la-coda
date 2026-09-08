import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/dog_labels.dart';
import 'package:amici_per_la_coda/features/dogs/dog_stato.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  test('transizioni ammesse: da rifugio verso qualsiasi altro stato', () {
    for (final to in DogStato.values) {
      expect(
        statoTransitionAllowed(DogStato.inRifugio, to),
        to != DogStato.inRifugio,
        reason: 'in_rifugio → ${to.wire}',
      );
    }
  });

  test('transizioni ammesse: deceduto è terminale', () {
    for (final to in DogStato.values) {
      expect(
        statoTransitionAllowed(DogStato.deceduto, to),
        isFalse,
        reason: 'deceduto → ${to.wire}',
      );
    }
  });

  test('stesso stato non è una transizione', () {
    for (final stato in DogStato.values) {
      expect(statoTransitionAllowed(stato, stato), isFalse);
    }
  });

  test('adottato e deceduto richiedono conferma', () {
    expect(statoRequiresConfirmation(DogStato.adottato), isTrue);
    expect(statoRequiresConfirmation(DogStato.deceduto), isTrue);
    expect(statoRequiresConfirmation(DogStato.inStallo), isFalse);
    expect(statoRequiresConfirmation(DogStato.preaffido), isFalse);
  });

  test('applyDogStato aggiorna stato, statoDal e prepende lo storico', () {
    final dog = testDog(stato: DogStato.inRifugio);
    final updated = applyDogStato(
      dog: dog,
      stato: DogStato.inStallo,
      dal: now,
      note: 'Trasferita da Giovanna',
      autoreId: 'uid-1',
      now: now,
    );

    expect(updated.stato, DogStato.inStallo);
    expect(updated.statoDal, now);
    expect(updated.storicoStati.first.stato, DogStato.inStallo);
    expect(updated.storicoStati.first.note, 'Trasferita da Giovanna');
    expect(updated.storicoStati.first.autoreId, 'uid-1');
    expect(updated.audit.updatedBy, 'uid-1');
    expect(updated.audit.updatedAt, now);
  });

  test('applyDogStato rifiuta una transizione non ammessa', () {
    final dog = testDog(stato: DogStato.deceduto);
    expect(
      () => applyDogStato(
        dog: dog,
        stato: DogStato.inRifugio,
        dal: now,
        note: '',
        autoreId: 'uid-1',
        now: now,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('storico oltre 30 voci: restano le più recenti', () {
    final storico = [
      for (var i = 0; i < storicoStatiMax; i++)
        StatoVoce(
          stato: DogStato.inRifugio,
          dal: DateTime.utc(2020, 1, 1).add(Duration(days: i)),
          note: 'v$i',
          autoreId: 'test',
        ),
    ];
    final newest = StatoVoce(
      stato: DogStato.inStallo,
      dal: DateTime.utc(2026, 9, 8),
      note: 'nuova',
      autoreId: 'uid-1',
    );
    final next = appendStoricoStato(storico, newest);
    expect(next, hasLength(storicoStatiMax));
    expect(next.first.note, 'nuova');
    expect(next.any((voce) => voce.note == 'v0'), isFalse);
  });

  test('dettaglio giorni e etichette di scelta', () {
    final dog = testDog(
      settore: 'B',
      box: '7',
      stato: DogStato.inRifugio,
    );
    expect(
      statoDalDettaglio(dog, now),
      'Settore B · Box 7 · dal 25/06/2024 (805 giorni)',
    );
    expect(dogStatoChoiceTitle(DogStato.preaffido), 'In preaffido');
    expect(dogStatoChoiceTitle(DogStato.inCura), 'In cura / degenza');
    expect(
      dogStatoChoiceSubtitle(DogStato.inStallo),
      'Ospitato da un volontario o famiglia',
    );
  });
}
