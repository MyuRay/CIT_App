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
        CwitterSocialPlatform.discord => 'ユーザー名・招待URL・プロフィールURL',
        CwitterSocialPlatform.github => 'ユーザー名またはプロフィールURL',
      };

  String get inputHelper => switch (this) {
        CwitterSocialPlatform.instagram => '例: cit_student または https://instagram.com/cit_student',
        CwitterSocialPlatform.x => '例: cit_student または https://x.com/cit_student',
        CwitterSocialPlatform.discord => '例: username または https://discord.gg/xxxxx',
        CwitterSocialPlatform.github => '例: cit-student または https://github.com/cit-student',
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
    if (isDark && (this == CwitterSocialPlatform.x || this == CwitterSocialPlatform.github)) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return brandColor;
  }

  String? resolveLaunchUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

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
    final lower = value.toLowerCase();
    if (lower.contains('discord.gg/') || lower.contains('discord.com/')) {
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
      return 'https://$value';
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
