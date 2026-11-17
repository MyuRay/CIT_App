import '../../models/user/profile_shortcut.dart';

/// 強調中ショートカット吹き出しの表示確率（本番は 0.3 程度）。
const double kHomeFeatureShortcutIntroShowProbability = 0.3;

/// メインキャンパスを一度でも保存したら true（吹き出しは二度と出さない）。
const String kHomeMainCampusIntroDismissedPrefsKey =
    'homeMainCampusIntroDismissed';

bool shouldShowHomeMainCampusIntro({
  required bool campusStored,
  required bool introDismissedPermanently,
}) {
  return !campusStored && !introDismissedPermanently;
}

/// true: 吹き出しタップで紹介文を切り替え（テストプレイ）。false: タップでマイページへ。
const bool kHomeFeatureIntroTapCyclesMessages = false;

/// 吹き出しで紹介する対象（強調中のマイページ機能）。
enum HomeFeatureIntroId {
  mainCampus,
  myCafeteria,
  assignments,
  contact,
  theme,
  fontSize,
  calendar,
  classroomMap,
  attendance,
}

HomeFeatureIntroId homeFeatureIntroIdForShortcut(ProfileShortcutId id) {
  return switch (id) {
    ProfileShortcutId.myCafeteria => HomeFeatureIntroId.myCafeteria,
    ProfileShortcutId.assignments => HomeFeatureIntroId.assignments,
    ProfileShortcutId.contact => HomeFeatureIntroId.contact,
    ProfileShortcutId.theme => HomeFeatureIntroId.theme,
    ProfileShortcutId.fontSize => HomeFeatureIntroId.fontSize,
    ProfileShortcutId.calendar => HomeFeatureIntroId.calendar,
    ProfileShortcutId.classroomMap => HomeFeatureIntroId.classroomMap,
    ProfileShortcutId.attendance => HomeFeatureIntroId.attendance,
  };
}

String homeFeatureIntroMessage(HomeFeatureIntroId id) {
  return switch (id) {
    HomeFeatureIntroId.mainCampus => 'メインキャンパスを設定！天気や学バスに反映',
    HomeFeatureIntroId.myCafeteria => 'My食堂でメニューのお気に入り登録',
    HomeFeatureIntroId.assignments => '課題管理で締切と完了を一覧管理',
    HomeFeatureIntroId.contact => 'お問い合わせから運営へ連絡できます',
    HomeFeatureIntroId.theme => 'テーマでライト／ダークを切り替え',
    HomeFeatureIntroId.fontSize => '文字サイズを読みやすく調整',
    HomeFeatureIntroId.calendar => 'カレンダーで学年暦の週始まりを設定',
    HomeFeatureIntroId.classroomMap => '教室マップで建物・教室を検索',
    HomeFeatureIntroId.attendance => '出席管理で出欠を記録・確認',
  };
}
