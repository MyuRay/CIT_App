class AppConstants {
  static const String appName = 'CIT App';
  static const String appVersion = '1.0.0';

  /// 最寄駅電車情報の JSON API ベース URL（空なら Firestore も使わず取得しない）。
  /// 例: `https://asia-northeast1-PROJECT.cloudfunctions.net/trainInfo`
  /// リクエスト: `GET {url}?campus=tsudanuma`（既存クエリがあれば `campus` をマージ）
  ///
  /// APIキーが必要な場合は、この URL を自前プロキシ（Functions/Run）に向けること。
  ///
  /// デプロイ後のモック例（本番プロジェクト）:
  /// `https://us-central1-cit-app-2de1c.cloudfunctions.net/trainInfo`
  static const String trainInfoApiBaseUrl = String.fromEnvironment(
    'TRAIN_INFO_API_BASE_URL',
    defaultValue: '',
  );

  /// モック利用フラグ。`true` / `false` / 未指定（未指定時は [resolveTrainInfoUseMock] 参照）
  static const String _trainInfoUseMockRaw = String.fromEnvironment(
    'TRAIN_INFO_USE_MOCK',
    defaultValue: '',
  );

  /// ODPT 承認前など、HTTP の代わりにローカルモックを使うか。
  ///
  /// - `--dart-define=TRAIN_INFO_USE_MOCK=true` … 常にモック
  /// - `--dart-define=TRAIN_INFO_USE_MOCK=false` … URL 設定時のみ HTTP
  /// - 未指定 … [isDebugMode] が true のときモック（リリースは URL 必須）
  static bool resolveTrainInfoUseMock({required bool isDebugMode}) {
    if (_trainInfoUseMockRaw == 'true') return true;
    if (_trainInfoUseMockRaw == 'false') return false;
    return isDebugMode;
  }
  
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