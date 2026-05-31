import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

class AppConstants {
  static const String appName = 'CIT App';
  static const String appVersion = '1.0.0';
  static const String appDescriptionTitle = '千葉工業大学向け大学生活支援アプリ';
  static const String appDescriptionSubtitle = '時間割・掲示板・学食情報などを提供';
  static const int developerRecruitmentTapThreshold = 50;
  static const String developerRecruitmentUrl = 'https://cit-app.com/';
  static const String developerRecruitmentEmail = 'citapp919@gmail.com';
  static const String developerRecruitmentEmailSubject = '開発メンバー応募';
  
  // 許可されたドメイン（複数対応）
  static const List<String> allowedDomains = [
    '@s.chibakoudai.jp',
    '@p.chibakoudai.jp',
    '@chibatech.ac.jp',
  ];

  /// ドメイン変更前の旧メールアドレス（変更推奨ポップアップ対象）
  static const List<String> legacyEmailDomains = [
    '@s.chibakoudai.jp',
    '@p.chibakoudai.jp',
  ];

  /// 移行先の新ドメイン
  static const String newEmailDomain = '@chibatech.ac.jp';
  
  static const String errorInvalidEmail = 'メールアドレスの形式が正しくありません';
  static const String errorInvalidDomain = 'CITのメールアドレスを使用してください\n（@s.chibakoudai.jp / @p.chibakoudai.jp / @chibatech.ac.jp）';
  static const String errorEmailLocalPart =
      'メールアドレス（@より前）は半角英数字（大文字・小文字）および . _ + - のみ使用できます';
  static const String errorWeakPassword = 'パスワードは6文字以上で入力してください';
  static const String errorPasswordChars =
      'パスワードは半角英数字（大文字・小文字）のみ使用できます';
  static const String errorPasswordMismatch = 'パスワードが一致しません';

  static const String emailInputHelper =
      '※ @より前は半角英数字（大文字・小文字）・. _ + - が使用できます';
  static const String passwordInputHelper =
      '※ 半角英数字（大文字・小文字）6文字以上';

  /// メールアドレス（@より前）: 半角英数字と . _ + -
  static final RegExp emailLocalPartPattern = RegExp(r'^[a-zA-Z0-9._+-]+$');

  /// パスワード: 半角英数字のみ
  static final RegExp passwordPattern = RegExp(r'^[a-zA-Z0-9]+$');

  /// Cwitter ID: 半角英数字と _ 3〜10 文字
  static final RegExp cwitterIdPattern = RegExp(r'^[a-zA-Z0-9_]{3,10}$');

  static const String cwitterIdInputHelper =
      '※ 半角英数字と _ 3〜10 文字（設定後は変更できません）';
  static const String errorCwitterIdFormat =
      'Cwitter IDは半角英数字と _ で3〜10文字で入力してください';
  static const String errorCwitterIdTaken = 'このIDは既に使用されています';

  /// CIT App 公式 Cwitter アカウント（ハードコード）
  static const String cwitterOfficialCwitterId = 'citapp';

  static bool isOfficialCwitterAccount(String? cwitterId) {
    if (cwitterId == null || cwitterId.trim().isEmpty) return false;
    return cwitterId.trim().toLowerCase() == cwitterOfficialCwitterId;
  }

  static const String errorOfficialAccountBlockDenied =
      'このアカウントは重要な情報の発信を含む公式アカウントのためブロックすることはできません';

  /// Cwitter プロフィールの自己紹介（bio）
  static const int cwitterBioMaxLength = 160;
  static const String cwitterBioInputHelper = '※ 160文字以内';

  /// Cwitter プロフィールの SNS リンク（各プラットフォームの ID / URL）
  static const int cwitterSocialLinkMaxLength = 200;

  /// Cwitter プロフィールのハッシュタグ（例: 27卒、建築、🔥）
  static const int cwitterTagsMaxCount = 2;
  static const int cwitterTagMaxLength = 5;
  /// Firestore rules 用（UTF-8 バイト上限。5文字分の日本語・絵文字を許容）
  static const int cwitterTagMaxUtf8Bytes = 20;
  static const String cwitterTagsInputHelper =
      '※ 最大2件、各5文字以内（絵文字可、例: 27卒、🔥）';
  static const String errorCwitterTagFormat =
      'ハッシュタグは5文字以内で入力してください（絵文字可、空白・# は不可）';

  /// ハッシュタグの形式チェック（日本語・英数字・絵文字など、空白と # のみ不可）
  static bool isValidCwitterTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains('#') || RegExp(r'\s').hasMatch(trimmed)) {
      return false;
    }
    return trimmed.characters.length <= cwitterTagMaxLength;
  }

  /// フィードの1回あたり読み込み件数（Cwitter・掲示板共通）
  static const int postPageSize = 30;

  static final List<TextInputFormatter> citEmailInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+-]')),
  ];

  static final List<TextInputFormatter> passwordInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
  ];
  
  /// 旧ドメインのメールアドレスか（変更推奨ポップアップ表示対象）
  static bool shouldPromptEmailMigration(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final normalized = email.trim().toLowerCase();
    return legacyEmailDomains.any((domain) => normalized.endsWith(domain.toLowerCase()));
  }

  /// 新ドメイン（@chibatech.ac.jp）のメールアドレスか
  static bool hasChibatechEmailDomain(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return email.trim().toLowerCase().endsWith(newEmailDomain.toLowerCase());
  }

  /// マイページに「メールアドレスを変更」を表示するか
  static bool shouldShowEmailChangeButton(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return !hasChibatechEmailDomain(email);
  }

  /// 旧メールから新ドメインへの移行候補（例: foo@s.chibakoudai.jp → foo@chibatech.ac.jp）
  static String? suggestMigratedEmail(String? currentEmail) {
    if (currentEmail == null || currentEmail.trim().isEmpty) return null;
    if (hasChibatechEmailDomain(currentEmail)) return null;

    final at = currentEmail.indexOf('@');
    if (at <= 0) return null;

    final localPart = currentEmail.substring(0, at).trim();
    if (localPart.isEmpty || !emailLocalPartPattern.hasMatch(localPart)) {
      return null;
    }
    return '$localPart$newEmailDomain';
  }

  // ドメインチェック用のヘルパーメソッド（大文字・小文字を区別しない）
  static bool isAllowedDomain(String email) {
    final normalized = email.trim().toLowerCase();
    return allowedDomains.any((domain) => normalized.endsWith(domain.toLowerCase()));
  }

  static bool isValidEmailLocalPart(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return false;
    return emailLocalPartPattern.hasMatch(email.substring(0, at));
  }

  static bool isValidPasswordFormat(String password) {
    return password.length >= 6 && passwordPattern.hasMatch(password);
  }

  /// 登録・メール変更時のメール形式チェック
  static bool isValidCitEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return false;
    if (!isValidEmailLocalPart(trimmed)) return false;
    return isAllowedDomain(trimmed);
  }

  static String? validateCitEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'メールアドレスを入力してください';
    }
    final email = value.trim();
    if (!email.contains('@')) return errorInvalidEmail;
    if (!isValidEmailLocalPart(email)) return errorEmailLocalPart;
    if (!isAllowedDomain(email)) return errorInvalidDomain;
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < 6) return errorWeakPassword;
    if (!passwordPattern.hasMatch(value)) return errorPasswordChars;
    return null;
  }
  
  // ドメイン表示用のテキスト
  static String get allowedDomainsText => allowedDomains.join(' または ');

  /// メール変更フロー用 SharedPreferences キー
  static const String pendingEmailChangeKey = 'pending_email_change';
  static const String postEmailChangeLoginEmailKey = 'post_email_change_login_email';

  /// 利用規約・プライバシーポリシー同意（更新版）の SharedPreferences キー
  static const String legalConsentAcceptedVersionKey =
      'legal_consent_accepted_version';

  /// 現在の同意が必要な規約バージョン（更新時に値を上げる）
  static const String currentLegalConsentVersion = '2026-05-31-community';
}