import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../models/comment/comment_model.dart';
import '../../services/bulletin/bulletin_service.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/comment_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/admin_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bulletin_post_form_screen.dart';
import '../../models/reports/report_model.dart';
import '../reports/report_form_dialog.dart';
import '../user_block/block_confirmation_dialog.dart';
import '../../widgets/profile/author_avatar.dart';
import '../../widgets/profile/author_display_name.dart';

class BulletinPostDetailScreen extends ConsumerStatefulWidget {
  final BulletinPost post;

  const BulletinPostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<BulletinPostDetailScreen> createState() => _BulletinPostDetailScreenState();
}

class _BulletinPostDetailScreenState extends ConsumerState<BulletinPostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  String? _replyToCommentId;
  String? _replyToAuthorName;
  bool _isCommentFormVisible = false;
  
  // クーポン連続押下防止用
  Timer? _couponCooldownTimer;
  int _remainingCooldownSeconds = 0;
  static const int _cooldownDurationSeconds = 300; // 5分 = 300秒
  
  // リアルタイム更新用のStreamを取得
  Stream<BulletinPost> get _postStream {
    return FirebaseFirestore.instance
        .collection('bulletin_posts')
        .doc(widget.post.id)
        .snapshots()
        .map((doc) => BulletinPost.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }));
  }

  @override
  void initState() {
    super.initState();
    // 閲覧数をインクリメント
    _incrementViewCount();
    // クーポンクールダウン状態を確認
    _checkCouponCooldown();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _couponCooldownTimer?.cancel();
    super.dispose();
  }

  // クーポンクールダウン状態を確認
  Future<void> _checkCouponCooldown() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastUsedKey = 'coupon_last_used_${widget.post.id}_${currentUser.uid}';
    final lastUsedTimestamp = prefs.getInt(lastUsedKey);

    if (lastUsedTimestamp != null) {
      final lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastUsedTimestamp);
      final now = DateTime.now();
      final elapsedSeconds = now.difference(lastUsedTime).inSeconds;

      if (elapsedSeconds < _cooldownDurationSeconds) {
        // まだクールダウン中
        setState(() {
          _remainingCooldownSeconds = _cooldownDurationSeconds - elapsedSeconds;
        });
        _startCooldownTimer();
      }
    }
  }

  // クールダウンタイマーを開始
  void _startCooldownTimer() {
    _couponCooldownTimer?.cancel();
    _couponCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingCooldownSeconds > 0) {
        setState(() {
          _remainingCooldownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {});
      }
    });
  }

  Future<void> _incrementViewCount() async {
    try {
      await BulletinService.incrementViewCount(widget.post.id);
    } catch (e) {
      // エラーが発生してもUIには影響させない
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(int.parse('0xff${widget.post.category.color.substring(1)}'));
    
    // コメント投稿状態を監視
    ref.listen<AsyncValue<void>>(commentNotifierProvider, (previous, next) {
      next.when(
        data: (_) {
          // 投稿成功時の処理は_postComment内で行う
        },
        loading: () {
          // ローディング状態（UIで表示される）
        },
        error: (error, stackTrace) {
          print('❌ CommentNotifier エラー: $error');
          // エラー処理は_postComment内で行う
        },
      );
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 通報ボタン（すべてのユーザーに表示、ただし自分の投稿は除く）
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authStateProvider);

              return authState.when(
                data: (user) {
                  if (user == null) {
                    return const SizedBox.shrink();
                  }

                  // 自分の投稿には通報ボタンを表示しない
                  final isOwner = user.uid == widget.post.authorId;
                  if (isOwner) {
                    return const SizedBox.shrink();
                  }

                  print('✅ 通報ボタンを表示します（ユーザー: ${user.email}）');
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flag, color: Colors.red),
                      tooltip: '通報',
                      onPressed: () {
                        print('🔴 通報ボタンがタップされました！');
                        _showPostReportDialog();
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          // 投稿者のみ編集・削除メニューを表示
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authStateProvider);

              return authState.when(
                data: (user) {
                  if (user == null) {
                    return const SizedBox.shrink();
                  }

                  final isOwner = user.uid == widget.post.authorId;
                  final adminState = ref.watch(adminPermissionsProvider(user.uid));

                  // 投稿者または管理者のみメニューを表示
                  final canEdit = isOwner || adminState.when(
                    data: (permissions) => permissions?.isAdmin == true,
                    loading: () => false,
                    error: (_, __) => false,
                  );
                  if (!canEdit) {
                    return const SizedBox.shrink();
                  }

                  return PopupMenuButton<String>(
                    onSelected: _handleMenuSelection,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('編集'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(), // 読み込み中は非表示
                error: (_, __) => const SizedBox.shrink(), // エラー時は非表示
              );
            },
          ),
          // ピン留めアイコンは非表示 (ピン留めの場合はカテゴリ名をフル表示)
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像セクション
            if (widget.post.imageUrl.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showImageDialog(),
                child: Hero(
                  tag: 'image_${widget.post.id}',
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment(widget.post.thumbAlignX, widget.post.thumbAlignY),
                      placeholder: (context, url) => const _BulletinImagePlaceholder(),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 画像タップの注釈
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '画像をタップすると画像全体が表示されます',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // コンテンツセクション
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリとメタ情報
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: categoryColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ピン留め投稿の場合はアイコンを非表示にしてカテゴリ名をフル表示
                            if (!widget.post.isPinned) ...[
                              Icon(
                                _getCategoryIcon(widget.post.category.icon),
                                size: 18,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              widget.post.category.name,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // タイトル
                  Text(
                    widget.post.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // クーポンセクション（リアルタイム更新）- タイトルと本文の間に配置
                  if (widget.post.isCoupon) ...[
                    StreamBuilder<BulletinPost>(
                      stream: _postStream,
                      initialData: widget.post,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return _buildCouponSection(snapshot.data!);
                        }
                        return _buildCouponSection(widget.post);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 説明
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.post.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 外部リンクセクション
                  if (widget.post.externalUrl != null && widget.post.externalUrl!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '関連リンク',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _launchURL(widget.post.externalUrl!),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      color: Colors.blue[700],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '外部サイトを開く',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.post.externalUrl!,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.blue[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new,
                                      color: Colors.blue[700],
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 投稿者情報
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '投稿者情報',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                widget.post.authorName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.visibility, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                '閲覧数: ${widget.post.viewCount + 1}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          if (widget.post.expiresAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  '期限: ${_formatDate(widget.post.expiresAt!)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // コメントセクション（コメント許可の場合のみ表示）
                  if (widget.post.allowComments)
                    _buildCommentsSection()
                  else
                    _buildCommentsDisabledSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.post.allowComments ? _buildCommentInput() : null,
    );
  }

  Widget _buildCommentsSection() {
    final commentsAsync = ref.watch(sortedPostCommentsProvider(widget.post.id));
    final commentStats = ref.watch(commentStatsProvider(widget.post.id));
    final sortOrder = ref.watch(commentSortOrderProvider(widget.post.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // コメントヘッダー
        Row(
          children: [
            Icon(Icons.comment, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'コメント',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 8),
            commentStats.when(
              data: (stats) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stats.totalComments}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              loading: () => Container(),
              error: (_, __) => Container(),
            ),
            const Spacer(),
            PopupMenuButton<CommentSortOrder>(
              tooltip: '並び替え',
              onSelected: (value) {
                ref.read(commentSortOrderProvider(widget.post.id).notifier).state =
                    value;
              },
              itemBuilder: (context) => CommentSortOrder.values
                  .map(
                    (order) => CheckedPopupMenuItem<CommentSortOrder>(
                      value: order,
                      checked: sortOrder == order,
                      child: Text(order.displayName),
                    ),
                  )
                  .toList(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    sortOrder.displayName,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // コメント一覧
        commentsAsync.when(
          data: (commentThreads) {
            if (commentThreads.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'まだコメントがありません',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最初のコメントを投稿してみましょう！',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: commentThreads.map((thread) => _buildCommentThread(thread)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error, color: Colors.red[400]),
                  const SizedBox(height: 8),
                  Text('コメントの読み込みに失敗しました'),
                  Text('$error', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsDisabledSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // コメントヘッダー
        Row(
          children: [
            Icon(Icons.comment_outlined, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'コメント',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // コメント無効化メッセージ
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.comments_disabled,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'コメントは無効化されています',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'この投稿では投稿者がコメントを許可していません',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentThread(CommentThread thread) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 親コメント
            _buildCommentBubble(thread.comment, false),
            
            // 返信一覧
            if (thread.replies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(left: 24),
                child: Column(
                  children: thread.replies.map((reply) => 
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildCommentBubble(reply, true),
                    )
                  ).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentBubble(BulletinComment comment, bool isReply) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthorAvatar(
          authorId: comment.authorId,
          displayName: comment.authorName,
          radius: isReply ? 16 : 20,
        ),
        const SizedBox(width: 12),
        
        // コメント内容
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isReply ? Colors.grey[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isReply ? Colors.grey[200]! : Colors.blue[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー（名前・時間）
                Row(
                  children: [
                    AuthorDisplayName(
                      authorId: comment.authorId,
                      fallback: comment.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isReply ? Colors.grey[700] : Colors.blue[700],
                        fontSize: isReply ? 13 : 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    if (comment.isEdited) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(編集済み)',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                
                // コメント本文
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: isReply ? 13 : 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                
                // アクションボタン
                Row(
                  children: [
                    // いいねボタン（トグル）
                    InkWell(
                      onTap: () => _toggleLikeComment(comment),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLikeIcon(comment),
                            if (comment.likeCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likeCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // 返信ボタン（親コメントのみ）
                    if (!isReply) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _startReply(comment.id, comment.authorName),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.reply,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '返信',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // 削除ボタン（自分のコメントまたは管理者のみ）
                    Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authStateProvider);
                        return authState.when(
                          data: (user) {
                            if (user == null) return const SizedBox.shrink();

                            final isOwner = user.uid == comment.authorId;
                            final adminState = ref.watch(adminPermissionsProvider(user.uid));
                            final isAdmin = adminState.when(
                              data: (permissions) => permissions?.isAdmin == true,
                              loading: () => false,
                              error: (_, __) => false,
                            );

                            if (!isOwner && !isAdmin) return const SizedBox.shrink();

                            return Row(
                              children: [
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _showDeleteCommentDialog(comment),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '削除',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),

                    // その他メニュー（通報・ブロック）
                    Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authStateProvider);
                        return authState.when(
                          data: (user) {
                            if (user == null) return const SizedBox.shrink();

                            // 自分のコメントには表示しない
                            final isOwner = user.uid == comment.authorId;
                            if (isOwner) return const SizedBox.shrink();

                            return Row(
                              children: [
                                const SizedBox(width: 12),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  onSelected: (value) {
                                    if (value == 'report') {
                                      _showCommentReportDialog(comment);
                                    } else if (value == 'block') {
                                      _showBlockUserDialog(comment.authorId, comment.authorName);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'report',
                                      child: Row(
                                        children: [
                                          Icon(Icons.flag, size: 18),
                                          SizedBox(width: 8),
                                          Text('通報'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'block',
                                      child: Row(
                                        children: [
                                          Icon(Icons.block, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('ブロック', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 返信表示
          if (_replyToCommentId != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    '$_replyToAuthorName さんに返信',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: Colors.blue[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // 入力フィールド
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyToCommentId != null 
                        ? '返信を入力...' 
                        : 'コメントを入力...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, child) {
                  final commentState = ref.watch(commentNotifierProvider);
                  final isLoading = commentState.isLoading;
                  
                  return CircleAvatar(
                    backgroundColor: isLoading ? Colors.grey[400] : Colors.blue[600],
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _postComment,
                          ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageDialog() {
    if (widget.post.imageUrl.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                maxScale: 3.0,
                child: Hero(
                  tag: 'image_${widget.post.id}',
                  child: CachedNetworkImage(
                    imageUrl: widget.post.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const _BulletinImagePlaceholder(),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'event':
        return Icons.event;
      case 'group':
        return Icons.group;
      case 'school':
        return Icons.school;
      case 'announcement':
        return Icons.announcement;
      case 'work':
        return Icons.work;
      case 'local_offer':
        return Icons.local_offer;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.circle;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }


  void _handleMenuSelection(String value) async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインが必要です'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final isOwner = user.uid == widget.post.authorId;
    final adminState = ref.read(adminPermissionsProvider(user.uid));
    final isAdmin = adminState.when(
      data: (permissions) => permissions?.isAdmin == true,
      loading: () => false,
      error: (_, __) => false,
    );
    
    // セキュリティチェック: 投稿者本人または管理者でない場合は操作を拒否
    if (!isOwner && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('この操作は投稿者または管理者のみ実行できます'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    switch (value) {
      case 'edit':
        _editPost();
        break;
      case 'delete':
        _showDeleteConfirmDialog();
        break;
    }
  }
  
  void _editPost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulletinPostEditScreen(post: widget.post),
      ),
    ).then((updated) async {
      if (updated == true) {
        await ref.read(bulletinFeedProvider.notifier).refresh();
      }
    });
  }
  
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('投稿を削除'),
          ],
        ),
        content: const Text(
          'この投稿を削除しますか？\n削除された投稿は復元できません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    // 再度セキュリティチェック: 投稿者本人または管理者でない場合は削除を拒否
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインが必要です'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final isOwner = user.uid == widget.post.authorId;
    final adminState = ref.read(adminPermissionsProvider(user.uid));
    final isAdmin = adminState.when(
      data: (permissions) => permissions?.isAdmin == true,
      loading: () => false,
      error: (_, __) => false,
    );
    
    if (!isOwner && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('この操作は投稿者または管理者のみ実行できます'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('削除中...'),
              ],
            ),
          ),
        ),
      );

      // Firebase Storageから画像を削除
      if (widget.post.imageUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(widget.post.imageUrl);
          await ref.delete();
          print('📸 画像を削除: ${ref.fullPath}');
        } catch (e) {
          print('⚠️ 画像削除エラー (続行): $e');
          // 画像削除に失敗してもドキュメントは削除する
        }
      }

      // Firestoreから投稿を削除
      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(widget.post.id)
          .delete();

      print('✅ 投稿を削除: ${widget.post.id}');

      // ローディング閉じる
      if (mounted) Navigator.of(context).pop();

      // プロバイダーを更新
      await ref.read(bulletinFeedProvider.notifier).refresh();

      // 成功メッセージ表示後、画面を閉じる
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('投稿を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ 投稿削除エラー: $e');
      
      // ローディング閉じる
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('リンクを開けませんでした: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ URL起動エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('リンクを開くのに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      print('🔄 コメント投稿開始: $content');
      
      final commentNotifier = ref.read(commentNotifierProvider.notifier);
      final currentUserName = ref.read(currentUserDisplayNameProvider);
      
      print('📝 投稿者名: $currentUserName');
      print('📝 投稿ID: ${widget.post.id}');
      print('📝 返信先: $_replyToCommentId');
      
      await commentNotifier.postComment(
        postId: widget.post.id,
        content: content,
        authorName: currentUserName,
        parentCommentId: _replyToCommentId,
      );

      print('✅ コメント投稿完了');

      // 投稿成功後の処理
      _commentController.clear();
      _cancelReply();
      
      print('🔄 コメントリストの即時更新開始...');
      
      // コメントリストプロバイダーを即座に更新
      ref.invalidate(postCommentsProvider(widget.post.id));
      
      // 統計プロバイダーも更新
      ref.invalidate(commentStatsProvider(widget.post.id));
      
      // 即座にリフレッシュして新しいデータを取得
      try {
        await ref.refresh(postCommentsProvider(widget.post.id).future);
        await ref.refresh(commentStatsProvider(widget.post.id).future);
      } catch (e) {
        print('⚠️ リフレッシュエラー (無視): $e');
      }
      
      print('🔄 コメントリストの即時更新完了');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('コメントを投稿しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ コメント投稿エラー: $e');
      print('❌ スタックトレース: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('コメントの投稿に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToAuthorName = authorName;
      _isCommentFormVisible = true;
    });
    
    // キーボードを表示してフォーカスを当てる
    FocusScope.of(context).requestFocus(FocusNode());
    _commentController.clear();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAuthorName = null;
      _isCommentFormVisible = false;
    });
  }

  Future<void> _likeComment(String commentId) async {
    try {
      print('👍 いいね処理開始: $commentId');
      
      // CommentServiceを直接呼び出し
      await CommentService.likeComment(commentId);
      
      print('🔄 いいね後のリスト更新開始...');
      
      // コメントリストと統計を即座に更新
      ref.invalidate(postCommentsProvider(widget.post.id));
      ref.invalidate(commentStatsProvider(widget.post.id));
      
      // 即座にリフレッシュ
      try {
        await ref.refresh(postCommentsProvider(widget.post.id).future);
        await ref.refresh(commentStatsProvider(widget.post.id).future);
        print('✅ いいね後のリスト更新完了');
      } catch (e) {
        print('⚠️ リフレッシュエラー (無視): $e');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('いいねに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // いいねアイコン（自分のいいね済みを視覚化）
  Widget _buildLikeIcon(BulletinComment comment) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = (comment.likedBy != null && uid != null && (comment.likedBy![uid] == true));
    return Icon(
      isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
      size: 16,
      color: isLiked ? Theme.of(context).colorScheme.primary : Colors.grey[600],
    );
  }

  Future<void> _toggleLikeComment(BulletinComment comment) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = (comment.likedBy != null && uid != null && (comment.likedBy![uid] == true));
    try {
      if (isLiked) {
        await CommentService.unlikeComment(comment.id);
      } else {
        await CommentService.likeComment(comment.id);
      }

      // 反映
      ref.invalidate(postCommentsProvider(widget.post.id));
      ref.invalidate(commentStatsProvider(widget.post.id));
      try {
        await ref.refresh(postCommentsProvider(widget.post.id).future);
        await ref.refresh(commentStatsProvider(widget.post.id).future);
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('いいね操作に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteCommentDialog(BulletinComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('コメントを削除'),
          ],
        ),
        content: const Text(
          'このコメントを削除しますか？\n削除されたコメントは復元できません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteComment(comment.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      // セキュリティチェック: コメントの削除権限を確認
      final authState = ref.read(authStateProvider);
      final currentUser = authState.value;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインが必要です'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // コメントの詳細を取得して所有者チェック
      final commentDoc = await FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc(commentId)
          .get();
      
      if (!commentDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('コメントが見つかりません'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final commentData = commentDoc.data()!;
      final commentAuthorId = commentData['authorId'] as String;
      
      // 権限チェック: コメント作成者または管理者のみ削除可能
      final isOwner = currentUser.uid == commentAuthorId;
      final adminState = ref.read(adminPermissionsProvider(currentUser.uid));
      final isAdmin = adminState.when(
        data: (permissions) => permissions?.isAdmin == true,
        loading: () => false,
        error: (_, __) => false,
      );
      
      if (!isOwner && !isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('この操作はコメント作成者または管理者のみ実行できます'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      print('🗑️ コメント削除開始: $commentId');
      
      final commentNotifier = ref.read(commentNotifierProvider.notifier);
      
      // コメントを削除
      await commentNotifier.deleteComment(commentId);
      
      print('🔄 削除後のリスト更新開始...');
      
      // コメントリストと統計を即座に更新
      ref.invalidate(postCommentsProvider(widget.post.id));
      ref.invalidate(commentStatsProvider(widget.post.id));
      
      // 即座にリフレッシュ
      try {
        await ref.refresh(postCommentsProvider(widget.post.id).future);
        await ref.refresh(commentStatsProvider(widget.post.id).future);
        print('✅ 削除後のリスト更新完了');
      } catch (e) {
        print('⚠️ リフレッシュエラー (無視): $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('コメントを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('コメントの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // クーポンセクションを構築
  Widget _buildCouponSection(BulletinPost post) {
    return Card(
      color: Colors.pink.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: Colors.pink.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'クーポン',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 使用状況表示
            Consumer(
              builder: (context, ref, child) {
                final currentUser = FirebaseAuth.instance.currentUser;
                final usedBy = post.couponUsedBy ?? <String, int>{};
                final currentUserUsageCount = currentUser != null ? (usedBy[currentUser.uid] ?? 0) : 0;
                
                if (post.couponMaxUses != null) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.confirmation_num, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '使用回数: $currentUserUsageCount / ${post.couponMaxUses!}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.confirmation_num, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '使用回数: ${currentUserUsageCount}回（無制限）',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }
              },
            ),
            
            // クーポン使用ボタン
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _canUseCoupon(post) && _remainingCooldownSeconds == 0
                        ? () => _useCoupon(post)
                        : null,
                    icon: const Icon(Icons.redeem),
                    label: Text(_getCouponButtonText(post)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _remainingCooldownSeconds > 0
                          ? Colors.grey
                          : Colors.pink.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (_remainingCooldownSeconds > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '次回使用可能まであと ${_formatCooldownTime(_remainingCooldownSeconds)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // クーポン使用可能かチェック
  bool _canUseCoupon(BulletinPost post) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    // クールダウン中は使用不可
    if (_remainingCooldownSeconds > 0) {
      return false;
    }
    
    // ユーザーごとの使用回数上限チェック
    final usedBy = post.couponUsedBy ?? <String, int>{};
    final currentUserUsageCount = usedBy[currentUser.uid] ?? 0;
    
    if (post.couponMaxUses != null && 
        currentUserUsageCount >= post.couponMaxUses!) {
      return false;
    }
    
    return true;
  }

  // ボタンテキストを取得
  String _getCouponButtonText(BulletinPost post) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 'ログインが必要';
    
    // 使用間隔制限中
    if (_remainingCooldownSeconds > 0) {
      return 'しばらくお待ちください';
    }
    
    // ユーザーごとの使用回数上限チェック
    final usedBy = post.couponUsedBy ?? <String, int>{};
    final currentUserUsageCount = usedBy[currentUser.uid] ?? 0;
    
    if (post.couponMaxUses != null && 
        currentUserUsageCount >= post.couponMaxUses!) {
      return '使用回数上限に達しています';
    }
    
    return 'クーポンを使用する';
  }

  // クールダウン時間をフォーマット
  String _formatCooldownTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}分${remainingSeconds.toString().padLeft(2, '0')}秒';
  }

  // クーポン使用処理
  void _useCoupon(BulletinPost post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.pink),
            SizedBox(width: 8),
            Text('クーポン使用確認'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${post.title}」のクーポンを使用しますか？'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '「使用する」を押すと連続使用防止のため5分間押せなくなります',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('使用する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BulletinService.useCoupon(post.id, currentUser.uid);
        
        // クールダウンを開始
        final prefs = await SharedPreferences.getInstance();
        final lastUsedKey = 'coupon_last_used_${post.id}_${currentUser.uid}';
        await prefs.setInt(lastUsedKey, DateTime.now().millisecondsSinceEpoch);
        
        setState(() {
          _remainingCooldownSeconds = _cooldownDurationSeconds;
        });
        _startCooldownTimer();
        
        if (mounted) {
          // 成功ポップアップを表示（投稿者名も含む）
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('クーポン使用完了'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('「${post.title}」のクーポンを使用しました！'),
                  const SizedBox(height: 8),
                  Text(
                    '投稿者: ${post.authorName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          
          // 画面をリアルタイム更新するために setState を呼び出し
          setState(() {
            // ウィジェットの再描画をトリガー
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('クーポン使用に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showPostReportDialog() async {
    print('🚩 投稿通報ダイアログを表示します');
    try {
      final result = await showReportDialog(
        context,
        type: ReportType.post,
        targetId: widget.post.id,
        targetTitle: widget.post.title.isNotEmpty ? widget.post.title : '投稿',
      );

      print('🚩 投稿通報ダイアログ結果: $result');
    } catch (e, stackTrace) {
      print('❌ 投稿通報ダイアログエラー: $e');
      print('❌ スタックトレース: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('通報フォームの表示に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // コメントの通報ダイアログを表示
  Future<void> _showCommentReportDialog(BulletinComment comment) async {
    print('🚩 コメント通報ダイアログを表示します');
    try {
      final result = await showReportDialog(
        context,
        type: ReportType.comment,
        targetId: comment.id,
        targetTitle: '${comment.authorName}のコメント',
      );

      print('🚩 コメント通報ダイアログ結果: $result');
      if (result == true && mounted) {
        // 通報が成功した場合は何もしない（ダイアログ内でメッセージ表示済み）
      }
    } catch (e) {
      print('❌ コメント通報ダイアログエラー: $e');
    }
  }

  // ユーザーのブロックダイアログを表示
  Future<void> _showBlockUserDialog(String userId, String userName) async {
    print('🚫 ブロックダイアログを表示します: $userName');
    try {
      final result = await showBlockConfirmationDialog(
        context,
        blockedUserId: userId,
        blockedUserName: userName,
      );

      print('🚫 ブロックダイアログ結果: $result');
      if (result == true && mounted) {
        // ブロックが成功した場合、コメント一覧を更新
        ref.invalidate(postCommentsProvider(widget.post.id));
      }
    } catch (e) {
      print('❌ ブロックダイアログエラー: $e');
    }
  }

}

class _BulletinImagePlaceholder extends StatefulWidget {
  const _BulletinImagePlaceholder({this.icon = Icons.photo});

  final IconData icon;

  @override
  State<_BulletinImagePlaceholder> createState() => _BulletinImagePlaceholderState();
}

class _BulletinImagePlaceholderState extends State<_BulletinImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = Color.lerp(base, highlight, _animation.value)!;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: color,
          ),
          child: Icon(
            widget.icon,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 48,
          ),
        );
      },
    );
  }
}
