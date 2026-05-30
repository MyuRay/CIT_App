import 'package:cloud_firestore/cloud_firestore.dart';

/// フォロー / フォロー解除失敗時のユーザー向けメッセージ
String cwitterFollowActionErrorMessage(
  Object error, {
  required bool unfollow,
}) {
  final action = unfollow ? 'フォロー解除' : 'フォロー';

  if (error is StateError) {
    return error.message;
  }
  if (error is ArgumentError) {
    final message = error.message?.toString();
    if (message != null && message.isNotEmpty) return message;
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return '$actionできませんでした';
      case 'unavailable':
      case 'deadline-exceeded':
        return '通信エラーが発生しました。接続を確認してください';
      case 'failed-precondition':
        return '操作を完了できませんでした。もう一度お試しください';
      default:
        break;
    }
  }

  final text = error.toString().toLowerCase();
  if (text.contains('permission-denied')) {
    return '$actionできませんでした';
  }
  if (text.contains('network') ||
      text.contains('unavailable') ||
      text.contains('deadline-exceeded')) {
    return '通信エラーが発生しました。接続を確認してください';
  }

  return '$actionに失敗しました';
}
