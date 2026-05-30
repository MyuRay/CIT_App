import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/cwitter_follow_counts_override_provider.dart';
import '../../../core/providers/cwitter_like_override_provider.dart';
import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../core/providers/user_block_provider.dart';
import '../../../models/community/cwitter_follow_counts.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../models/community/cwitter_profile_activity.dart';
import '../../../models/community/cwitter_profile_user.dart';
import '../../../models/user/user_model.dart';
import 'cwitter_activity_card.dart';
import 'cwitter_author_name_row.dart';
import 'cwitter_avatar.dart';
import 'cwitter_post_card.dart';
import '../../../services/community/cwitter_service.dart';
import '../../../screens/user_block/block_confirmation_dialog.dart';
import 'cwitter_profile_setup_dialog.dart';
import 'cwitter_social_links_section.dart';
import 'cwitter_follow_list_screen.dart';
import 'cwitter_handle_text.dart';
import '../../../models/community/cwitter_follow_user.dart';
import 'cwitter_follow_feedback.dart';
import 'cwitter_more_menu.dart';
import 'cwitter_report_helper.dart';

/// ユーザーの投稿一覧（自分は「いいね」タブあり）
class CwitterProfileScreen extends ConsumerStatefulWidget {
  const CwitterProfileScreen({
    super.key,
    this.user,
    this.showInitialProfileSetup = false,
  });

  /// null のときはログインユーザーのマイページ
  final CwitterProfileUser? user;

  /// Cwitter ID 初回設定後にプロフィール設定ダイアログを表示する
  final bool showInitialProfileSetup;

  @override
  ConsumerState<CwitterProfileScreen> createState() =>
      _CwitterProfileScreenState();
}

class _CwitterProfileScreenState extends ConsumerState<CwitterProfileScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _initialSetupShown = false;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _maybeShowInitialProfileSetup(String uid) {
    if (!widget.showInitialProfileSetup || _initialSetupShown) return;
    _initialSetupShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await CwitterProfileSetupDialog.show(context, uid: uid);
    });
  }

  void _syncTabController(bool showLikesTab) {
    final length = showLikesTab ? 2 : 1;
    if (_tabController != null && _tabController!.length == length) return;
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
  }

  void _syncLikeOverrides(List<CwitterPost> posts) {
    final uid = ref.read(currentUserIdProvider);
    ref.read(cwitterLikeOverrideProvider.notifier).syncWithPosts(posts, uid);
  }

  void _syncLikeOverridesFromActivities(List<CwitterProfileActivity> activities) {
    final posts = <CwitterPost>[];
    for (final activity in activities) {
      if (activity.post != null) {
        posts.add(activity.post!);
      }
    }
    _syncLikeOverrides(posts);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUid = ref.watch(currentUserIdProvider);
    final appUser = ref.watch(currentAppUserStreamProvider).valueOrNull;

    final isMyPage = widget.user == null;
    if (isMyPage && (appUser == null || !appUser.hasCwitterId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('マイページ')),
        body: const Center(child: Text('Cwitter IDを設定してください')),
      );
    }

    final profileUser = _resolveProfileUser(widget.user, appUser, currentUid);
    if (profileUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: const Center(child: Text('ユーザー情報を取得できません')),
      );
    }

    final resolvedProfileName = resolveAuthorDisplayName(
      ref.watch(
        authorDisplayNameProvider(
          (authorId: profileUser.authorId, fallback: profileUser.displayName),
        ),
      ),
      profileUser.displayName,
    );

    final isSelf = currentUid != null && currentUid == profileUser.authorId;
    if (isSelf && widget.showInitialProfileSetup) {
      _maybeShowInitialProfileSetup(profileUser.authorId);
    }
    final showLikesTab = isSelf;
    _syncTabController(showLikesTab);

    final activityProvider =
        filteredCwitterUserActivityProvider(profileUser.authorId);

    ref.listen<AsyncValue<List<CwitterProfileActivity>>>(activityProvider, (
      _,
      next,
    ) {
      next.whenData(_syncLikeOverridesFromActivities);
    });
    if (showLikesTab) {
      ref.listen<AsyncValue<List<CwitterPost>>>(filteredLikedCwitterPostsProvider, (
        _,
        next,
      ) {
        next.whenData(_syncLikeOverrides);
      });
    }

    final appBarTitle = isMyPage && isSelf
        ? 'マイページ'
        : resolvedProfileName;

    final blockedUsers = ref.watch(blockedUsersProvider).valueOrNull ?? [];
    final blockedByMe = blockedUsers.any(
      (user) => user.blockedUserId == profileUser.authorId,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (!isSelf && currentUid != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CwitterMoreMenu(
                isOwner: false,
                iconSize: 24,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onReport: () => showCwitterUserReportDialog(
                  context,
                  authorId: profileUser.authorId,
                  displayName: profileUser.displayName,
                  cwitterId: profileUser.cwitterId,
                ),
                onBlock: blockedByMe
                    ? null
                    : () async {
                        final blocked = await showBlockConfirmationDialog(
                          context,
                          blockedUserId: profileUser.authorId,
                          blockedUserName: profileUser.displayName,
                          blockedUserCwitterId: profileUser.cwitterId,
                        );
                        if (blocked == true && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                profileUser: profileUser,
                isSelf: isSelf,
                currentUid: currentUid,
              ),
            ),
            if (showLikesTab)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF4CAF50),
                    labelColor: const Color(0xFF2E7D32),
                    unselectedLabelColor:
                        colorScheme.onSurface.withValues(alpha: 0.6),
                    tabs: const [
                      Tab(text: 'Cweet'),
                      Tab(text: 'いいね'),
                    ],
                  ),
                  backgroundColor: colorScheme.surface,
                ),
              ),
          ];
        },
        body: showLikesTab
            ? TabBarView(
                controller: _tabController,
                children: [
                  _ActivityTab(
                    provider: activityProvider,
                    emptyMessage: 'まだCweet・返信・recweetがありません',
                    onRefresh: () async {
                      ref.invalidate(cwitterUserActivityProvider(profileUser.authorId));
                      ref.invalidate(filteredCwitterUserActivityProvider(profileUser.authorId));
                      await ref.read(cwitterUserActivityProvider(profileUser.authorId).future);
                    },
                  ),
                  _PostsTab(
                    provider: filteredLikedCwitterPostsProvider,
                    emptyMessage: 'いいねしたCweetはありません',
                    onRefresh: () async {
                      ref.invalidate(likedCwitterPostsProvider);
                      ref.invalidate(filteredLikedCwitterPostsProvider);
                      await ref.read(likedCwitterPostsProvider.future);
                    },
                  ),
                ],
              )
            : _ActivityTab(
                provider: activityProvider,
                emptyMessage: 'まだCweet・返信・recweetがありません',
                onRefresh: () async {
                  ref.invalidate(
                    cwitterUserActivityProvider(profileUser.authorId),
                  );
                  ref.invalidate(
                    filteredCwitterUserActivityProvider(profileUser.authorId),
                  );
                  await ref.read(
                    cwitterUserActivityProvider(profileUser.authorId).future,
                  );
                },
              ),
      ),
    );
  }

  CwitterProfileUser? _resolveProfileUser(
    CwitterProfileUser? fromArgs,
    AppUser? appUser,
    String? currentUid,
  ) {
    if (fromArgs != null) return fromArgs;
    if (appUser == null || currentUid == null || !appUser.hasCwitterId) {
      return null;
    }
    return CwitterProfileUser(
      authorId: currentUid,
      displayName: appUser.displayName,
      cwitterId: appUser.cwitterId!,
      profileImageUrl: appUser.profileImageUrl,
      bio: appUser.cwitterBio,
      tags: appUser.cwitterTags,
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SliverTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.profileUser,
    required this.isSelf,
    required this.currentUid,
  });

  final CwitterProfileUser profileUser;
  final bool isSelf;
  final String? currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countsAsync = ref.watch(cwitterFollowCountsProvider(profileUser.authorId));
    final cweetCountsAsync =
        ref.watch(cwitterUserCweetCountsProvider(profileUser.authorId));
    final countsOverride =
        ref.watch(cwitterFollowCountsOverrideProvider)[profileUser.authorId];

    ref.listen<AsyncValue<CwitterFollowCounts>>(
      cwitterFollowCountsProvider(profileUser.authorId),
      (_, next) {
        next.whenData((counts) {
          ref
              .read(cwitterFollowCountsOverrideProvider.notifier)
              .syncWithCounts(profileUser.authorId, counts);
        });
      },
    );

    final hiddenUserIds = ref.watch(hiddenUserIdsProvider).valueOrNull ?? {};
    final tags = ref.watch(cwitterUserTagsProvider(profileUser.authorId)).valueOrNull ??
        profileUser.tags;
    final resolvedName = resolveAuthorDisplayName(
      ref.watch(
        authorDisplayNameProvider(
          (authorId: profileUser.authorId, fallback: profileUser.displayName),
        ),
      ),
      profileUser.displayName,
    );
    final isHidden = hiddenUserIds.contains(profileUser.authorId);
    final showFollowButton = !isSelf &&
        currentUid != null &&
        ref.watch(hasCwitterIdProvider) &&
        !isHidden;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CwitterAvatar(
                    authorId: profileUser.authorId,
                    displayName: resolvedName,
                    cwitterId: profileUser.cwitterId,
                    profileImageUrl: profileUser.profileImageUrl,
                    radius: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CwitterAuthorNameRow(
                          displayName: resolvedName,
                          cwitterId: profileUser.cwitterId,
                          tags: tags,
                          nameStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CwitterHandleText(
                          cwitterId: profileUser.cwitterId,
                          showOfficialTag: false,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProfileTagsSection(
                authorId: profileUser.authorId,
                initialTags: profileUser.tags,
                isSelf: isSelf,
              ),
              const SizedBox(height: 12),
              _ProfileBioSection(
                authorId: profileUser.authorId,
                initialBio: profileUser.bio,
                isSelf: isSelf,
              ),
              const SizedBox(height: 12),
              CwitterSocialLinksSection(
                authorId: profileUser.authorId,
                isSelf: isSelf,
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final isLoading =
                      countsAsync.isLoading || cweetCountsAsync.isLoading;
                  if (isLoading) {
                    return Text(
                      '読み込み中…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    );
                  }

                  if (countsAsync.hasError && cweetCountsAsync.hasError) {
                    return Text(
                      'プロフィール情報を取得できません',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    );
                  }

                  final displayCounts = resolveCwitterFollowCounts(
                    server: countsAsync.valueOrNull ??
                        const CwitterFollowCounts(),
                    override: countsOverride,
                  );
                  final cweetCount =
                      cweetCountsAsync.valueOrNull?.totalCount ?? 0;

                  return Row(
                    children: [
                      _FollowCountLabel(
                        count: cweetCount,
                        label: 'Cweet',
                      ),
                      const SizedBox(width: 20),
                      _FollowCountLabel(
                        count: displayCounts.followingCount,
                        label: 'フォロー中',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CwitterFollowListScreen(
                                userId: profileUser.authorId,
                                userDisplayName: profileUser.displayName,
                                kind: CwitterFollowListKind.following,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      _FollowCountLabel(
                        count: displayCounts.followerCount,
                        label: 'フォロワー',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CwitterFollowListScreen(
                                userId: profileUser.authorId,
                                userDisplayName: profileUser.displayName,
                                kind: CwitterFollowListKind.followers,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              if (showFollowButton) ...[
                const SizedBox(height: 12),
                _FollowButton(
                  followerId: currentUid!,
                  followeeId: profileUser.authorId,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTagsSection extends ConsumerStatefulWidget {
  const _ProfileTagsSection({
    required this.authorId,
    required this.isSelf,
    this.initialTags = const [],
  });

  final String authorId;
  final bool isSelf;
  final List<String> initialTags;

  @override
  ConsumerState<_ProfileTagsSection> createState() =>
      _ProfileTagsSectionState();
}

class _ProfileTagsSectionState extends ConsumerState<_ProfileTagsSection> {
  bool _isSaving = false;

  Future<void> _showTagsEditor(List<String> currentTags) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return _CwitterTagsEditorDialog(currentTags: currentTags);
      },
    );

    if (result == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await CwitterService.updateCwitterTags(
        uid: widget.authorId,
        tags: result,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ハッシュタグを保存しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.65);
    final tagsAsync = ref.watch(cwitterUserTagsProvider(widget.authorId));
    final tags = tagsAsync.valueOrNull ?? widget.initialTags;

    if (!widget.isSelf) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _isSaving ? null : () => _showTagsEditor(tags),
        icon: _isSaving
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.sell_outlined, size: 16, color: mutedColor),
        label: Text(
          tags.isEmpty ? 'ハッシュタグを追加' : 'ハッシュタグを編集',
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _CwitterTagsEditorDialog extends StatefulWidget {
  const _CwitterTagsEditorDialog({required this.currentTags});

  final List<String> currentTags;

  @override
  State<_CwitterTagsEditorDialog> createState() =>
      _CwitterTagsEditorDialogState();
}

class _CwitterTagsEditorDialogState extends State<_CwitterTagsEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tag1Controller;
  late final TextEditingController _tag2Controller;

  @override
  void initState() {
    super.initState();
    _tag1Controller = TextEditingController(
      text: widget.currentTags.isNotEmpty ? widget.currentTags[0] : '',
    );
    _tag2Controller = TextEditingController(
      text: widget.currentTags.length > 1 ? widget.currentTags[1] : '',
    );
  }

  @override
  void dispose() {
    _tag1Controller.dispose();
    _tag2Controller.dispose();
    super.dispose();
  }

  String? _validateTagField(String? value, {bool optional = false}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return optional ? null : '1つ目のハッシュタグを入力してください';
    }
    final normalized = trimmed.startsWith('#')
        ? trimmed.substring(1).trim()
        : trimmed;
    if (!AppConstants.isValidCwitterTag(normalized)) {
      return AppConstants.errorCwitterTagFormat;
    }
    return null;
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop([
      _tag1Controller.text,
      _tag2Controller.text,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ハッシュタグを編集'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tag1Controller,
              decoration: const InputDecoration(
                labelText: 'ハッシュタグ 1',
                hintText: '例: 27卒',
                helperText: AppConstants.cwitterTagsInputHelper,
                border: OutlineInputBorder(),
                prefixText: '#',
              ),
              validator: (value) => _validateTagField(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tag2Controller,
              decoration: const InputDecoration(
                labelText: 'ハッシュタグ 2（任意）',
                hintText: '例: 建築',
                border: OutlineInputBorder(),
                prefixText: '#',
              ),
              validator: (value) => _validateTagField(value, optional: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _ProfileBioSection extends ConsumerStatefulWidget {
  const _ProfileBioSection({
    required this.authorId,
    required this.isSelf,
    this.initialBio,
  });

  final String authorId;
  final bool isSelf;
  final String? initialBio;

  @override
  ConsumerState<_ProfileBioSection> createState() => _ProfileBioSectionState();
}

class _ProfileBioSectionState extends ConsumerState<_ProfileBioSection> {
  bool _isSaving = false;
  bool _bioExpanded = false;
  static const _collapsedMaxLines = 3;

  @override
  void didUpdateWidget(covariant _ProfileBioSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorId != widget.authorId ||
        oldWidget.initialBio != widget.initialBio) {
      _bioExpanded = false;
    }
  }

  bool _textExceedsLineLimit(
    String text,
    TextStyle style,
    double maxWidth,
    int maxLines,
  ) {
    if (maxWidth <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  Future<void> _showBioEditor(String? currentBio) async {
    final controller = TextEditingController(text: currentBio ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('自己紹介を編集'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              maxLines: 4,
              minLines: 3,
              maxLength: AppConstants.cwitterBioMaxLength,
              decoration: const InputDecoration(
                hintText: '自己紹介を入力してください',
                helperText: AppConstants.cwitterBioInputHelper,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final length = (value ?? '').trim().length;
                if (length > AppConstants.cwitterBioMaxLength) {
                  return '${AppConstants.cwitterBioMaxLength}文字以内で入力してください';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await CwitterService.updateCwitterBio(
        uid: widget.authorId,
        bio: controller.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自己紹介を保存しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      controller.dispose();
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.65);
    final bioAsync = ref.watch(cwitterUserBioProvider(widget.authorId));
    final bio = bioAsync.valueOrNull ?? widget.initialBio;

    if (!widget.isSelf && (bio == null || bio.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (widget.isSelf && (bio == null || bio.isEmpty)) {
      return OutlinedButton.icon(
        onPressed: _isSaving ? null : () => _showBioEditor(bio),
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.edit_outlined, size: 18),
        label: const Text('自己紹介を追加'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E7D32),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          alignment: Alignment.centerLeft,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bioStyle = theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.85),
          height: 1.45,
        );
        final canExpand = bioStyle != null &&
            _textExceedsLineLimit(
              bio!,
              bioStyle,
              constraints.maxWidth,
              _collapsedMaxLines,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              bio!,
              style: bioStyle,
              maxLines: _bioExpanded ? null : _collapsedMaxLines,
              overflow: _bioExpanded ? null : TextOverflow.ellipsis,
            ),
            if (canExpand) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _bioExpanded = !_bioExpanded),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _bioExpanded ? '折りたたむ' : '続きを読む',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (widget.isSelf) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isSaving ? null : () => _showBioEditor(bio),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.edit_outlined, size: 16, color: mutedColor),
                  label: Text(
                    '自己紹介を編集',
                    style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FollowCountLabel extends StatelessWidget {
  const _FollowCountLabel({
    required this.count,
    required this.label,
    this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    final content = RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
        children: [
          TextSpan(
            text: '$count',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: content,
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({
    required this.followerId,
    required this.followeeId,
  });

  final String followerId;
  final String followeeId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isUpdating = false;
  bool? _optimisticFollowing;

  ({String followerId, String followeeId}) get _followTarget => (
        followerId: widget.followerId,
        followeeId: widget.followeeId,
      );

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    if (_isUpdating) return;

    final targetFollowing = !currentlyFollowing;
    final countsNotifier =
        ref.read(cwitterFollowCountsOverrideProvider.notifier);
    final delta = targetFollowing ? 1 : -1;

    final followeeAsync = ref.read(cwitterFollowCountsProvider(widget.followeeId));
    final followerAsync = ref.read(cwitterFollowCountsProvider(widget.followerId));

    if (followeeAsync.hasValue && followerAsync.hasValue) {
      final followeeCounts = followeeAsync.requireValue;
      final followerCounts = followerAsync.requireValue;
      final followeeOverride =
          ref.read(cwitterFollowCountsOverrideProvider)[widget.followeeId];
      final followerOverride =
          ref.read(cwitterFollowCountsOverrideProvider)[widget.followerId];

      final followeeBase = resolveCwitterFollowCounts(
        server: followeeCounts,
        override: followeeOverride,
      );
      final followerBase = resolveCwitterFollowCounts(
        server: followerCounts,
        override: followerOverride,
      );

      countsNotifier.apply(
        userId: widget.followeeId,
        followerCount: followeeBase.followerCount + delta < 0
            ? 0
            : followeeBase.followerCount + delta,
      );
      countsNotifier.apply(
        userId: widget.followerId,
        followingCount: followerBase.followingCount + delta < 0
            ? 0
            : followerBase.followingCount + delta,
      );
    }

    setState(() {
      _isUpdating = true;
      _optimisticFollowing = targetFollowing;
    });

    try {
      if (currentlyFollowing) {
        await CwitterService.unfollowUser(
          followerId: widget.followerId,
          followeeId: widget.followeeId,
        );
      } else {
        await CwitterService.followUser(
          followerId: widget.followerId,
          followeeId: widget.followeeId,
        );
      }
    } catch (e) {
      countsNotifier.revertPair(widget.followeeId, widget.followerId);
      if (!mounted) return;
      setState(() => _optimisticFollowing = currentlyFollowing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cwitterFollowActionErrorMessage(
              e,
              unfollow: currentlyFollowing,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowingAsync = ref.watch(
      cwitterIsFollowingProvider(_followTarget),
    );

    ref.listen<AsyncValue<bool>>(
      cwitterIsFollowingProvider(_followTarget),
      (previous, next) {
        next.whenData((streamValue) {
          if (!mounted || _optimisticFollowing == null || _isUpdating) return;
          if (streamValue == _optimisticFollowing) {
            setState(() => _optimisticFollowing = null);
          }
        });
      },
    );

    return isFollowingAsync.when(
      loading: () => const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (streamFollowing) {
        final isFollowing = _optimisticFollowing ?? streamFollowing;
        final mutedColor =
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);

        if (isFollowing) {
          return OutlinedButton(
            onPressed: _isUpdating ? null : () => _toggleFollow(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: mutedColor,
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('フォロー中'),
          );
        }

        return FilledButton(
          onPressed: _isUpdating ? null : () => _toggleFollow(false),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: const Text('フォローする'),
        );
      },
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({
    required this.provider,
    required this.emptyMessage,
    required this.onRefresh,
  });

  final ProviderListenable<AsyncValue<List<CwitterProfileActivity>>> provider;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityAsync = ref.watch(provider);

    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('読み込みに失敗しました: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.25,
                  child: Center(
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: activities.length,
            itemBuilder: (context, index) =>
                CwitterActivityCard(activity: activities[index]),
          ),
        );
      },
    );
  }
}

class _PostsTab extends ConsumerWidget {
  const _PostsTab({
    required this.provider,
    required this.emptyMessage,
    required this.onRefresh,
  });

  final ProviderListenable<AsyncValue<List<CwitterPost>>> provider;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final postsAsync = ref.watch(provider);

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('読み込みに失敗しました: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.25,
                  child: Center(
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: posts.length,
            itemBuilder: (context, index) =>
                CwitterPostCard(post: posts[index]),
          ),
        );
      },
    );
  }
}
