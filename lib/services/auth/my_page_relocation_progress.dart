import 'package:shared_preferences/shared_preferences.dart';

/// This announcement belongs to the avatar relocation, not every app update.
class MyPageRelocationProgress {
  MyPageRelocationProgress(this.preferences);

  final SharedPreferences preferences;
  static const announcement = 'home-avatar-v1';
  String _key(String uid) => 'my_page_relocation_seen:$uid';

  bool shouldShow(String uid) =>
      uid.isNotEmpty && preferences.getString(_key(uid)) != announcement;

  Future<void> markSeen(String uid) async {
    final saved = await preferences.setString(_key(uid), announcement);
    if (!saved) throw StateError('マイページの移動案内を保存できませんでした');
  }
}
