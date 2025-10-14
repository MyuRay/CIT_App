import 'package:flutter/foundation.dart';

/// セキュアなログ出力ユーティリティ
class SecureLogger {
  static const String _tag = '[CITApp]';
  
  /// デバッグログ（開発環境でのみ出力）
  static void debug(String message, {String? context}) {
    if (kDebugMode) {
      print('$_tag [DEBUG] ${context != null ? '[$context] ' : ''}$message');
    }
  }
  
  /// 情報ログ（重要な操作の記録）
  static void info(String message, {String? context}) {
    if (kDebugMode) {
      print('$_tag [INFO] ${context != null ? '[$context] ' : ''}$message');
    }
  }
  
  /// 警告ログ（潜在的な問題）
  static void warning(String message, {String? context}) {
    if (kDebugMode) {
      print('$_tag [WARN] ${context != null ? '[$context] ' : ''}$message');
    }
  }
  
  /// エラーログ（必ず出力、ただし機密情報は除外）
  static void error(String message, {String? context, Object? error}) {
    final sanitizedMessage = _sanitizeMessage(message);
    print('$_tag [ERROR] ${context != null ? '[$context] ' : ''}$sanitizedMessage');
    if (kDebugMode && error != null) {
      print('$_tag [ERROR] スタックトレース: $error');
    }
  }
  
  /// セキュリティ関連ログ（重要度高）
  static void security(String message, {String? context}) {
    final sanitizedMessage = _sanitizeMessage(message);
    print('$_tag [SECURITY] ${context != null ? '[$context] ' : ''}$sanitizedMessage');
  }
  
  /// メッセージから機密情報を除去
  static String _sanitizeMessage(String message) {
    return message
        .replaceAll(RegExp(r'password\s*[:=]\s*\S+', caseSensitive: false), 'password: [REDACTED]')
        .replaceAll(RegExp(r'token\s*[:=]\s*\S+', caseSensitive: false), 'token: [REDACTED]')
        .replaceAll(RegExp(r'key\s*[:=]\s*\S+', caseSensitive: false), 'key: [REDACTED]')
        .replaceAll(RegExp(r'secret\s*[:=]\s*\S+', caseSensitive: false), 'secret: [REDACTED]');
  }
}