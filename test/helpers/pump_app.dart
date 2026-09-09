import 'package:amici_per_la_coda/app.dart';
import 'package:amici_per_la_coda/core/app_update/app_update_controller.dart';
import 'package:amici_per_la_coda/data/data_providers.dart';
import 'package:amici_per_la_coda/data/photos/photo_picker.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';
import 'package:amici_per_la_coda/features/auth/auth_providers.dart';
import 'package:amici_per_la_coda/features/dashboard/home_providers.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_providers.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/microchip_scanner.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_draft_store.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_providers.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'fake_auth_repository.dart';

var _italianDatesReady = false;

Future<void> _ensureItalianDates() async {
  if (_italianDatesReady) {
    return;
  }
  await initializeDateFormatting('it_IT');
  _italianDatesReady = true;
}

Future<void> pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  String? initialLocation,
  Size? size,
  DogRepository? dogs,
  HealthRepository? health,
  ExpenseRepository? expenses,
  AdoptionRepository? adoptions,
  NoteRepository? notes,
  DocumentRepository? documents,
  VolunteerRepository? volunteers,
  PhotoRepository? photos,
  WeightRepository? weights,
  SponsorshipRepository? sponsorships,
  AppointmentRepository? appointments,
  BoxRepository? boxes,
  AdopterRepository? adopters,
  PhotoPicker? picker,
  DogDraftStore? drafts,
  MicrochipScanner? scanner,
  DateTime? dogListNow,
  bool settle = true,
  bool offline = false,
}) async {
  await _ensureItalianDates();
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  final repository = auth ?? FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appUpdateEnabledProvider.overrideWith((ref) => false),
        authRepositoryProvider.overrideWith((ref) => repository),
        if (initialLocation != null)
          initialLocationProvider.overrideWith((ref) => initialLocation),
        if (dogs != null)
          dogRepositoryProvider.overrideWith((ref) => dogs),
        if (health != null)
          healthRepositoryProvider.overrideWith((ref) => health),
        if (expenses != null)
          expenseRepositoryProvider.overrideWith((ref) => expenses),
        if (adoptions != null)
          adoptionRepositoryProvider.overrideWith((ref) => adoptions),
        if (notes != null)
          noteRepositoryProvider.overrideWith((ref) => notes),
        if (documents != null)
          documentRepositoryProvider.overrideWith((ref) => documents),
        if (volunteers != null)
          volunteerRepositoryProvider.overrideWith((ref) => volunteers),
        if (photos != null)
          photoRepositoryProvider.overrideWith((ref) => photos),
        if (weights != null)
          weightRepositoryProvider.overrideWith((ref) => weights),
        if (sponsorships != null)
          sponsorshipRepositoryProvider.overrideWith((ref) => sponsorships),
        if (appointments != null)
          appointmentRepositoryProvider.overrideWith((ref) => appointments),
        if (boxes != null)
          boxRepositoryProvider.overrideWith((ref) => boxes),
        if (adopters != null)
          adopterRepositoryProvider.overrideWith((ref) => adopters),
        if (picker != null)
          photoPickerProvider.overrideWith((ref) => picker),
        if (drafts != null)
          dogDraftStoreProvider.overrideWith((ref) => drafts),
        if (scanner != null)
          microchipScannerProvider.overrideWith((ref) => scanner),
        if (dogListNow != null)
          dogListNowProvider.overrideWith((ref) => dogListNow),
        homeOfflineProvider.overrideWith((ref) => offline),
      ],
      child: const AmiciPerLaCodaApp(),
    ),
  );
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  }
}
