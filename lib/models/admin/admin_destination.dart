import 'package:flutter/material.dart';

enum AdminCategory {
  publishing('配信・スポンサー'),
  support('問い合わせ・安全管理'),
  campus('キャンパス運営');

  const AdminCategory(this.label);
  final String label;
}

enum AdminDestination {
  bulletin(
    '掲示板管理',
    '投稿・掲載期限・スポンサー枠を管理',
    Icons.forum_outlined,
    AdminCategory.publishing,
    '投稿 お知らせ 金色 クーポン',
  ),
  ads(
    '広告管理',
    'スポンサー広告の作成・配信設定',
    Icons.workspace_premium_outlined,
    AdminCategory.publishing,
    '営業 金色 スポンサー バナー',
  ),
  notifications(
    '通知管理',
    'お知らせの作成・配信履歴',
    Icons.notifications_outlined,
    AdminCategory.publishing,
    '送信 プッシュ アップデート',
  ),
  approvals(
    '投稿申請管理',
    '掲示板への投稿を確認・承認',
    Icons.fact_check_outlined,
    AdminCategory.support,
    '承認待ち 審査 却下 ピン留め',
  ),
  contacts(
    'お問い合わせ管理',
    '未対応の確認・返信・対応履歴',
    Icons.support_agent,
    AdminCategory.support,
    '問い合わせ サポート 質問 不具合 要望',
  ),
  reports(
    '通報管理',
    '通報内容の確認と対応記録',
    Icons.flag_outlined,
    AdminCategory.support,
    'モデレーション 違反 安全',
  ),
  users(
    'ユーザー管理',
    'アカウント状態・管理者権限を確認',
    Icons.people_outline,
    AdminCategory.support,
    '会員 権限 アカウント 停止',
  ),
  bus(
    '学バス管理',
    '路線・時刻表・運行期間を設定',
    Icons.directions_bus_outlined,
    AdminCategory.campus,
    'バス 交通 臨時便',
  ),
  lecturePeriod(
    '講義期間設定',
    '前期・後期の開始日と終了日',
    Icons.date_range_outlined,
    AdminCategory.campus,
    '学期 授業 時間割',
  ),
  calendar(
    '学年暦予定管理',
    'ホームに表示する学年暦の予定',
    Icons.event_note_outlined,
    AdminCategory.campus,
    'カレンダー 行事 休講',
  );

  const AdminDestination(
    this.title,
    this.description,
    this.icon,
    this.category,
    this.keywords,
  );
  final String title;
  final String description;
  final IconData icon;
  final AdminCategory category;
  final String keywords;

  bool matches(String query) {
    final words = query.trim().toLowerCase().split(RegExp(r'\s+'));
    final text =
        '$title $description $keywords ${category.label}'.toLowerCase();
    return words.every(text.contains);
  }
}
