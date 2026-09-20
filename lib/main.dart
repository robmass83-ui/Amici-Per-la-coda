import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/local_notifications.dart';
import 'core/web_surface.dart';
import 'data/firestore/firebase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  if (showAndroidOnlyTools()) {
    initializeNotificationTimeZone();
  }
  await bootstrapFirebase();
  runApp(const ProviderScope(child: AmiciPerLaCodaApp()));
}
