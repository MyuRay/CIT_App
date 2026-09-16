import 'package:flutter/foundation.dart';

/// セキュアなログ出力ユーティリティ
class SecureLogger {
  static const String _tag = '[CITApp]';

  /// デバッグログ（開発環境でのみ出力）
  static void debug(String message, {String? context}) {
    if (kDebugMode) {
      print(
        '$_tag [DEBUG] ${context != null ? '[${sanitize(context)}] ' : ''}${sanitize(message)}',
      );
    }
  }

  /// 情報ログ（重要な操作の記録）
  static void info(String message, {String? context}) {
    if (kDebugMode) {
      print(
        '$_tag [INFO] ${context != null ? '[${sanitize(context)}] ' : ''}${sanitize(message)}',
      );
    }
  }

  /// 警告ログ（潜在的な問題）
  static void warning(String message, {String? context}) {
    if (kDebugMode) {
      print(
        '$_tag [WARN] ${context != null ? '[${sanitize(context)}] ' : ''}${sanitize(message)}',
      );
    }
  }

  /// エラーログ（必ず出力、ただし機密情報は除外）
  static void error(String message, {String? context, Object? error}) {
    final sanitizedMessage = sanitize(message);
    print(
      '$_tag [ERROR] ${context != null ? '[${sanitize(context)}] ' : ''}$sanitizedMessage',
    );
    if (kDebugMode && error != null) {
      print('$_tag [ERROR] スタックトレース: ${sanitize(error.toString())}');
    }
  }

  /// セキュリティ関連ログ（重要度高）
  static void security(String message, {String? context}) {
    final sanitizedMessage = sanitize(message);
    print(
      '$_tag [SECURITY] ${context != null ? '[${sanitize(context)}] ' : ''}$sanitizedMessage',
    );
  }

  /// メッセージから機密情報を除去
  static String sanitize(String message) {
    return message
        .replaceAll(
          RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
          '[EMAIL]',
        )
        .replaceAll(RegExp(r'https?://[^\s]+\?[^\s]+'), '[URL_WITH_QUERY]')
        .replaceAll(
          RegExp(r'[A-Za-z0-9_-]{10,}:[A-Za-z0-9_:-]{40,}'),
          '[TOKEN]',
        )
        .replaceAll(
          RegExp(r'Bearer\s+\S+', caseSensitive: false),
          'Bearer [REDACTED]',
        )
        .replaceAll(
          RegExp(r'password\s*[:=]\s*\S+', caseSensitive: false),
          'password: [REDACTED]',
        )
        .replaceAll(
          RegExp(r'token\s*[:=]\s*\S+', caseSensitive: false),
          'token: [REDACTED]',
        )
        .replaceAll(
          RegExp(r'key\s*[:=]\s*\S+', caseSensitive: false),
          'key: [REDACTED]',
        )
        .replaceAll(
          RegExp(r'secret\s*[:=]\s*\S+', caseSensitive: false),
          'secret: [REDACTED]',
        );
  }
}
