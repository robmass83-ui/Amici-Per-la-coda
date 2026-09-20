import 'package:amici_per_la_coda/core/app_update/installed_apk_share.dart';

class FakeInstalledApkShare implements InstalledApkShare {
  FakeInstalledApkShare(this.apk);

  final SharedApk apk;
  var prepareCount = 0;

  @override
  Future<SharedApk> prepare() async {
    prepareCount += 1;
    return apk;
  }
}
