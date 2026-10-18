import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/external_browser.dart';

class UrlLauncherExternalBrowser implements ExternalBrowser {
  const UrlLauncherExternalBrowser();

  @override
  Future<bool> openHttpUrl(Uri url) {
    final scheme = url.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.toString().runes.any(
          (rune) => rune < 0x20 || (rune >= 0x7f && rune <= 0x9f),
        )) {
      return Future<bool>.value(false);
    }
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
