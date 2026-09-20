import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

const amiciUseEmulatorDefine = bool.fromEnvironment(
  'AMICI_USE_EMULATOR',
  defaultValue: false,
);

bool shouldUseEmulators({
  bool? isWeb,
  String? host,
  bool? dartDefine,
}) {
  final web = isWeb ?? kIsWeb;
  if (!web) {
    return false;
  }
  final define = dartDefine ?? amiciUseEmulatorDefine;
  if (define) {
    return true;
  }
  final name = host ?? Uri.base.host;
  return name == 'localhost' || name == '127.0.0.1';
}

String? identityToolkitEmulatorOrigin({bool? useEmulators}) {
  if (!(useEmulators ?? shouldUseEmulators())) {
    return null;
  }
  return 'http://127.0.0.1:9099';
}

Future<void> connectFirebaseEmulators({
  required FirebaseAuth auth,
  required FirebaseFirestore db,
}) async {
  if (!shouldUseEmulators()) {
    return;
  }
  await auth.useAuthEmulator('127.0.0.1', 9099);
  db.useFirestoreEmulator('127.0.0.1', 8080);
}
