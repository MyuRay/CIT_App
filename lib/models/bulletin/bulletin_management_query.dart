import 'bulletin_model.dart';

enum BulletinStatusFilter {
  all('すべて'),
  published('公開中'),
  pending('承認待ち'),
  sponsored('スポンサー'),
  inactive('非公開'),
  expired('期限切れ'),
  pinned('ピン留め'),
  approved('承認済'),
  rejected('却下');

  const BulletinStatusFilter(this.label);
  final String label;

  bool matches(BulletinPost post, DateTime now) => switch (this) {
    all => true,
    published => post.isPublishedAt(now),
    pending => post.approvalStatus == 'pending',
    sponsored => post.isSponsored,
    inactive => !post.isActive,
    expired => post.expiresAt != null && !now.isBefore(post.expiresAt!),
    pinned => post.isPinned,
    approved => post.approvalStatus == 'approved',
    rejected => post.approvalStatus == 'rejected',
  };
}

enum BulletinSort {
  newest('新しい順'),
  oldest('古い順'),
  views('閲覧数が多い順'),
  expiry('掲載期限が近い順');

  const BulletinSort(this.label);
  final String label;
}

List<BulletinPost> queryManagedBulletins(
  List<BulletinPost> posts, {
  required DateTime now,
  String search = '',
  String? categoryId,
  BulletinStatusFilter status = BulletinStatusFilter.all,
  BulletinSort sort = BulletinSort.newest,
}) {
  final q = search.trim().toLowerCase();
  final result =
      posts
          .where(
            (post) =>
                (categoryId == null || post.category.id == categoryId) &&
                status.matches(post, now) &&
                (q.isEmpty ||
                    [
                      post.title,
                      post.description,
                      post.authorName,
                      post.sponsorName,
                    ].any((text) => text.toLowerCase().contains(q))),
          )
          .toList();
  result.sort((a, b) {
    final compare = switch (sort) {
      BulletinSort.newest => b.createdAt.compareTo(a.createdAt),
      BulletinSort.oldest => a.createdAt.compareTo(b.createdAt),
      BulletinSort.views => b.viewCount.compareTo(a.viewCount),
      BulletinSort.expiry =>
        a.expiresAt == null
            ? (b.expiresAt == null ? 0 : 1)
            : b.expiresAt == null
            ? -1
            : a.expiresAt!.compareTo(b.expiresAt!),
    };
    return compare != 0 ? compare : a.id.compareTo(b.id);
  });
  return result;
}

String bulletinManagementCsv(List<BulletinPost> visiblePosts) {
  String cell(String value) {
    // Quoting alone does not stop spreadsheet formula execution.
    final safe = RegExp(r'^[\s]*[=+\-@]').hasMatch(value) ? "'$value" : value;
    return '"' + safe.replaceAll('"', '""') + '"';
  }

  final rows = <List<String>>[
    [
      '投稿ID',
      'タイトル',
      'カテゴリ',
      '承認状態',
      '公開設定',
      'ピン留め',
      'スポンサー枠',
      'スポンサー名',
      '作成日時',
      '掲載期限',
      '閲覧数',
    ],
    for (final post in visiblePosts)
      [
        post.id,
        post.title,
        post.category.name,
        post.approvalStatus,
        post.isActive ? '有効' : '無効',
        post.isPinned ? 'あり' : 'なし',
        post.isSponsored ? 'あり' : 'なし',
        post.sponsorName,
        post.createdAt.toIso8601String(),
        post.expiresAt?.toIso8601String() ?? '',
        post.viewCount.toString(),
      ],
  ];
  return rows.map((row) => row.map(cell).join(',')).join('\r\n');
}
