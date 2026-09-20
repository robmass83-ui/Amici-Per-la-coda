import 'package:amici_per_la_coda/core/app_links.dart';

class FakeAppLinkOpener implements AppLinkOpener {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
