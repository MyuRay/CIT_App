import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Uri appStoreUrlForPlatform(TargetPlatform platform) => Uri.parse(
  platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
      ? 'https://apps.apple.com/jp/app/cit-app/id6752514796'
      : 'https://play.google.com/store/apps/details?id=jp.ac.chibakoudai.citapp',
);
Future<bool> openAppStore() => launchUrl(
  appStoreUrlForPlatform(defaultTargetPlatform),
  mode: LaunchMode.externalApplication,
);
