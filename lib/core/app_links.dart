import 'package:url_launcher/url_launcher.dart';

/// Apre `tel:` e `mailto:` sul dispositivo.
abstract interface class AppLinkOpener {
  Future<bool> open(Uri uri);
}

class UrlLauncherLinkOpener implements AppLinkOpener {
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
