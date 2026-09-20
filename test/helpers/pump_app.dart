import 'package:amici_per_la_coda/app.dart';
import 'package:amici_per_la_coda/core/app_connectivity.dart';
import 'package:amici_per_la_coda/core/app_links.dart';
import 'package:amici_per_la_coda/core/local_notifications.dart';
import 'package:amici_per_la_coda/core/app_update/app_update_controller.dart';
import 'package:amici_per_la_coda/core/app_update/installed_apk_share.dart';
import 'package:amici_per_la_coda/core/app_version.dart';
import 'package:amici_per_la_coda/core/web_surface.dart';
import 'package:amici_per_la_coda/data/data_providers.dart';
import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/data/documents/file_actions.dart';
import 'package:amici_per_la_coda/data/documents/template_assets.dart';
import 'package:amici_per_la_coda/features/dogs/export/gallery_saver.dart';
import 'package:amici_per_la_coda/data/photos/photo_picker.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';
import 'package:amici_per_la_coda/data/seed/seed_cleanup.dart';
import 'package:amici_per_la_coda/data/search_recents_store.dart';
import 'package:amici_per_la_coda/features/auth/auth_providers.dart';
import 'package:amici_per_la_coda/features/dashboard/home_providers.dart';
import 'package:amici_per_la_coda/features/notifications/app_runtime_listener.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_providers.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/microchip_scanner.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_draft_store.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_providers.dart';
import 'package:amici_per_la_coda/features/search/search_providers.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dog_fixtures.dart';
import 'fake_auth_repository.dart';
import 'fake_connectivity.dart';
import 'fake_app_link_opener.dart';
import 'fake_adopter_repository.dart';
import 'fake_adoption_repository.dart';
import 'fake_dog_repository.dart';
import 'fake_vendor_repository.dart';
import 'fake_seed_cleanup.dart';
import 'fake_volunteer_repository.dart';
import 'pubspec_version.dart';

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
  TemplateRepository? templates,
  VolunteerRepository? volunteers,
  PhotoRepository? photos,
  WeightRepository? weights,
  SponsorshipRepository? sponsorships,
  AppointmentRepository? appointments,
  BoxRepository? boxes,
  SettingsRepository? settings,
  AdopterRepository? adopters,
  VendorRepository? vendors,
  PhotoPicker? picker,
  DocumentFilePicker? documentPicker,
  FileShare? fileShare,
  GallerySaver? gallerySaver,
  InstalledApkShare? installedApkShare,
  FileOpener? fileOpener,
  AppLinkOpener? links,
  AssetBytesLoader? assets,
  DogDraftStore? drafts,
  MicrochipScanner? scanner,
  DateTime? dogListNow,
  bool settle = true,
  bool offline = false,
  bool dataFromCache = false,
  LocalNotifications? notifications,
  SeedCleanup? seedCleanup,
  SearchRecentsStore? searchRecents,
  String? appVersion,
  bool? webSurfaceIsWeb,
}) async {
  await _ensureItalianDates();
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  final repository = auth ?? FakeAuthRepository();
  final volunteerRepo =
      volunteers ?? InMemoryVolunteerRepository([testVolunteer()]);
  final dogRepo = dogs ?? InMemoryDogRepository();
  final adoptionRepo = adoptions ?? InMemoryAdoptionRepository();
  final adopterRepo = adopters ?? InMemoryAdopterRepository();
  final cleanup =
      seedCleanup ??
      (dogRepo is InMemoryDogRepository &&
              volunteerRepo is InMemoryVolunteerRepository &&
              adoptionRepo is InMemoryAdoptionRepository &&
              adopterRepo is InMemoryAdopterRepository
          ? InMemorySeedCleanup(
              dogs: dogRepo,
              adoptions: adoptionRepo,
              volunteers: volunteerRepo,
              adopters: adopterRepo,
            )
          : null);
  final connectivity = ControllableAppConnectivity(
    offline ? const [ConnectivityResult.none] : const [ConnectivityResult.wifi],
  );
  addTearDown(connectivity.dispose);

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        appUpdateEnabledProvider.overrideWith((ref) => false),
        appConnectivityProvider.overrideWith((ref) => connectivity),
        localNotificationsProvider.overrideWith(
          (ref) => notifications ?? const NoopLocalNotifications(),
        ),
        appVersionProvider.overrideWith(
          (ref) async => appVersion ?? pubspecVersionName(),
        ),
        if (webSurfaceIsWeb != null)
          webSurfaceIsWebProvider.overrideWith((ref) => webSurfaceIsWeb),
        authRepositoryProvider.overrideWith((ref) => repository),
        if (initialLocation != null)
          initialLocationProvider.overrideWith((ref) => initialLocation),
        dogRepositoryProvider.overrideWith((ref) => dogRepo),
        if (health != null)
          healthRepositoryProvider.overrideWith((ref) => health),
        if (expenses != null)
          expenseRepositoryProvider.overrideWith((ref) => expenses),
        adoptionRepositoryProvider.overrideWith((ref) => adoptionRepo),
        if (notes != null) noteRepositoryProvider.overrideWith((ref) => notes),
        if (documents != null)
          documentRepositoryProvider.overrideWith((ref) => documents),
        if (templates != null)
          templateRepositoryProvider.overrideWith((ref) => templates),
        volunteerRepositoryProvider.overrideWith((ref) => volunteerRepo),
        if (photos != null)
          photoRepositoryProvider.overrideWith((ref) => photos),
        if (weights != null)
          weightRepositoryProvider.overrideWith((ref) => weights),
        if (sponsorships != null)
          sponsorshipRepositoryProvider.overrideWith((ref) => sponsorships),
        if (appointments != null)
          appointmentRepositoryProvider.overrideWith((ref) => appointments),
        if (boxes != null) boxRepositoryProvider.overrideWith((ref) => boxes),
        if (settings != null)
          settingsRepositoryProvider.overrideWith((ref) => settings),
        adopterRepositoryProvider.overrideWith((ref) => adopterRepo),
        vendorRepositoryProvider.overrideWith(
          (ref) => vendors ?? InMemoryVendorRepository(),
        ),
        if (cleanup != null) seedCleanupProvider.overrideWith((ref) => cleanup),
        if (searchRecents != null)
          searchRecentsStoreProvider.overrideWith((ref) => searchRecents),
        if (picker != null) photoPickerProvider.overrideWith((ref) => picker),
        if (documentPicker != null)
          documentFilePickerProvider.overrideWith((ref) => documentPicker),
        if (fileShare != null)
          fileShareProvider.overrideWith((ref) => fileShare),
        if (gallerySaver != null)
          gallerySaverProvider.overrideWith((ref) => gallerySaver),
        if (installedApkShare != null)
          installedApkShareProvider.overrideWith((ref) => installedApkShare),
        if (fileOpener != null)
          fileOpenerProvider.overrideWith((ref) => fileOpener),
        appLinkOpenerProvider.overrideWith(
          (ref) => links ?? FakeAppLinkOpener(),
        ),
        if (assets != null)
          assetBytesLoaderProvider.overrideWith((ref) => assets),
        if (drafts != null) dogDraftStoreProvider.overrideWith((ref) => drafts),
        if (scanner != null)
          microchipScannerProvider.overrideWith((ref) => scanner),
        if (dogListNow != null)
          dogListNowProvider.overrideWith((ref) => dogListNow),
        homeOfflineProvider.overrideWith((ref) => offline),
        if (dataFromCache) ...[
          dogsFromCacheProvider.overrideWith((ref) => Stream.value(true)),
          coversFromCacheProvider.overrideWith((ref) => Stream.value(true)),
        ],
      ],
      child: const AmiciPerLaCodaApp(),
    ),
  );
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  }
}
