import 'dart:convert';

import 'package:amici_per_la_coda/data/backup_json.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/adoptions/adoption_detail_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adoptions_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/edit_permissions.dart';
import 'package:amici_per_la_coda/features/settings/edit_association_sheet.dart';
import 'package:amici_per_la_coda/features/settings/settings_page.dart';
import 'package:amici_per_la_coda/features/settings/users_card.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/fake_settings_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 10, 8);

  Finder horizontalScrollables() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Scrollable) {
        return false;
      }
      if (axisDirectionToAxis(widget.axisDirection) != Axis.horizontal) {
        return false;
      }
      return widget.restorationId != 'editable';
    });
  }

  Future<void> pumpLogged(
    WidgetTester tester, {
    required String location,
    Size size = const Size(360, 1400),
    VolunteerRuolo ruolo = VolunteerRuolo.presidente,
    InMemorySettingsRepository? settings,
    RecordingFileShare? fileShare,
    InMemoryDogRepository? dogs,
    InMemoryAdoptionRepository? adoptions,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: location,
      size: size,
      dogListNow: now,
      dogs: dogs ?? InMemoryDogRepository(testListDogs()),
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: ruolo),
      ]),
      settings: settings ??
          InMemorySettingsRepository(testAssociationSettings()),
      fileShare: fileShare,
      adoptions: adoptions,
    );
  }

  test('canManageSettings solo per il presidente attivo', () {
    expect(canManageSettings(null), isFalse);
    expect(canManageSettings(testVolunteer(attivo: false)), isFalse);
    expect(
      canManageSettings(testVolunteer(ruolo: VolunteerRuolo.volontario)),
      isFalse,
    );
    expect(
      canManageSettings(testVolunteer(ruolo: VolunteerRuolo.referente)),
      isFalse,
    );
    expect(canManageSettings(testVolunteer()), isTrue);
  });

  test('backup JSON contiene i cani', () {
    final json = backupJsonOf(
      buildBackupMap(
        exportedAt: now,
        dogs: [testDog(id: 'fenice', nome: 'Fenice')],
        volunteers: [testVolunteer()],
        boxes: const [],
        adoptions: const [],
        adopters: const [],
        appointments: const [],
        health: const [],
        expenses: const [],
        sponsorships: const [],
        documents: const [],
        templates: const [],
        association: testAssociationSettings(),
      ),
    );
    final map = jsonDecode(json) as Map<String, dynamic>;
    final dogs = map['dogs'] as List<dynamic>;
    final first = dogs.first as Map<String, dynamic>;
    final association = map['associazione'] as Map<String, dynamic>;
    expect(first['nome'], 'Fenice');
    expect(association['denominazione'], 'Amici per la Coda ODV');
    expect(backupFileName(now), 'amici-per-la-coda-export-20260910.json');
  });

  testWidgets('volontario non vede modifica, FAB, backup né utenti', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.home,
      ruolo: VolunteerRuolo.volontario,
    );
    expect(find.byTooltip('Nuovo'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpLogged(
      tester,
      location: AppRoutes.dog('fenice'),
      ruolo: VolunteerRuolo.volontario,
    );
    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.byTooltip('Modifica'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpLogged(
      tester,
      location: AppRoutes.impostazioni,
      ruolo: VolunteerRuolo.volontario,
    );
    expect(find.byKey(SettingsPage.modificaAssociazioneKey), findsNothing);
    expect(find.byKey(SettingsPage.backupKey), findsNothing);
    expect(find.byKey(UsersCard.cardKey), findsNothing);
    expect(find.byKey(SettingsPage.associazioneKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpLogged(
      tester,
      location: AppRoutes.richieste,
      ruolo: VolunteerRuolo.volontario,
    );
    expect(find.byKey(AdoptionsPage.nuovaKey), findsNothing);
  });

  testWidgets('referente scrive ma non gestisce le impostazioni', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.home,
      ruolo: VolunteerRuolo.referente,
    );
    expect(find.byTooltip('Nuovo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpLogged(
      tester,
      location: AppRoutes.impostazioni,
      ruolo: VolunteerRuolo.referente,
    );
    expect(find.byKey(SettingsPage.modificaAssociazioneKey), findsNothing);
    expect(find.byKey(SettingsPage.backupKey), findsNothing);
    expect(find.byKey(UsersCard.cardKey), findsNothing);
  });

  testWidgets('presidente modifica associazione, switch e backup', (
    tester,
  ) async {
    final settings = InMemorySettingsRepository(testAssociationSettings());
    final share = RecordingFileShare();
    await pumpLogged(
      tester,
      location: AppRoutes.impostazioni,
      settings: settings,
      fileShare: share,
    );
    expect(find.text('Amici per la Coda ODV'), findsOneWidget);
    expect(find.text('54 posti'), findsOneWidget);

    await tester.tap(find.byKey(SettingsPage.riepilogoSwitchKey));
    await tester.pumpAndSettle();
    expect(settings.current!.notificheRiepilogoSettimanale, isTrue);

    await tester.ensureVisible(find.byKey(SettingsPage.backupKey));
    await tester.tap(find.byKey(SettingsPage.backupKey));
    await tester.pumpAndSettle();
    expect(share.lastFileName, 'amici-per-la-coda-export-20260910.json');
    expect(utf8.decode(share.lastBytes!), contains('Fenice'));
    expect(settings.current!.ultimoExportAt, now);

    await tester.tap(find.byKey(SettingsPage.modificaAssociazioneKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(EditAssociationSheet.sedeKey),
      'Sassari (SS)',
    );
    await tester.tap(find.byKey(EditAssociationSheet.salvaKey));
    await tester.pumpAndSettle();
    expect(settings.current!.sede, 'Sassari (SS)');
  });

  testWidgets('CSV dalle impostazioni condivide l\'anagrafe', (tester) async {
    final share = RecordingFileShare();
    await pumpLogged(
      tester,
      location: AppRoutes.impostazioni,
      fileShare: share,
      dogs: InMemoryDogRepository([
        testDog(id: 'fenice', nome: 'Fenice', microchip: '380260043210987'),
      ]),
    );
    await tester.ensureVisible(find.byKey(SettingsPage.csvKey));
    await tester.tap(find.byKey(SettingsPage.csvKey));
    await tester.pumpAndSettle();
    expect(share.lastFileName, 'anagrafe-cani.csv');
    expect(utf8.decode(share.lastBytes!), contains('Fenice'));
  });

  testWidgets('volontario non vede Respingi né Invia modulo', (tester) async {
    await pumpLogged(
      tester,
      location: AppRoutes.richiesta('r1'),
      ruolo: VolunteerRuolo.volontario,
      adoptions: InMemoryAdoptionRepository([
        testAdoption(id: 'r1', dogId: 'fenice'),
      ]),
    );
    expect(find.byType(AdoptionDetailPage), findsOneWidget);
    expect(find.byKey(AdoptionDetailPage.respingiKey), findsNothing);
    expect(find.byKey(AdoptionDetailPage.avanzaKey), findsNothing);
    expect(find.byKey(AdoptionDetailPage.inviaModuloKey), findsNothing);
  });

  for (final width in widths) {
    testWidgets(
      'impostazioni a ${width.toInt()} dp senza overflow',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.impostazioni,
          size: Size(width, 1400),
        );
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
  }
}
