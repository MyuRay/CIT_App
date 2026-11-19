import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/app_constants.dart';

enum CwitterSocialPlatform {
  instagram,
  x,
  discord,
  github;

  String get storageKey => name;

  String get label => switch (this) {
    CwitterSocialPlatform.instagram => 'Instagram',
    CwitterSocialPlatform.x => 'X',
    CwitterSocialPlatform.discord => 'Discord',
    CwitterSocialPlatform.github => 'GitHub',
  };

  String get inputHint => switch (this) {
    CwitterSocialPlatform.instagram => 'ユーザー名またはプロフィールURL',
    CwitterSocialPlatform.x => 'ユーザー名またはプロフィールURL',
    CwitterSocialPlatform.discord => '数字のユーザーIDまたはプロフィールURL',
    CwitterSocialPlatform.github => 'ユーザー名またはプロフィールURL',
  };

  String get inputHelper => switch (this) {
    CwitterSocialPlatform.instagram =>
      '例: cit_student または https://instagram.com/cit_student',
    CwitterSocialPlatform.x => '例: cit_student または https://x.com/cit_student',
    CwitterSocialPlatform.discord =>
      'Discordの「設定 → 詳細設定 → 開発者モード」をオンにし、'
          '自分のプロフィールの「…」から「ユーザーIDをコピー」して貼り付けてください。'
          'ユーザー名だけではプロフィールを開けません。招待URLも使えます。',
    CwitterSocialPlatform.github =>
      '例: cit-student または https://github.com/cit-student',
  };

  Color get brandColor => switch (this) {
    CwitterSocialPlatform.instagram => const Color(0xFFE4405F),
    CwitterSocialPlatform.x => const Color(0xFF0F1419),
    CwitterSocialPlatform.discord => const Color(0xFF5865F2),
    CwitterSocialPlatform.github => const Color(0xFF24292F),
  };

  FaIconData get brandIcon => switch (this) {
    CwitterSocialPlatform.instagram => FontAwesomeIcons.instagram,
    CwitterSocialPlatform.x => FontAwesomeIcons.xTwitter,
    CwitterSocialPlatform.discord => FontAwesomeIcons.discord,
    CwitterSocialPlatform.github => FontAwesomeIcons.github,
  };

  Color iconColor(BuildContext context, {required bool registered}) {
    if (!registered) {
      return brandColor.withValues(alpha: 0.35);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark &&
        (this == CwitterSocialPlatform.x ||
            this == CwitterSocialPlatform.github)) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return brandColor;
  }

  String? resolveLaunchUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (this == CwitterSocialPlatform.discord) {
      return _resolveDiscordUrl(trimmed);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final handle = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;

    return switch (this) {
      CwitterSocialPlatform.instagram => 'https://instagram.com/$handle',
      CwitterSocialPlatform.x => 'https://x.com/$handle',
      CwitterSocialPlatform.github => 'https://github.com/$handle',
      CwitterSocialPlatform.discord => _resolveDiscordUrl(handle),
    };
  }

  String? _resolveDiscordUrl(String value) {
    final idPattern = RegExp(r'^[1-9][0-9]{16,19}$');
    final id = value.startsWith('@') ? value.substring(1) : value;
    if (idPattern.hasMatch(id)) {
      return 'https://discord.com/users/$id';
    }

    // Only recognized Discord destinations can be opened without the generic
    // external-site confirmation. Normalize legacy domains and pasted URLs.
    if (RegExp(r'\s').hasMatch(value)) return null;
    final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      return null;
    }
    final host = uri.host.toLowerCase();
    if (host == 'discord.com' ||
        host == 'www.discord.com' ||
        host == 'discordapp.com' ||
        host == 'www.discordapp.com') {
      final profile = RegExp(
        r'^/users/([1-9][0-9]{16,19})/?$',
      ).firstMatch(uri.path);
      if (profile != null) {
        return 'https://discord.com/users/${profile.group(1)}';
      }
      final invite = RegExp(
        r'^/invite/([A-Za-z0-9_-]+)/?$',
      ).firstMatch(uri.path);
      if (invite != null) {
        return 'https://discord.com/invite/${invite.group(1)}';
      }
    } else if (host == 'discord.gg' || host == 'www.discord.gg') {
      final invite = RegExp(r'^/([A-Za-z0-9_-]+)/?$').firstMatch(uri.path);
      if (invite != null) {
        return 'https://discord.com/invite/${invite.group(1)}';
      }
    }
    return null;
  }

  static CwitterSocialPlatform? fromStorageKey(String key) {
    for (final platform in CwitterSocialPlatform.values) {
      if (platform.storageKey == key) return platform;
    }
    return null;
  }

  static Map<String, String> parseLinks(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const {};

    final links = <String, String>{};
    for (final platform in CwitterSocialPlatform.values) {
      final value = raw[platform.storageKey];
      if (value == null) continue;
      final trimmed = value.toString().trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length > AppConstants.cwitterSocialLinkMaxLength) continue;
      links[platform.storageKey] = trimmed;
    }
    return links;
  }

  static Map<String, String> sanitizeLinks(Map<String, String> links) {
    final sanitized = <String, String>{};
    for (final entry in links.entries) {
      final platform = fromStorageKey(entry.key);
      if (platform == null) continue;
      final trimmed = entry.value.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length > AppConstants.cwitterSocialLinkMaxLength) continue;
      sanitized[platform.storageKey] = trimmed;
    }
    return sanitized;
  }
}
