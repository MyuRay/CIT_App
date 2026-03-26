class AppConstants {
  static const String appName = 'CIT App';
  static const String appVersion = '1.0.0';
  
  // 許可されたドメイン（複数対応）
  static const List<String> allowedDomains = [
    '@s.chibakoudai.jp',
    '@p.chibakoudai.jp',
    '@chibatech.ac.jp',
  ];
  
  static const String errorInvalidEmail = 'メールアドレスの形式が正しくありません';
  static const String errorInvalidDomain = 'CITのメールアドレスを使用してください\n（@s.chibakoudai.jp / @p.chibakoudai.jp / @chibatech.ac.jp）';
  static const String errorWeakPassword = 'パスワードは6文字以上で入力してください';
  static const String errorPasswordMismatch = 'パスワードが一致しません';
  
  // ドメインチェック用のヘルパーメソッド
  static bool isAllowedDomain(String email) {
    return allowedDomains.any((domain) => email.endsWith(domain));
  }
  
  // ドメイン表示用のテキスト
  static String get allowedDomainsText => allowedDomains.join(' または ');

  /// iOS: GoogleService-Info.plist 未配置など Firebase 未初期化時（チーム開発・README 参照）
  static const String firebaseNotConfiguredMessage =
      'Firebase が未設定です。Firebase Console から GoogleService-Info.plist を取得し、'
      'ios/Runner に配置して Xcode の Runner ターゲットに追加してください（README の Firebase 設定）。';
}