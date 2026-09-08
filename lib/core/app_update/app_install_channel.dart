import 'package:flutter/services.dart';

import 'installed_version.dart';

abstract final class AppInstallChannel {
  static const _channel = MethodChannel(
    'it.amiciperlacoda.amici_per_la_coda/updater',
  );

  static Future<InstalledVersion> getVersion() async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>('getVersion');
    final map = <String, Object?>{};
    if (raw != null) {
      for (final entry in raw.entries) {
        map['${entry.key}'] = entry.value;
      }
    }
    final abisRaw = map['abis'];
    final abis = <String>[];
    if (abisRaw is List<Object?>) {
      for (final item in abisRaw) {
        if (item is String && item.isNotEmpty) {
          abis.add(item);
        }
      }
    }
    return InstalledVersion(
      versionName: map['versionName'] as String? ?? '0.0.0',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
      abis: abis,
    );
  }

  static Future<String> getDownloadPath() async {
    final path = await _channel.invokeMethod<String>('getDownloadPath');
    if (path == null || path.isEmpty) {
      throw StateError('Percorso di download non disponibile.');
    }
    return path;
  }

  static Future<bool> canInstallPackages() async {
    return await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
  }

  static Future<void> requestInstallPermission() {
    return _channel.invokeMethod<void>('requestInstallPermission');
  }

  static Future<void> requestNotificationPermission() {
    return _channel.invokeMethod<void>('requestNotificationPermission');
  }

  static Future<void> showUpdateNotification({
    required String title,
    required String body,
  }) {
    return _channel.invokeMethod<void>('showUpdateNotification', {
      'title': title,
      'body': body,
    });
  }

  static Future<void> installApk(String path) {
    return _channel.invokeMethod<void>('installApk', {'path': path});
  }
}
