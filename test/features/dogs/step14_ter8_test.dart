import 'dart:math';

import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/auth/change_password_page.dart';
import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dogs/edit_permissions.dart';
import 'package:amici_per_la_coda/features/dogs/record_actions.dart';
import 'package:amici_per_la_coda/features/settings/altro_page.dart';
import 'package:amici_per_la_coda/features/settings/new_volunteer_sheet.dart';
import 'package:amici_per_la_coda/features/settings/users_card.dart';
import 'package:amici_per_la_coda/features/settings/volunteer_detail_page.dart';
import 'package:amici_per_la_coda/features/volunteers/volunteer_account_service.dart';
import 'package:amici_per_la_coda/features/volunteers/volunteer_labels.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);

  Finder horizontalScrollables() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Scrollable || widget.axis != Axis.horizontal) {
        return false;
      }
      return widget.restorationId != 'editable';
    });
  }

  Future<FakeAuthRepository> pumpLogged(
    WidgetTester tester, {
    String location = AppRoutes.impostazioni,
    Size size = const Size(360, 1600),
    InMemoryVolunteerRepository? volunteers,
    FakeAuthRepository? auth,
  }) async {
    final session = auth ?? FakeAuthRepository();
    if (session.currentUser == null) {
      await session.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
    }
    await pumpApp(
      tester,
      auth: session,
      initialLocation: location,
      size: size,
      dogs: InMemoryDogRepository(testListDogs()),
      volunteers: volunteers ?? InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );
    return session;
  }

  test('password iniziale: 10 caratteri senza ambiguità', () {
    final password = generateInitialPassword(Random(1));
    expect(password.length, 10);
    expect(password.contains(RegExp(r'[0O1lI]')), isFalse);
    for (final char in password.split('')) {
      expect(passwordAlphabet.contains(char), isTrue);
    }
  });

  test('greetingName rende maiuscola l\'iniziale', () {
    expect(
      greetingName(volunteer: testVolunteer(nome: 'marco')),
      'Marco',
    );
    expect(homeGreeting('Marco'), 'Ciao Marco 👋');
    expect(homeGreeting(''), 'Ciao 👋');
  });

  testWidgets(
    '1-2. creare un volontario non cambia la sessione e scrive il documento',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([testVolunteer()]);
      final auth = await pumpLogged(tester, volunteers: volunteers);
      final uidPrima = auth.currentUser!.uid;

      await tester.ensureVisible(find.byKey(UsersCard.nuovoKey));
      await tester.tap(find.byKey(UsersCard.nuovoKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(NewVolunteerSheet.nomeKey), 'Luca');
      await tester.enterText(find.byKey(NewVolunteerSheet.cognomeKey), 'Bianchi');
      await tester.enterText(
        find.byKey(NewVolunteerSheet.emailKey),
        'luca.bianchi@amiciperlacoda.it',
      );
      await tester.enterText(
        find.byKey(NewVolunteerSheet.passwordKey),
        'password1',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(NewVolunteerSheet.creaKey));
      await tester.tap(find.byKey(NewVolunteerSheet.creaKey));
      await tester.pumpAndSettle();

      expect(auth.currentUser!.uid, uidPrima);
      expect(find.textContaining('Account creato per Luca Bianchi'), findsOneWidget);
      final created = volunteers.items.where(
        (item) => item.email == 'luca.bianchi@amiciperlacoda.it',
      );
      expect(created, hasLength(1));
      expect(created.first.mustChangePassword, isTrue);
      expect(created.first.attivo, isTrue);
      expect(created.first.audit.createdBy, uidPrima);
      expect(created.first.ruolo, VolunteerRuolo.volontario);
    },
  );

  testWidgets(
    'password troppo corta: avviso visibile e Crea account disattivato',
    (tester) async {
      await pumpLogged(
        tester,
        volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      );
      await tester.ensureVisible(find.byKey(UsersCard.nuovoKey));
      await tester.tap(find.byKey(UsersCard.nuovoKey));
      await tester.pumpAndSettle();

      expect(find.byKey(NewVolunteerSheet.passwordHintKey), findsOneWidget);
      expect(
        find.textContaining('Almeno 8 caratteri'),
        findsWidgets,
      );
      expect(
        find.textContaining('Crea account resta disattivato'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(NewVolunteerSheet.nomeKey), 'Luca');
      await tester.enterText(find.byKey(NewVolunteerSheet.cognomeKey), 'Neri');
      await tester.enterText(
        find.byKey(NewVolunteerSheet.emailKey),
        'luca.neri@amiciperlacoda.it',
      );
      await tester.enterText(find.byKey(NewVolunteerSheet.passwordKey), 'corta');
      await tester.pump();

      expect(
        find.textContaining('La password inserita è troppo corta'),
        findsOneWidget,
      );
      expect(find.textContaining('non si può creare l\'account'), findsOneWidget);
      await tester.tap(find.byKey(NewVolunteerSheet.creaKey));
      await tester.pumpAndSettle();
      expect(find.byType(NewVolunteerSheet), findsOneWidget);

      await tester.enterText(
        find.byKey(NewVolunteerSheet.passwordKey),
        'password1',
      );
      await tester.pump();
      expect(find.byKey(NewVolunteerSheet.passwordHintKey), findsNothing);
      expect(
        find.textContaining('La password inserita è troppo corta'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'privilegi: Volontario o Responsabile, mai un secondo proprietario',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([testVolunteer()]);
      await pumpLogged(tester, volunteers: volunteers);

      await tester.ensureVisible(find.byKey(UsersCard.nuovoKey));
      await tester.tap(find.byKey(UsersCard.nuovoKey));
      await tester.pumpAndSettle();
      expect(find.text('Volontario'), findsWidgets);
      expect(find.text('Responsabile'), findsWidgets);
      expect(find.text('Presidente'), findsNothing);
      expect(find.text('Proprietario'), findsWidgets);
      expect(
        find.textContaining('Consulta le schede e scrive solo le proprie note'),
        findsOneWidget,
      );

      await tester.tap(find.text('Responsabile').last);
      await tester.pump();
      expect(
        find.textContaining('Come il proprietario su cani, adozioni e calendario'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(NewVolunteerSheet.nomeKey), 'Sara');
      await tester.enterText(find.byKey(NewVolunteerSheet.cognomeKey), 'Conti');
      await tester.enterText(
        find.byKey(NewVolunteerSheet.emailKey),
        'sara.conti@amiciperlacoda.it',
      );
      await tester.enterText(
        find.byKey(NewVolunteerSheet.passwordKey),
        'password1',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(NewVolunteerSheet.creaKey));
      await tester.tap(find.byKey(NewVolunteerSheet.creaKey));
      await tester.pumpAndSettle();

      final created = volunteers.items.singleWhere(
        (item) => item.email == 'sara.conti@amiciperlacoda.it',
      );
      expect(created.ruolo, VolunteerRuolo.referente);
      expect(canWriteRecords(created), isTrue);
      expect(
        canWriteRecords(testVolunteer(ruolo: VolunteerRuolo.volontario)),
        isFalse,
      );
    },
  );

  test('non si può creare né promuovere un proprietario dall\'app', () async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final volunteers = InMemoryVolunteerRepository([testVolunteer()]);
    final service = VolunteerAccountService(
      auth: auth,
      volunteers: volunteers,
    );
    await expectLater(
      service.createVolunteer(
        nome: 'Altro',
        cognome: 'Dono',
        email: 'altro.dono@amiciperlacoda.it',
        password: 'password1',
        ruolo: VolunteerRuolo.presidente,
        now: now,
      ),
      throwsA(
        isA<VolunteerAccountException>().having(
          (error) => error.message,
          'message',
          contains('altro proprietario'),
        ),
      ),
    );
    expect(volunteers.items, hasLength(1));
    await expectLater(
      service.setRuolo(
        volunteer: testVolunteer(
          id: 'uid-2',
          nome: 'Marco',
          ruolo: VolunteerRuolo.volontario,
        ),
        ruolo: VolunteerRuolo.presidente,
        editorUid: 'uid-1',
        now: now,
        all: volunteers.items,
      ),
      throwsA(
        isA<VolunteerAccountException>().having(
          (error) => error.message,
          'message',
          contains('proprietario'),
        ),
      ),
    );
  });

  test('recordLogin ripara anagrafiche con UID Auth incrociati', () async {
    final auth = FakeAuthRepository(
      validEmail: 'robmass83@gmail.com',
      uid: 'uid-roberto',
    );
    await auth.signIn(email: 'robmass83@gmail.com', password: 'corretta');
    final volunteers = InMemoryVolunteerRepository([
      testVolunteer(
        id: 'uid-roberto',
        nome: 'Giovanna',
        email: 'giovannacacciuto@hotmail.it',
      ),
      testVolunteer(
        id: 'uid-giovanna',
        nome: 'Roberto',
        email: 'robmass83@gmail.com',
      ),
    ]);
    final service = VolunteerAccountService(
      auth: auth,
      volunteers: volunteers,
    );
    await service.recordLogin(
      uid: 'uid-roberto',
      email: 'robmass83@gmail.com',
      now: now,
    );
    expect(
      volunteers.items.firstWhere((item) => item.id == 'uid-roberto').nome,
      'Roberto',
    );
    expect(
      volunteers.items.firstWhere((item) => item.id == 'uid-roberto').email,
      'robmass83@gmail.com',
    );
    expect(
      volunteers.items.firstWhere((item) => item.id == 'uid-giovanna').nome,
      'Giovanna',
    );
    expect(
      volunteers.items.firstWhere((item) => item.id == 'uid-giovanna').email,
      'giovannacacciuto@hotmail.it',
    );
  });

  testWidgets(
    '3. email già in uso: messaggio italiano, nessun documento nuovo',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([testVolunteer()]);
      await pumpLogged(tester, volunteers: volunteers);

      await tester.ensureVisible(find.byKey(UsersCard.nuovoKey));
      await tester.tap(find.byKey(UsersCard.nuovoKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(NewVolunteerSheet.nomeKey), 'Altra');
      await tester.enterText(find.byKey(NewVolunteerSheet.cognomeKey), 'Giovanna');
      await tester.enterText(
        find.byKey(NewVolunteerSheet.emailKey),
        'giovanna@amiciperlacoda.it',
      );
      await tester.enterText(
        find.byKey(NewVolunteerSheet.passwordKey),
        'password1',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(NewVolunteerSheet.creaKey));
      await tester.tap(find.byKey(NewVolunteerSheet.creaKey));
      await tester.pumpAndSettle();

      expect(find.text('Questa email è già registrata.'), findsOneWidget);
      expect(volunteers.items, hasLength(1));
      expect(find.byType(NewVolunteerSheet), findsOneWidget);
    },
  );

  test(
    'email di un profilo disattivato: non crea un secondo account',
    () async {
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      final inactive = testVolunteer(
        id: 'uid-2',
        nome: 'Giangino',
        cognome: 'Filfo',
        email: 'robmass83+v@gmail.com',
        ruolo: VolunteerRuolo.volontario,
        attivo: false,
      );
      final volunteers = InMemoryVolunteerRepository([
        testVolunteer(),
        inactive,
      ]);
      final service = VolunteerAccountService(
        auth: auth,
        volunteers: volunteers,
      );
      await expectLater(
        service.createVolunteer(
          nome: 'Giangino',
          cognome: 'Filfo',
          email: 'robmass83+v@gmail.com',
          password: 'password1',
          ruolo: VolunteerRuolo.volontario,
          now: now,
        ),
        throwsA(
          isA<VolunteerAccountException>()
              .having(
                (error) => error.message,
                'message',
                contains('disattivato'),
              )
              .having(
                (error) => error.inactiveVolunteer?.id,
                'inactiveVolunteer',
                'uid-2',
              ),
        ),
      );
      expect(volunteers.items, hasLength(2));
    },
  );

  testWidgets(
    'profilo disattivato: il foglio propone Riattiva account',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([
        testVolunteer(),
        testVolunteer(
          id: 'uid-2',
          nome: 'Giangino',
          cognome: 'Filfo',
          email: 'robmass83+v@gmail.com',
          ruolo: VolunteerRuolo.volontario,
          attivo: false,
        ),
      ]);
      await pumpLogged(tester, volunteers: volunteers);
      await tester.ensureVisible(find.byKey(UsersCard.nuovoKey));
      await tester.tap(find.byKey(UsersCard.nuovoKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(NewVolunteerSheet.nomeKey), 'Giangino');
      await tester.enterText(find.byKey(NewVolunteerSheet.cognomeKey), 'Filfo');
      await tester.enterText(
        find.byKey(NewVolunteerSheet.emailKey),
        'robmass83+v@gmail.com',
      );
      await tester.enterText(
        find.byKey(NewVolunteerSheet.passwordKey),
        'password1',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(NewVolunteerSheet.creaKey));
      await tester.tap(find.byKey(NewVolunteerSheet.creaKey));
      await tester.pumpAndSettle();

      expect(find.textContaining('esiste già ma è disattivato'), findsOneWidget);
      expect(find.byKey(NewVolunteerSheet.riattivaKey), findsOneWidget);
      await tester.tap(find.byKey(NewVolunteerSheet.riattivaKey));
      await tester.pumpAndSettle();

      expect(
        volunteers.items.firstWhere((item) => item.id == 'uid-2').attivo,
        isTrue,
      );
      expect(find.byType(NewVolunteerSheet), findsNothing);
      expect(
        find.textContaining('Account di Giangino Filfo riattivato'),
        findsOneWidget,
      );
    },
  );

  test('dopo l\'eliminazione la stessa email si può creare di nuovo', () async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final volunteers = InMemoryVolunteerRepository([testVolunteer()]);
    final service = VolunteerAccountService(
      auth: auth,
      volunteers: volunteers,
    );
    final created = await service.createVolunteer(
      nome: 'Giangino',
      cognome: 'Filfo',
      email: 'robmass83+v@gmail.com',
      password: 'Sardegna83',
      ruolo: VolunteerRuolo.volontario,
      now: now,
    );
    await service.deleteVolunteer(
      volunteer: created,
      editorUid: 'uid-1',
      all: volunteers.items,
    );
    expect(volunteers.items.where((item) => item.id == created.id), isEmpty);
    final recreated = await service.createVolunteer(
      nome: 'Giangino',
      cognome: 'Filfo',
      email: 'robmass83+v@gmail.com',
      password: 'AltraPass1',
      ruolo: VolunteerRuolo.volontario,
      now: now,
    );
    expect(recreated.email, 'robmass83+v@gmail.com');
    expect(recreated.attivo, isTrue);
    expect(recreated.id, isNot(created.id));
  });

  test(
    'email Auth orfana con la stessa password si recupera in creazione',
    () async {
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      await auth.createUserAccount(
        email: 'orfano@amiciperlacoda.it',
        password: 'password1',
      );
      final volunteers = InMemoryVolunteerRepository([testVolunteer()]);
      final service = VolunteerAccountService(
        auth: auth,
        volunteers: volunteers,
      );
      final created = await service.createVolunteer(
        nome: 'Luca',
        cognome: 'Orfano',
        email: 'orfano@amiciperlacoda.it',
        password: 'password1',
        ruolo: VolunteerRuolo.volontario,
        now: now,
      );
      expect(created.email, 'orfano@amiciperlacoda.it');
      expect(volunteers.items.where((item) => item.email == created.email), hasLength(1));
    },
  );

  testWidgets('4. un referente non vede la sezione Utenti', (tester) async {
    final auth = FakeAuthRepository(
      validEmail: 'marco@amiciperlacoda.it',
      uid: 'uid-marco',
    );
    await auth.signIn(
      email: 'marco@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.impostazioni,
      size: const Size(360, 1100),
      dogs: InMemoryDogRepository(testListDogs()),
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(),
        testVolunteer(
          id: 'uid-marco',
          nome: 'Marco',
          email: 'marco@amiciperlacoda.it',
          ruolo: VolunteerRuolo.referente,
        ),
      ]),
      dogListNow: now,
    );
    expect(find.byKey(UsersCard.cardKey), findsNothing);
    expect(find.text('Utenti'), findsNothing);
    expect(find.byKey(UsersCard.nuovoKey), findsNothing);
  });

  testWidgets(
    '5. disattivato: riga ingrigita e al login vede Account disattivato',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([testVolunteer()]);
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      final service = VolunteerAccountService(
        auth: auth,
        volunteers: volunteers,
      );
      final created = await service.createVolunteer(
        nome: 'Luca',
        cognome: 'Neri',
        email: 'luca.neri@amiciperlacoda.it',
        password: 'password1',
        ruolo: VolunteerRuolo.volontario,
        now: now,
      );
      await service.setAttivo(
        volunteer: created,
        attivo: false,
        editorUid: 'uid-1',
        now: now,
        all: volunteers.items,
      );
      expect(
        volunteers.items.firstWhere((item) => item.id == created.id).attivo,
        isFalse,
      );

      await pumpLogged(tester, auth: auth, volunteers: volunteers);
      expect(find.text('Disattivato'), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.signIn(
        email: 'luca.neri@amiciperlacoda.it',
        password: 'password1',
      );
      await tester.pumpAndSettle();
      expect(find.text('Account disattivato'), findsOneWidget);
      expect(find.byKey(HomePage.accountDeactivatedKey), findsOneWidget);
      expect(find.textContaining('Ciao'), findsNothing);
      expect(find.byType(AppBottomNav), findsNothing);
    },
  );

  test('6. disattivare l\'ultimo presidente attivo viene rifiutato', () async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final president = testVolunteer();
    final volunteers = InMemoryVolunteerRepository([president]);
    final service = VolunteerAccountService(
      auth: auth,
      volunteers: volunteers,
    );
    expect(
      wouldLeaveZeroActivePresidents(
        volunteers: volunteers.items,
        id: president.id,
        attivo: false,
      ),
      isTrue,
    );
    await expectLater(
      service.setAttivo(
        volunteer: president,
        attivo: false,
        editorUid: 'altro-uid',
        now: now,
        all: volunteers.items,
      ),
      throwsA(
        isA<VolunteerAccountException>().having(
          (error) => error.message,
          'message',
          'Deve restare almeno un presidente attivo.',
        ),
      ),
    );
    expect(volunteers.items.single.attivo, isTrue);
  });

  test('eliminare l\'ultimo presidente attivo viene rifiutato', () async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final president = testVolunteer();
    final volunteers = InMemoryVolunteerRepository([president]);
    final service = VolunteerAccountService(
      auth: auth,
      volunteers: volunteers,
    );
    await expectLater(
      service.deleteVolunteer(
        volunteer: president,
        editorUid: 'altro-uid',
        all: volunteers.items,
      ),
      throwsA(
        isA<VolunteerAccountException>().having(
          (error) => error.message,
          'message',
          'Deve restare almeno un presidente attivo.',
        ),
      ),
    );
    expect(volunteers.items, hasLength(1));
  });

  test('non puoi eliminare il tuo account', () async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final volunteers = InMemoryVolunteerRepository([
      testVolunteer(),
      testVolunteer(
        id: 'uid-2',
        nome: 'Marzia',
        ruolo: VolunteerRuolo.referente,
      ),
    ]);
    final service = VolunteerAccountService(
      auth: auth,
      volunteers: volunteers,
    );
    await expectLater(
      service.deleteVolunteer(
        volunteer: testVolunteer(),
        editorUid: 'uid-1',
        all: volunteers.items,
      ),
      throwsA(
        isA<VolunteerAccountException>().having(
          (error) => error.message,
          'message',
          'Non puoi eliminare il tuo account.',
        ),
      ),
    );
    expect(volunteers.items, hasLength(2));
  });

  testWidgets(
    '7. il presidente non vede Disattiva né il ruolo su sé stesso',
    (tester) async {
      await pumpLogged(tester);
      await tester.tap(find.byKey(UsersCard.rowKey('uid-1')));
      await tester.pumpAndSettle();
      expect(find.byType(VolunteerDetailPage), findsOneWidget);
      expect(find.byKey(VolunteerDetailPage.disattivaKey), findsNothing);
      expect(find.byKey(VolunteerDetailPage.ruoloKey), findsNothing);
      expect(find.byKey(VolunteerDetailPage.riattivaKey), findsNothing);
      expect(find.byKey(VolunteerDetailPage.eliminaKey), findsNothing);
    },
  );

  testWidgets(
    'un account non più in uso si elimina dall\'elenco, non solo si disattiva',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([
        testVolunteer(),
        testVolunteer(
          id: 'uid-2',
          nome: 'Marzia',
          cognome: 'Masala',
          email: 'marzia@amiciperlacoda.it',
          ruolo: VolunteerRuolo.referente,
          attivo: false,
        ),
      ]);
      await pumpLogged(tester, volunteers: volunteers);
      await tester.ensureVisible(find.byKey(UsersCard.rowKey('uid-2')));
      await tester.tap(find.byKey(UsersCard.rowKey('uid-2')));
      await tester.pumpAndSettle();
      expect(find.byType(VolunteerDetailPage), findsOneWidget);
      expect(find.byKey(VolunteerDetailPage.riattivaKey), findsOneWidget);
      expect(find.byKey(VolunteerDetailPage.eliminaKey), findsOneWidget);

      await tester.ensureVisible(find.byKey(VolunteerDetailPage.eliminaKey));
      await tester.tap(find.byKey(VolunteerDetailPage.eliminaKey));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Eliminare definitivamente l\'account di Marzia Masala'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ConfirmActionKeys.confirm));
      await tester.pumpAndSettle();

      expect(volunteers.items.where((item) => item.id == 'uid-2'), isEmpty);
      expect(find.byType(VolunteerDetailPage), findsNothing);
      expect(find.textContaining('Account di Marzia Masala eliminato'), findsOneWidget);
      expect(find.text('Marzia Masala'), findsNothing);
    },
  );

  testWidgets(
    '8. mustChangePassword porta al cambio password, poi alla home',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([
        testVolunteer(mustChangePassword: true),
      ]);
      await pumpLogged(
        tester,
        location: AppRoutes.home,
        volunteers: volunteers,
      );
      expect(find.byType(ChangePasswordPage), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
      expect(find.byTooltip('Indietro'), findsNothing);

      await tester.enterText(
        find.byKey(ChangePasswordPage.nuovaKey),
        'nuovapass',
      );
      await tester.enterText(
        find.byKey(ChangePasswordPage.ripetiKey),
        'nuovapass',
      );
      await tester.tap(find.byKey(ChangePasswordPage.salvaKey));
      await tester.pumpAndSettle();

      expect(volunteers.items.single.mustChangePassword, isFalse);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Ciao Giovanna 👋'), findsOneWidget);
    },
  );

  test(
    'stessa password del login: il flag si azzera senza chiamare Auth',
    () async {
      final volunteers = InMemoryVolunteerRepository([
        testVolunteer(mustChangePassword: true),
      ]);
      final auth = FakeAuthRepository();
      auth.updatePasswordError = Exception('stessa password');
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      final service = VolunteerAccountService(
        auth: auth,
        volunteers: volunteers,
      );
      await service.completePasswordChange(
        'corretta',
        currentPassword: 'corretta',
      );
      expect(auth.updatePasswordCalls, 0);
      expect(volunteers.items.single.mustChangePassword, isFalse);
    },
  );

  testWidgets(
    'dopo logout il cambio password non viene chiesto di nuovo',
    (tester) async {
      final volunteers = InMemoryVolunteerRepository([
        testVolunteer(mustChangePassword: true),
      ]);
      final auth = FakeAuthRepository();
      await pumpLogged(
        tester,
        location: AppRoutes.home,
        auth: auth,
        volunteers: volunteers,
        size: const Size(360, 900),
      );
      expect(find.byType(ChangePasswordPage), findsOneWidget);

      await tester.enterText(
        find.byKey(ChangePasswordPage.nuovaKey),
        'corretta',
      );
      await tester.enterText(
        find.byKey(ChangePasswordPage.ripetiKey),
        'corretta',
      );
      await tester.tap(find.byKey(ChangePasswordPage.salvaKey));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(volunteers.items.single.mustChangePassword, isFalse);

      await tester.tap(find.text('Altro'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(AltroPage.esciKey),
        80,
        scrollable: find.descendant(
          of: find.byKey(AltroPage.listKey),
          matching: find.byType(Scrollable),
        ),
      );
      tester.widget<OptionRow>(find.byKey(AltroPage.esciKey)).onTap();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(0),
        'giovanna@amiciperlacoda.it',
      );
      await tester.enterText(find.byType(TextField).at(1), 'corretta');
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  test('completePasswordChange azzera il flag sul documento Auth', () async {
    final volunteers = InMemoryVolunteerRepository([
      testVolunteer(mustChangePassword: true),
    ]);
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final service = VolunteerAccountService(
      auth: auth,
      volunteers: volunteers,
    );
    await service.completePasswordChange('nuovapass');
    expect(volunteers.items.single.mustChangePassword, isFalse);
  });

  testWidgets(
    'se il cambio password fallisce resta sulla pagina con l\'errore',
    (tester) async {
      final auth = FakeAuthRepository();
      auth.updatePasswordError = Exception('piattaforma');
      await pumpLogged(
        tester,
        location: AppRoutes.home,
        auth: auth,
        volunteers: InMemoryVolunteerRepository([
          testVolunteer(mustChangePassword: true),
        ]),
      );
      expect(find.byType(ChangePasswordPage), findsOneWidget);

      await tester.enterText(
        find.byKey(ChangePasswordPage.nuovaKey),
        'nuovapass',
      );
      await tester.enterText(
        find.byKey(ChangePasswordPage.ripetiKey),
        'nuovapass',
      );
      await tester.tap(find.byKey(ChangePasswordPage.salvaKey));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordPage), findsOneWidget);
      expect(
        find.text('Non è stato possibile salvare la password. Riprova.'),
        findsOneWidget,
      );
      expect(find.byType(HomePage), findsNothing);
    },
  );

  testWidgets(
    'Esci dalla schermata password torna al login',
    (tester) async {
      final auth = FakeAuthRepository();
      await pumpLogged(
        tester,
        location: AppRoutes.home,
        auth: auth,
        volunteers: InMemoryVolunteerRepository([
          testVolunteer(mustChangePassword: true),
        ]),
      );
      expect(find.byType(ChangePasswordPage), findsOneWidget);
      expect(find.byKey(ChangePasswordPage.esciKey), findsOneWidget);

      await tester.tap(find.byKey(ChangePasswordPage.esciKey));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNull);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(ChangePasswordPage), findsNothing);
    },
  );

  test(
    'sblocco fallisce se il documento volontario non è sull\'uid Auth',
    () async {
      final volunteers = InMemoryVolunteerRepository([
        testVolunteer(id: 'altro-id', mustChangePassword: true),
      ]);
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      final service = VolunteerAccountService(
        auth: auth,
        volunteers: volunteers,
      );
      expect(
        () => service.completePasswordChange('nuovapass'),
        throwsA(
          isA<VolunteerAccountException>().having(
            (error) => error.message,
            'message',
            contains('profilo non si è sbloccato'),
          ),
        ),
      );
      expect(volunteers.items.single.mustChangePassword, isTrue);
    },
  );

  testWidgets('9. Home: nome "marco" diventa Ciao Marco', (tester) async {
    final marcoAuth = FakeAuthRepository(
      validEmail: 'marco@rifugio.it',
      uid: 'uid-marco',
    );
    await marcoAuth.signIn(
      email: 'marco@rifugio.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: marcoAuth,
      initialLocation: AppRoutes.home,
      size: const Size(360, 1100),
      dogs: InMemoryDogRepository(testListDogs()),
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(
          id: 'uid-marco',
          nome: 'marco',
          email: 'marco@rifugio.it',
          ruolo: VolunteerRuolo.referente,
        ),
      ]),
      dogListNow: now,
    );
    expect(find.text('Ciao Marco 👋'), findsOneWidget);
    expect(find.text('Ciao Giovanna 👋'), findsNothing);
  });

  testWidgets(
    '9b. senza documento il saluto non contiene nomi del seed',
    (tester) async {
      final other = FakeAuthRepository(
        validEmail: 'ospite@esempio.it',
        uid: 'uid-ospite',
      );
      await other.signIn(email: 'ospite@esempio.it', password: 'corretta');
      await pumpApp(
        tester,
        auth: other,
        initialLocation: AppRoutes.home,
        size: const Size(360, 1100),
        dogs: InMemoryDogRepository(testListDogs()),
        volunteers: InMemoryVolunteerRepository([
          testVolunteer(id: 'seed_giovanna'),
          testVolunteer(
            id: 'seed_roberto',
            nome: 'Roberto',
            email: 'roberto@amiciperlacoda.it',
          ),
        ]),
        dogListNow: now,
      );
      expect(find.byKey(HomePage.accountDisabledKey), findsOneWidget);
      expect(find.text('Ciao Giovanna 👋'), findsNothing);
      expect(find.text('Ciao Roberto 👋'), findsNothing);
      expect(find.textContaining('Giovanna'), findsNothing);
    },
  );

  test('canWriteRecords è falso se il volontario è disattivato', () {
    expect(
      canWriteRecords(testVolunteer(attivo: false)),
      isFalse,
    );
  });

  for (final width in widths) {
    testWidgets(
      '11. Impostazioni utenti a ${width.toInt()} dp senza overflow',
      (tester) async {
        await pumpLogged(
          tester,
          size: Size(width, 1600),
          volunteers: InMemoryVolunteerRepository([
            testVolunteer(),
            testVolunteer(
              id: 'uid-2',
              nome: 'Marco',
              cognome: 'Pellegrino',
              email: 'marco@amiciperlacoda.it',
              ruolo: VolunteerRuolo.referente,
              mustChangePassword: true,
            ),
            testVolunteer(
              id: 'uid-3',
              nome: 'Anna',
              cognome: 'Verdi',
              email: 'anna@amiciperlacoda.it',
              ruolo: VolunteerRuolo.volontario,
              attivo: false,
            ),
          ]),
        );
        expect(find.byKey(UsersCard.cardKey), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);

        await tester.ensureVisible(find.byKey(UsersCard.nuovoKey));
        await tester.tap(find.byKey(UsersCard.nuovoKey));
        await tester.pumpAndSettle();
        expect(find.byType(NewVolunteerSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '11b. dettaglio volontario a ${width.toInt()} dp senza overflow',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.volontario('uid-1'),
          size: Size(width, 1100),
        );
        expect(find.byType(VolunteerDetailPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );

    testWidgets(
      '11d. elimina account a ${width.toInt()} dp senza overflow',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.volontario('uid-2'),
          size: Size(width, 1100),
          volunteers: InMemoryVolunteerRepository([
            testVolunteer(),
            testVolunteer(
              id: 'uid-2',
              nome: 'Marzia',
              cognome: 'Masala',
              email: 'marzia@amiciperlacoda.it',
              ruolo: VolunteerRuolo.referente,
              attivo: false,
            ),
          ]),
        );
        expect(find.byType(VolunteerDetailPage), findsOneWidget);
        expect(find.byKey(VolunteerDetailPage.eliminaKey), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );

    testWidgets(
      '11c. cambio password a ${width.toInt()} dp senza overflow',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.home,
          size: Size(width, 1100),
          volunteers: InMemoryVolunteerRepository([
            testVolunteer(mustChangePassword: true),
          ]),
        );
        expect(find.byType(ChangePasswordPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
  }
}
