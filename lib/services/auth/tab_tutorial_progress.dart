import 'package:shared_preferences/shared_preferences.dart';

/// A device-wide completion flag cannot prove that this account saw the guide.
class TabTutorialProgress {
  TabTutorialProgress(this.preferences);

  final SharedPreferences preferences;
  static const currentVersion = '2.1.0';
  String _key(String uid) => 'tab_tutorial_seen_version:$uid';

  bool shouldShow(String uid) =>
      preferences.getString(_key(uid)) != currentVersion;

  Future<void> markSeen(String uid) async {
    await preferences.setString(_key(uid), currentVersion);
  }
}
