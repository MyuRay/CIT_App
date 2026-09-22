import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InstalledAppVersion {
  const InstalledAppVersion(this.version, this.buildNumber, this.packageName);

  final String version;
  final String buildNumber;
  final String packageName;
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.storeUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final Uri storeUrl;
}

/// Only a published, newer release with a valid store destination is advertised.
/// Invalid or missing configuration must never prevent the app from opening.
AppUpdateInfo? availableAppUpdate({
  required String configuration,
  required InstalledAppVersion installed,
  required TargetPlatform platform,
}) {
  if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
    return null;
  }
  try {
    final policy = jsonDecode(configuration);
    if (policy is! Map<String, dynamic> || policy['enabled'] != true) {
      return null;
    }
    final version = policy['version'];
    final build = policy['buildNumber'];
    final destination = policy['storeUrl'];
    if (version is! String ||
        destination is! String ||
        (build != null && build is! String)) {
      return null;
    }
    final versionOrder = _compareNumbers(
      version,
      installed.version,
      exactParts: 3,
    );
    final buildOrder =
        build is String ? _compareNumbers(build, installed.buildNumber) : null;
    if (versionOrder == null || versionOrder < 0) return null;
    if (build != null && buildOrder == null) return null;
    if (versionOrder == 0 && (buildOrder == null || buildOrder <= 0)) {
      return null;
    }
    // Play only serves increasing versionCodes, even if versionName was edited.
    if (platform == TargetPlatform.android &&
        (buildOrder == null || buildOrder <= 0)) {
      return null;
    }
    // The public App Store listing exposes version, not CFBundleVersion.
    // iOS can use version alone; equal versions require a known newer build.

    final uri = Uri.tryParse(destination);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443)) {
      return null;
    }
    if (platform == TargetPlatform.android) {
      if (uri.host != 'play.google.com' ||
          uri.path != '/store/apps/details' ||
          uri.queryParameters['id'] != installed.packageName) {
        return null;
      }
    } else {
      if (uri.host != 'apps.apple.com' ||
          !RegExp(r'/id[0-9]+/?$').hasMatch(uri.path)) {
        return null;
      }
    }
    return AppUpdateInfo(
      currentVersion: installed.version,
      latestVersion: version,
      storeUrl: uri,
    );
  } on FormatException {
    return null;
  }
}

int? _compareNumbers(String a, String b, {int? exactParts}) {
  List<int>? parse(String value) {
    if (!RegExp(r'^\d+(\.\d+){0,2}$').hasMatch(value)) return null;
    final parts = value.split('.').map(int.tryParse).toList();
    if (parts.any((part) => part == null) ||
        (exactParts != null && parts.length != exactParts)) {
      return null;
    }
    return [for (var i = 0; i < 3; i++) i < parts.length ? parts[i]! : 0];
  }

  final left = parse(a);
  final right = parse(b);
  if (left == null || right == null) return null;
  for (var i = 0; i < 3; i++) {
    final result = left[i].compareTo(right[i]);
    if (result != 0) return result;
  }
  return 0;
}

class AppUpdateService {
  AppUpdateService({
    required this.platform,
    required this.loadConfiguration,
    required this.loadInstalledVersion,
    this.timeout = const Duration(seconds: 6),
  });

  factory AppUpdateService.firebase(TargetPlatform platform) {
    return AppUpdateService(
      platform: platform,
      loadConfiguration: () async {
        final remote = FirebaseRemoteConfig.instance;
        await remote.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 5),
            minimumFetchInterval: const Duration(hours: 1),
          ),
        );
        await remote.fetchAndActivate();
        final key =
            platform == TargetPlatform.android
                ? 'app_update_android'
                : 'app_update_ios';
        return remote.getString(key);
      },
      loadInstalledVersion: () async {
        final info = await PackageInfo.fromPlatform();
        return InstalledAppVersion(
          info.version,
          info.buildNumber,
          info.packageName,
        );
      },
    );
  }

  final TargetPlatform platform;
  final Future<String> Function() loadConfiguration;
  final Future<InstalledAppVersion> Function() loadInstalledVersion;
  final Duration timeout;

  Future<AppUpdateInfo?> check() async {
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return null;
    }
    try {
      return await _check().timeout(timeout);
    } catch (_) {
      // Offline, unavailable Firebase, and platform errors are non-fatal.
      return null;
    }
  }

  Future<AppUpdateInfo?> _check() async {
    final installed = await loadInstalledVersion();
    final configuration = await loadConfiguration();
    return availableAppUpdate(
      configuration: configuration,
      installed: installed,
      platform: platform,
    );
  }
}
