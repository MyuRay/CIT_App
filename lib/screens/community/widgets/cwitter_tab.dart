import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/cwitter_like_override_provider.dart';
import '../../../core/providers/cwitter_recweet_override_provider.dart';
import '../../../core/providers/cwitter_reply_count_override_provider.dart';
import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/cwitter_composer_back_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_poll.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../models/community/cwitter_follow_user.dart';
import '../../../models/user/user_model.dart';
import '../../../services/community/cwitter_post_image_service.dart';
import '../../../services/community/cwitter_service.dart';
import 'cwitter_avatar.dart';
import 'cwitter_post_images_grid.dart';
import 'cwitter_id_setup_view.dart';
import 'cwitter_post_card.dart';
import 'cwitter_posting_guidelines_dialog.dart';
import '../../../widgets/ads/in_app_ad_banner_slot.dart';
import '../../../widgets/ads/in_app_ad_intervals.dart';
import '../../../widgets/ads/in_app_ad_list_inserter.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';

const _composerPlaceholders = [
  'いま何してる？',
  '学食混んでる？',
  'CITにゃんこ見た？',
  '図書館空いてる？',
  '今日の昼食何食べた？',
  '空きコマ誰かいない？',
  '一緒に昼食行かない？',
  '今日の試験どうだった？',
  '卒論進んでる？',
  '今の学バス混んでる？',
  '今日何か変わったことあった？',
  '空きコマは何してる？',
  '食堂の席空いてる？',
  '今日講義で分からないところあった？',
  '千葉工大あるあるって？',
  'おすすめの勉強場所は？',
];

class CwitterTab extends ConsumerStatefulWidget {
  const CwitterTab({super.key, this.isActiveTab = true});

  final bool isActiveTab;

  @override
  ConsumerState<CwitterTab> createState() => _CwitterTabState();
}

class _CwitterTabState extends ConsumerState<CwitterTab> {
  final _composerController = TextEditingController();
  final _composerFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _pendingImages = <XFile>[];
  bool _isPosting = false;
  bool _composerExpanded = false;
  bool _pollEnabled = false;
  late final List<TextEditingController> _pollOptionControllers;
  late String _composerPlaceholder;
  final Object _composerTapGroup = Object();
  CwitterFeedTab _feedTab = CwitterFeedTab.everyone;
  bool _showNewPostsBanner = false;
  int? _feedSnapshotCreatedAtMs;
  bool _isHandlingComposerBack = false;
  static const _feedTopThreshold = 48.0;

  bool get _isComposerInputActive =>
      _composerExpanded || _composerFocusNode.hasFocus;

  bool get _isComposerExpanded =>
      _composerExpanded ||
      _composerController.text.isNotEmpty ||
      _pendingImages.isNotEmpty ||
      _pollEnabled;

  bool get _hasComposerDraft =>
      _composerController.text.trim().isNotEmpty ||
      _pendingImages.isNotEmpty ||
      _pollEnabled;

  List<String> get _filledPollOptions => _pollOptionControllers
      .map((controller) => controller.text.trim())
      .where((text) => text.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _composerPlaceholder = _pickComposerPlaceholder();
    _pollOptionControllers = List.generate(
      CwitterPoll.minOptions,
      (_) => TextEditingController(),
    );
    _composerFocusNode.addListener(_onComposerFocusChange);
    _scrollController.addListener(_onFeedScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncComposerBackGate();
    });
  }

  void _syncComposerBackGate() {
    if (!mounted) return;
    ref.read(cwitterComposerBackGateProvider.notifier).set(
          isTabVisible: widget.isActiveTab,
          isInputActive: _isComposerInputActive,
          handleBack: _handleComposerBackPress,
        );
  }

  String _pickComposerPlaceholder({String? current}) {
    if (_composerPlaceholders.length <= 1) {
      return _composerPlaceholders.first;
    }

    var next = _composerPlaceholders[Random().nextInt(_composerPlaceholders.length)];
    while (next == current) {
      next = _composerPlaceholders[Random().nextInt(_composerPlaceholders.length)];
    }
    return next;
  }

  void _onFeedScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    if (position.pixels <= _feedTopThreshold) {
      _syncFeedSnapshotAtTop();
    }

    if (position.pixels < position.maxScrollExtent - 240) return;

    final feed = ref.read(cwitterFeedProvider);
    if (feed.isLoading || feed.isLoadingMore || !feed.hasMore) return;
    ref.read(cwitterFeedProvider.notifier).loadMore();
  }

  int _resolveFeedSnapshotMs() {
    final streamLatest =
        ref.read(cwitterLatestPostCreatedAtProvider).valueOrNull;
    if (streamLatest != null) {
      return streamLatest.millisecondsSinceEpoch;
    }

    final posts = ref.read(cwitterPostsProvider).valueOrNull;
    if (posts == null || posts.isEmpty) {
      return _feedSnapshotCreatedAtMs ?? 0;
    }
    return posts
        .map((post) => post.createdAt.millisecondsSinceEpoch)
        .reduce((a, b) => a > b ? a : b);
  }

  void _syncFeedSnapshotAtTop() {
    final latestMs = _resolveFeedSnapshotMs();
    final shouldUpdate =
        _showNewPostsBanner || _feedSnapshotCreatedAtMs != latestMs;
    if (shouldUpdate) {
      setState(() {
        _feedSnapshotCreatedAtMs = latestMs;
        _showNewPostsBanner = false;
      });
    }
    markCwitterFeedSeen(ref);
  }

  void _checkForNewPostsWhileScrolled() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= _feedTopThreshold) return;

    final latest =
        ref.read(cwitterLatestPostCreatedAtProvider).valueOrNull;
    if (latest == null) return;

    final snapshot = _feedSnapshotCreatedAtMs ?? _resolveFeedSnapshotMs();
    if (_feedSnapshotCreatedAtMs == null) {
      setState(() => _feedSnapshotCreatedAtMs = snapshot);
    }
    if (latest.millisecondsSinceEpoch > snapshot && !_showNewPostsBanner) {
      setState(() => _showNewPostsBanner = true);
    }
  }

  Future<void> _showLatestCweets() async {
    await ref.read(cwitterFeedProvider.notifier).refresh();
    ref.invalidate(cwitterRecweetsProvider);
    if (!mounted) return;

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    markCwitterFeedSeen(ref);
    if (!mounted) return;
    setState(() {
      _showNewPostsBanner = false;
      _feedSnapshotCreatedAtMs = _resolveFeedSnapshotMs();
    });
  }

  void _onComposerFocusChange() {
    if (_isHandlingComposerBack) return;
    if (!_composerFocusNode.hasFocus) {
      _dismissComposerIfEmpty();
      _syncComposerBackGate();
    }
  }

  void _dismissComposerIfEmpty() {
    if (_isPosting) return;
    _composerFocusNode.unfocus();
    if (_composerController.text.trim().isEmpty &&
        _pendingImages.isEmpty &&
        !_pollEnabled) {
      setState(() => _composerExpanded = false);
      _syncComposerBackGate();
    }
  }

  void _clearPollOptions() {
    for (final controller in _pollOptionControllers) {
      controller.clear();
    }
    while (_pollOptionControllers.length > CwitterPoll.minOptions) {
      _pollOptionControllers.removeLast().dispose();
    }
    _pollEnabled = false;
  }

  void _togglePoll() {
    if (_isPosting) return;
    setState(() {
      if (_pollEnabled) {
        _clearPollOptions();
      } else {
        _pollEnabled = true;
        _pendingImages.clear();
        _composerExpanded = true;
      }
    });
  }

  void _addPollOption() {
    if (_pollOptionControllers.length >= CwitterPoll.maxOptions) return;
    setState(() {
      _pollOptionControllers.add(TextEditingController());
    });
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length <= CwitterPoll.minOptions) return;
    setState(() {
      _pollOptionControllers.removeAt(index).dispose();
    });
  }

  void _expandComposer() {
    if (_isPosting) return;
    setState(() => _composerExpanded = true);
    _syncComposerBackGate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _composerFocusNode.requestFocus();
        _syncComposerBackGate();
      }
    });
  }

  void _collapseComposer() {
    _composerFocusNode.unfocus();
    setState(() => _composerExpanded = false);
    _syncComposerBackGate();
  }

  void _resetComposer() {
    _composerController.clear();
    _pendingImages.clear();
    _clearPollOptions();
    _composerFocusNode.unfocus();
    setState(() => _composerExpanded = false);
    _syncComposerBackGate();
  }

  Future<void> _handleComposerBackPress() async {
    if (!_isComposerInputActive || _isPosting) return;

    _isHandlingComposerBack = true;
    try {
      _composerFocusNode.unfocus();

      if (_hasComposerDraft) {
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('途中入力を削除しますか？'),
            content: const Text('入力中の内容は保存されません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除する'),
              ),
            ],
          ),
        );
        if (discard != true || !mounted) {
          if (_composerExpanded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _composerFocusNode.requestFocus();
                _syncComposerBackGate();
              }
            });
          }
          return;
        }
        _resetComposer();
        return;
      }

      _collapseComposer();
    } finally {
      _isHandlingComposerBack = false;
      _syncComposerBackGate();
    }
  }

  @override
  void dispose() {
    ref.read(cwitterComposerBackGateProvider.notifier).clear();
    _scrollController.removeListener(_onFeedScroll);
    _scrollController.dispose();
    _composerFocusNode.removeListener(_onComposerFocusChange);
    _composerFocusNode.dispose();
    _composerController.dispose();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_pendingImages.length >= CwitterPostImageService.maxImagesPerPost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '画像は最大${CwitterPostImageService.maxImagesPerPost}枚までです',
          ),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (!mounted || picked.isEmpty) return;

    setState(() {
      final remaining =
          CwitterPostImageService.maxImagesPerPost - _pendingImages.length;
      _pendingImages.addAll(picked.take(remaining));
      _composerExpanded = true;
    });
  }

  Future<void> _onPostTap() async {
    final text = _composerController.text.trim();
    final pollOptions = _pollEnabled ? _filledPollOptions : const <String>[];
    if (text.isEmpty && _pendingImages.isEmpty && pollOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cweetする内容、画像、または投票を入力してください')),
      );
      return;
    }
    if (_pollEnabled && pollOptions.length < CwitterPoll.minOptions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '投票の選択肢は${CwitterPoll.minOptions}件以上入力してください',
          ),
        ),
      );
      return;
    }

    final appUser = ref.read(currentAppUserStreamProvider).valueOrNull;
    final uid = ref.read(currentUserIdProvider);
    if (appUser == null || uid == null || !appUser.hasCwitterId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cwitter IDを設定してください')),
      );
      return;
    }

    final confirmed = await CwitterPostingGuidelinesDialog.confirmIfNeeded(
      context,
      ref,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isPosting = true);
    try {
      await CwitterService.createPost(
        authorId: uid,
        authorEmail: appUser.email,
        cwitterId: appUser.cwitterId!,
        displayName: appUser.displayName,
        body: text,
        profileImageUrl: appUser.profileImageUrl,
        imageFiles: List<XFile>.from(_pendingImages),
        pollOptions: _pollEnabled ? pollOptions : null,
      );
      if (!mounted) return;
      _composerController.clear();
      setState(() {
        _pendingImages.clear();
        _clearPollOptions();
      });
      _collapseComposer();
      await ref.read(cwitterFeedProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _showNewPostsBanner = false;
        _feedSnapshotCreatedAtMs = _resolveFeedSnapshotMs();
      });
      markCwitterFeedSeen(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cweetしました'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final isRateLimited = e is CwitterPostRateLimitException;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: isRateLimited ? Colors.orange.shade800 : null,
          duration: Duration(seconds: isRateLimited ? 3 : 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cwitterTagsOverrideSyncProvider);

    if (widget.isActiveTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncComposerBackGate();
      });
    }

    final uid = ref.watch(currentUserIdProvider);
    ref.listen<AsyncValue<List<CwitterPost>>>(
      cwitterPostsProvider,
      (_, next) {
        next.whenData((posts) {
          ref
              .read(cwitterLikeOverrideProvider.notifier)
              .syncWithPosts(posts, uid);
          ref
              .read(cwitterRecweetOverrideProvider.notifier)
              .syncWithPosts(
                posts,
                uid,
                (postId) =>
                    ref
                        .read(
                          cwitterIsRecweetedProvider(
                            (userId: uid!, postId: postId),
                          ),
                        )
                        .valueOrNull ??
                    false,
              );
          ref
              .read(cwitterReplyCountOverrideProvider.notifier)
              .syncWithPosts(posts);
          if (_feedSnapshotCreatedAtMs == null && posts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _feedSnapshotCreatedAtMs = _resolveFeedSnapshotMs();
              });
            });
          }
        });
      },
    );

    ref.listen<AsyncValue<DateTime?>>(
      cwitterLatestPostCreatedAtProvider,
      (_, next) {
        next.whenData((_) => _checkForNewPostsWhileScrolled());
      },
    );

    final appUserAsync = ref.watch(currentAppUserStreamProvider);

    return appUserAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('読み込みに失敗しました: $error'),
        ),
      ),
      data: (appUser) {
        if (appUser == null || !appUser.hasCwitterId) {
          return const CwitterIdSetupView();
        }
        return BackButtonListener(
          onBackButtonPressed: () async {
            if (!widget.isActiveTab || !_isComposerInputActive) {
              return false;
            }
            await _handleComposerBackPress();
            return true;
          },
          child: _buildFeed(context, appUser),
        );
      },
    );
  }

  Widget _buildFeed(BuildContext context, AppUser appUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final followingIdsAsync = ref.watch(
      cwitterFollowingUserIdsProvider(appUser.uid),
    );

    if (_feedTab == CwitterFeedTab.everyone) {
      final postsAsync = ref.watch(filteredCwitterPostsProvider);
      return postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildFeedError(context, error),
        data: (posts) => _buildFeedList(
          context: context,
          appUser: appUser,
          theme: theme,
          colorScheme: colorScheme,
          followingIdsAsync: followingIdsAsync,
          isEmpty: posts.isEmpty,
          children: posts.map((post) => CwitterPostCard(post: post)).toList(),
        ),
      );
    }

    final itemsAsync = ref.watch(filteredFollowingFeedCwitterItemsProvider);
    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildFeedError(context, error),
      data: (items) => _buildFeedList(
        context: context,
        appUser: appUser,
        theme: theme,
        colorScheme: colorScheme,
        followingIdsAsync: followingIdsAsync,
        isEmpty: items.isEmpty,
        children: items
            .map(
              (item) => CwitterPostCard(
                post: item.post,
                recweet: item.recweet,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFeedError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cweetの取得に失敗しました: $error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await ref.read(cwitterFeedProvider.notifier).refresh();
                ref.invalidate(cwitterRecweetsProvider);
              },
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList({
    required BuildContext context,
    required AppUser appUser,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required AsyncValue<Set<String>> followingIdsAsync,
    required bool isEmpty,
    required List<Widget> children,
  }) {
    final feed = ref.watch(cwitterFeedProvider);
    final showLoadMore =
        _feedTab == CwitterFeedTab.everyone && feed.isLoadingMore;
    final feedChildren = interleaveWidgetListWithBannerAds(
      items: children,
      interval: InAppAdIntervals.cwitterFeed,
      ad: const InAppAdBannerSlot(placement: AdPlacement.cwitterFeed),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(cwitterFeedProvider.notifier).refresh();
        ref.invalidate(cwitterRecweetsProvider);
        ref.invalidate(filteredFollowingFeedCwitterItemsProvider);
        ref.invalidate(cwitterFollowingUserIdsProvider(appUser.uid));
        markCwitterFeedSeen(ref);
        if (mounted) {
          setState(() {
            _showNewPostsBanner = false;
            _feedSnapshotCreatedAtMs = _resolveFeedSnapshotMs();
            _composerPlaceholder =
                _pickComposerPlaceholder(current: _composerPlaceholder);
          });
        }
      },
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _isComposerExpanded
                      ? _buildExpandedComposer(context, appUser)
                      : _buildCollapsedComposer(context, appUser),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeedTabSelector(theme),
              const SizedBox(height: 12),
              if (isEmpty)
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.3,
                  child: Center(
                    child: Text(
                      _emptyFeedMessage(followingIdsAsync),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              else
                ...feedChildren,
              if (showLoadMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          if (_showNewPostsBanner)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: _NewCweetsBanner(onTap: _showLatestCweets),
              ),
            ),
        ],
      ),
    );
  }

  String _emptyFeedMessage(AsyncValue<Set<String>> followingIdsAsync) {
    if (_feedTab == CwitterFeedTab.everyone) {
      return 'まだCweetがありません\n最初のCweetをしてみましょう';
    }

    final followingCount = followingIdsAsync.valueOrNull?.length ?? 0;
    if (followingCount == 0) {
      return 'フォロー中のユーザーがいません\n気になる人をフォローしてみましょう';
    }
    return 'フォロー中のユーザーのCweetはまだありません';
  }

  Widget _buildFeedTabSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _FeedTabButton(
            label: 'フォロー中のCweet',
            selected: _feedTab == CwitterFeedTab.following,
            onTap: () {
              if (_feedTab == CwitterFeedTab.following) return;
              setState(() {
                _feedTab = CwitterFeedTab.following;
                _showNewPostsBanner = false;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FeedTabButton(
            label: 'みんなのCweet',
            selected: _feedTab == CwitterFeedTab.everyone,
            onTap: () {
              if (_feedTab == CwitterFeedTab.everyone) return;
              setState(() {
                _feedTab = CwitterFeedTab.everyone;
                _showNewPostsBanner = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedComposer(BuildContext context, AppUser appUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CwitterAvatar(
          authorId: appUser.uid,
          displayName: appUser.displayName,
          cwitterId: appUser.cwitterId,
          profileImageUrl: appUser.profileImageUrl,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _isPosting ? null : _expandComposer,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  _composerPlaceholder,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildCweetButton(compact: true),
      ],
    );
  }

  Widget _buildExpandedComposer(BuildContext context, AppUser appUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _dismissComposerIfEmpty,
          behavior: HitTestBehavior.opaque,
          child: CwitterAvatar(
            authorId: appUser.uid,
            displayName: appUser.displayName,
            cwitterId: appUser.cwitterId,
            profileImageUrl: appUser.profileImageUrl,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TapRegion(
                groupId: _composerTapGroup,
                onTapOutside: (_) => _dismissComposerIfEmpty(),
                child: TextField(
                  controller: _composerController,
                  focusNode: _composerFocusNode,
                  enableInteractiveSelection: true,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 280,
                  enabled: !_isPosting,
                  decoration: InputDecoration(
                    hintText: _composerPlaceholder,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              if (_pendingImages.isNotEmpty) ...[
                const SizedBox(height: 10),
                TapRegion(
                  groupId: _composerTapGroup,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CwitterPostImagesGrid(
                        imageUrls: const [],
                        localXFiles: _pendingImages,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _isPosting
                                ? null
                                : () => setState(_pendingImages.clear),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '画像をすべて削除',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_pollEnabled) ...[
                const SizedBox(height: 10),
                TapRegion(
                  groupId: _composerTapGroup,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _pollOptionControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _pollOptionControllers[i],
                                  enabled: !_isPosting,
                                  maxLength: CwitterPoll.maxOptionTextLength,
                                  decoration: InputDecoration(
                                    hintText: '選択肢 ${i + 1}',
                                    filled: true,
                                    fillColor: colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              if (_pollOptionControllers.length >
                                  CwitterPoll.minOptions)
                                IconButton(
                                  tooltip: '選択肢を削除',
                                  onPressed: _isPosting
                                      ? null
                                      : () => _removePollOption(i),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                            ],
                          ),
                        ),
                      if (_pollOptionControllers.length <
                          CwitterPoll.maxOptions)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _isPosting ? null : _addPollOption,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('選択肢を追加'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  TapRegion(
                    groupId: _composerTapGroup,
                    child: IconButton(
                      tooltip: '画像を追加（最大4枚）',
                      onPressed: _isPosting || _pollEnabled ? null : _pickImages,
                      icon: Icon(
                        Icons.image_outlined,
                        color: _pendingImages.length >=
                                CwitterPostImageService.maxImagesPerPost
                            ? colorScheme.onSurface.withValues(alpha: 0.35)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  TapRegion(
                    groupId: _composerTapGroup,
                    child: IconButton(
                      tooltip: '投票を追加（2〜4択）',
                      onPressed: _isPosting || _pendingImages.isNotEmpty
                          ? null
                          : _togglePoll,
                      icon: Icon(
                        Icons.poll_outlined,
                        color: _pollEnabled
                            ? const Color(0xFF2E7D32)
                            : colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  if (_pendingImages.isNotEmpty)
                    Text(
                      '${_pendingImages.length}/${CwitterPostImageService.maxImagesPerPost}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  const Spacer(),
                  TapRegion(
                    groupId: _composerTapGroup,
                    child: _buildCweetButton(compact: false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCweetButton({required bool compact}) {
    return FilledButton.icon(
      onPressed: _isPosting ? null : _onPostTap,
      icon: _isPosting
          ? SizedBox(
              width: compact ? 16 : 18,
              height: compact ? 16 : 18,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(Icons.send, size: compact ? 16 : 18),
      label: const Text('Cweet'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: compact ? 8 : 10,
        ),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
    );
  }
}

class _NewCweetsBanner extends StatelessWidget {
  const _NewCweetsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: const Color(0xFF4CAF50),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                '最新のCweetを見る',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTabButton extends StatelessWidget {
  const _FeedTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? const Color(0xFF4CAF50).withValues(alpha: 0.14)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4CAF50)
                  : colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? const Color(0xFF2E7D32)
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
