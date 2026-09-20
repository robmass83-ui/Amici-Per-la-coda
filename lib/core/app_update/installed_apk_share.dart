import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_install_channel.dart';

class SharedApk {
  const SharedApk({
    required this.path,
    required this.fileName,
    required this.versionName,
    required this.versionCode,
  });

  final String path;
  final String fileName;
  final String versionName;
  final int versionCode;

  String get versionLabel => '$versionName ($versionCode)';
}

abstract interface class InstalledApkShare {
  Future<SharedApk> prepare();
}

class ChannelInstalledApkShare implements InstalledApkShare {
  @override
  Future<SharedApk> prepare() async {
    final map = await AppInstallChannel.copyInstalledApkForShare();
    return SharedApk(
      path: map['path'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      versionName: map['versionName'] as String? ?? '0.0.0',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
    );
  }
}

final installedApkShareProvider = Provider<InstalledApkShare>(
  (ref) => ChannelInstalledApkShare(),
);
