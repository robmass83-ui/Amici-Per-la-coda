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

  test('transizioni ammesse: da deceduto verso un altro stato', () {
    for (final to in DogStato.values) {
      expect(
        statoTransitionAllowed(DogStato.deceduto, to),
        to != DogStato.deceduto,
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
    final dog = testDog(stato: DogStato.inRifugio);
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

  test('cambio stato da deceduto a inRifugio toglie dall\'archivio', () {
    final dog = testDog(stato: DogStato.deceduto, archiviato: true);
    final updated = applyDogStato(
      dog: dog,
      stato: DogStato.inRifugio,
      dal: now,
      note: 'Errore di registrazione',
      autoreId: 'uid-1',
      now: now,
    );
    expect(updated.stato, DogStato.inRifugio);
    expect(updated.archiviato, isFalse);
  });

  test('cambio stato da deceduto ad adottato resta in archivio', () {
    final dog = testDog(stato: DogStato.deceduto, archiviato: true);
    final updated = applyDogStato(
      dog: dog,
      stato: DogStato.adottato,
      dal: now,
      note: '',
      autoreId: 'uid-1',
      now: now,
    );
    expect(updated.stato, DogStato.adottato);
    expect(updated.archiviato, isTrue);
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
    expect(dogStatoChoiceTitle(DogStato.trasferito), 'Trasferito ad altra struttura');
    expect(
      dogStatoChoiceSubtitle(DogStato.inStallo),
      'Ospitato da un volontario o famiglia',
    );
  });

  test('applyArchivia marca archiviato e scrive lo storico', () {
    final dog = testDog(stato: DogStato.inRifugio);
    final updated = applyArchivia(dog: dog, autoreId: 'uid-1', now: now);
    expect(updated.archiviato, isTrue);
    expect(updated.stato, DogStato.inRifugio);
    expect(updated.storicoStati.first.note, 'Scheda archiviata');
    final restored = applyRipristina(dog: updated, autoreId: 'uid-1', now: now);
    expect(restored.archiviato, isFalse);
    expect(restored.stato, DogStato.inRifugio);
    expect(
      restored.storicoStati.map((voce) => voce.note),
      containsAll(['Scheda archiviata', 'Scheda ripristinata']),
    );
  });

  test('applyDogStato a deceduto archivia la scheda', () {
    final dog = testDog(stato: DogStato.inRifugio);
    final updated = applyDogStato(
      dog: dog,
      stato: DogStato.deceduto,
      dal: now,
      note: 'Decesso',
      autoreId: 'uid-1',
      now: now,
    );
    expect(updated.stato, DogStato.deceduto);
    expect(updated.archiviato, isTrue);
    expect(updated.storicoStati.first.stato, DogStato.deceduto);
  });

  test('applyDogStato a inStallo non archivia la scheda', () {
    final dog = testDog(stato: DogStato.inRifugio);
    final updated = applyDogStato(
      dog: dog,
      stato: DogStato.inStallo,
      dal: now,
      note: '',
      autoreId: 'uid-1',
      now: now,
    );
    expect(updated.archiviato, isFalse);
  });

  test('uscita definitiva (adottato, trasferito, restituito) archivia', () {
    for (final stato in [
      DogStato.adottato,
      DogStato.restituito,
      DogStato.trasferito,
    ]) {
      final updated = applyDogStato(
        dog: testDog(stato: DogStato.inRifugio),
        stato: stato,
        dal: now,
        note: '',
        autoreId: 'uid-1',
        now: now,
        strutturaDestinazione: stato == DogStato.trasferito
            ? 'Canile di Potenza'
            : null,
      );
      expect(updated.archiviato, isTrue, reason: stato.wire);
    }
  });

  test('dogInArchivio include deceduto anche senza flag', () {
    expect(
      dogInArchivio(testDog(stato: DogStato.deceduto, archiviato: false)),
      isTrue,
    );
    expect(
      dogInArchivio(testDog(stato: DogStato.inRifugio, archiviato: false)),
      isFalse,
    );
    expect(
      dogInArchivio(testDog(stato: DogStato.inRifugio, archiviato: true)),
      isTrue,
    );
  });

  test('applyRipristina riporta in rifugio anche un deceduto senza flag', () {
    final dog = testDog(stato: DogStato.deceduto, archiviato: false);
    final restored = applyRipristina(dog: dog, autoreId: 'uid-1', now: now);
    expect(restored.archiviato, isFalse);
    expect(restored.stato, DogStato.inRifugio);
  });

  test('applyDogStato a trasferito senza struttura è bloccato', () {
    final dog = testDog(stato: DogStato.inRifugio);
    expect(
      () => applyDogStato(
        dog: dog,
        stato: DogStato.trasferito,
        dal: now,
        note: '',
        autoreId: 'uid-1',
        now: now,
      ),
      throwsA(isA<ArgumentError>()),
    );
    final updated = applyDogStato(
      dog: dog,
      stato: DogStato.trasferito,
      dal: now,
      note: 'Spostato',
      autoreId: 'uid-1',
      now: now,
      strutturaDestinazione: 'Canile di Potenza',
    );
    expect(updated.stato, DogStato.trasferito);
    expect(updated.storicoStati.first.strutturaDestinazione, 'Canile di Potenza');
  });
}
