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
}