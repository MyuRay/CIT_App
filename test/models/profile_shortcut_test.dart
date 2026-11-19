import 'package:cit_app/models/user/profile_shortcut.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('prefs key missing defaults to all shortcuts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(
      profileShortcutVisibleIdsFromPrefs(prefs),
      kProfileShortcutDefaultVisible,
    );
  });

  test('prefs key with empty string means none visible', () async {
    SharedPreferences.setMockInitialValues({
      kProfileShortcutVisibleIdsPrefsKey: '',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(profileShortcutVisibleIdsFromPrefs(prefs), isEmpty);
  });

  test('encode and parse round trip', () async {
    const ids = [
      ProfileShortcutId.myCafeteria,
      ProfileShortcutId.assignments,
    ];
    SharedPreferences.setMockInitialValues({
      kProfileShortcutVisibleIdsPrefsKey: encodeProfileShortcutVisibleIds(ids),
    });
    final prefs = await SharedPreferences.getInstance();
    expect(profileShortcutVisibleIdsFromPrefs(prefs), ids);
  });
}
