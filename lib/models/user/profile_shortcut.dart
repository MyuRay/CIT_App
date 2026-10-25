import 'package:shared_preferences/shared_preferences.dart';

/// マイページ「よく使う機能」の項目 ID。
enum ProfileShortcutId {
  myCafeteria,
  assignments,
  contact,
  theme,
  fontSize,
  calendar,
  classroomMap,
  attendance,
}

extension ProfileShortcutIdX on ProfileShortcutId {
  String get storageKey => switch (this) {
    ProfileShortcutId.myCafeteria => 'my_cafeteria',
    ProfileShortcutId.assignments => 'assignments',
    ProfileShortcutId.contact => 'contact',
    ProfileShortcutId.theme => 'theme',
    ProfileShortcutId.fontSize => 'font_size',
    ProfileShortcutId.calendar => 'calendar',
    ProfileShortcutId.classroomMap => 'classroom_map',
    ProfileShortcutId.attendance => 'attendance',
  };

  String get label => switch (this) {
    ProfileShortcutId.myCafeteria => 'My食堂',
    ProfileShortcutId.assignments => '課題管理',
    ProfileShortcutId.contact => 'お問い合わせ',
    ProfileShortcutId.theme => 'テーマ',
    ProfileShortcutId.fontSize => '文字サイズ',
    ProfileShortcutId.calendar => 'カレンダー',
    ProfileShortcutId.classroomMap => '教室マップ',
    ProfileShortcutId.attendance => '出席管理',
  };

}

ProfileShortcutId? profileShortcutIdFromStorageKey(String key) {
  for (final id in ProfileShortcutId.values) {
    if (id.storageKey == key) return id;
  }
  return null;
}

const List<ProfileShortcutId> kProfileShortcutCatalog =
    ProfileShortcutId.values;

/// 未保存時・初回表示時は全機能を表示。
const List<ProfileShortcutId> kProfileShortcutDefaultVisible =
    kProfileShortcutCatalog;

const String kProfileShortcutVisibleIdsPrefsKey = 'profileShortcutVisibleIds';

/// 旧: 一括解除フラグ（読み取り互換のみ）。
const String kProfileShortcutsHighlightDismissedLegacyPrefsKey =
    'profileShortcutsHighlightDismissed';

/// 先の画面を開いて強調を解除したショートカット ID（storageKey の CSV）。
const String kProfileShortcutsHighlightDismissedIdsPrefsKey =
    'profileShortcutsHighlightDismissedIds';

Set<String> profileShortcutHighlightDismissedIdsFromPrefs(
  SharedPreferences prefs,
) {
  if (prefs.getBool(kProfileShortcutsHighlightDismissedLegacyPrefsKey) == true) {
    return kProfileShortcutCatalog.map((id) => id.storageKey).toSet();
  }
  final raw = prefs.getString(kProfileShortcutsHighlightDismissedIdsPrefsKey);
  if (raw == null || raw.trim().isEmpty) {
    return {};
  }
  return raw
      .split(',')
      .map((part) => part.trim())
      .where((key) => key.isNotEmpty)
      .toSet();
}

String encodeProfileShortcutHighlightDismissedIds(Set<String> ids) {
  return ids.join(',');
}

bool shouldEmphasizeProfileShortcut(
  SharedPreferences prefs,
  ProfileShortcutId id,
) {
  return !profileShortcutHighlightDismissedIdsFromPrefs(
    prefs,
  ).contains(id.storageKey);
}

/// [prefsKeyExists] が false のときだけ未設定扱い（全件 ON）。キーありで空文字なら 0 件。
List<ProfileShortcutId> parseProfileShortcutVisibleIds(
  String? raw, {
  required bool prefsKeyExists,
}) {
  if (!prefsKeyExists) {
    return List<ProfileShortcutId>.from(kProfileShortcutDefaultVisible);
  }
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }
  final parsed = <ProfileShortcutId>[];
  for (final part in raw.split(',')) {
    final key = part.trim();
    if (key.isEmpty) continue;
    final id = profileShortcutIdFromStorageKey(key);
    if (id != null && !parsed.contains(id)) {
      parsed.add(id);
    }
  }
  return parsed;
}

List<ProfileShortcutId> profileShortcutVisibleIdsFromPrefs(
  SharedPreferences prefs,
) {
  const key = kProfileShortcutVisibleIdsPrefsKey;
  return parseProfileShortcutVisibleIds(
    prefs.getString(key),
    prefsKeyExists: prefs.containsKey(key),
  );
}

String encodeProfileShortcutVisibleIds(List<ProfileShortcutId> ids) {
  return ids.map((e) => e.storageKey).join(',');
}
