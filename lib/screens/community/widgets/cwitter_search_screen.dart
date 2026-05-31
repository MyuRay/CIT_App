import 'dart:async';



import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';



import '../../../core/providers/schedule_provider.dart';

import '../../../core/providers/cwitter_provider.dart';

import '../../../core/providers/user_block_provider.dart';

import '../../../models/community/cwitter_follow_user.dart';

import '../../../models/community/cwitter_hashtag_summary.dart';

import '../../../models/community/cwitter_post.dart';

import '../../../services/community/cwitter_service.dart';

import '../../../services/users/content_filter_service.dart';

import 'cwitter_avatar.dart';

import 'cwitter_handle_text.dart';

import 'cwitter_follow_button.dart';
import 'cwitter_hashtag_users_screen.dart';
import 'cwitter_post_card.dart';

import 'cwitter_profile_screen.dart';

import 'cwitter_tags_row.dart';



/// Cweet 本文・Cwitter ID・ハッシュタグの検索

class CwitterSearchScreen extends ConsumerStatefulWidget {

  const CwitterSearchScreen({super.key});



  @override

  ConsumerState<CwitterSearchScreen> createState() =>

      _CwitterSearchScreenState();

}



class _CwitterSearchScreenState extends ConsumerState<CwitterSearchScreen>

    with SingleTickerProviderStateMixin {

  final _searchController = TextEditingController();

  final _searchFocusNode = FocusNode();

  late final TabController _tabController;

  Timer? _debounce;



  bool _isSearching = false;

  String? _errorMessage;

  List<CwitterPost> _postResults = const [];

  List<CwitterFollowUser> _userResults = const [];

  List<CwitterFollowUser> _tagUserResults = const [];



  @override

  void initState() {

    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _searchController.addListener(_onQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {

      _searchFocusNode.requestFocus();

    });

  }



  @override

  void dispose() {

    _debounce?.cancel();

    _searchController.dispose();

    _searchFocusNode.dispose();

    _tabController.dispose();

    super.dispose();

  }



  void _onQueryChanged() {

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);

  }



  Future<void> _runSearch() async {

    final query = _searchController.text.trim();

    if (query.isEmpty) {

      if (!mounted) return;

      setState(() {

        _isSearching = false;

        _errorMessage = null;

        _postResults = const [];

        _userResults = const [];

        _tagUserResults = const [];

      });

      return;

    }



    setState(() {

      _isSearching = true;

      _errorMessage = null;

    });



    try {

      final hiddenUserIds =

          ref.read(hiddenUserIdsProvider).valueOrNull ?? const {};

      final posts = ContentFilterService.filterCwitterPosts(

        await CwitterService.searchPosts(query),

        hiddenUserIds,

      );

      final users = (await CwitterService.searchUsersByCwitterId(query))

          .where((user) => !hiddenUserIds.contains(user.authorId))

          .toList();

      final tagUsers = (await CwitterService.searchUsersByHashtag(query))

          .where((user) => !hiddenUserIds.contains(user.authorId))

          .toList();



      if (!mounted) return;

      setState(() {

        _postResults = posts;

        _userResults = users;

        _tagUserResults = tagUsers;

        _isSearching = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _isSearching = false;

        _errorMessage = '$e';

      });

    }

  }



  void _openHashtagUsers(String tag) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CwitterHashtagUsersScreen(tag: tag),
      ),
    );
  }



  List<CwitterHashtagSummary> _filteredHashtags(
    List<CwitterHashtagSummary> registeredHashtags,
    String query,
  ) {

    final needle = query.trim().toLowerCase().replaceFirst(RegExp(r'^#'), '');

    if (needle.isEmpty) return registeredHashtags;

    return registeredHashtags

        .where((summary) => summary.tag.toLowerCase().contains(needle))

        .toList();

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final query = _searchController.text.trim();



    return Scaffold(

      appBar: AppBar(

        title: TextField(

          controller: _searchController,

          focusNode: _searchFocusNode,

          textInputAction: TextInputAction.search,

          decoration: InputDecoration(

            hintText: 'キーワード・@ID・#タグ（部分一致）',

            border: InputBorder.none,

            hintStyle: theme.textTheme.titleMedium?.copyWith(

              color: colorScheme.onSurface.withValues(alpha: 0.45),

              fontWeight: FontWeight.normal,

            ),

            suffixIcon: query.isNotEmpty

                ? IconButton(

                    icon: const Icon(Icons.clear),

                    onPressed: () {

                      _searchController.clear();

                      _runSearch();

                    },

                  )

                : null,

          ),

          style: theme.textTheme.titleMedium,

          onSubmitted: (_) => _runSearch(),

        ),

        bottom: TabBar(

          controller: _tabController,

          indicatorColor: const Color(0xFF4CAF50),

          labelColor: const Color(0xFF2E7D32),

          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),

          tabs: const [

            Tab(text: 'Cweet'),

            Tab(text: 'ID'),

            Tab(text: 'タグ'),

          ],

        ),

      ),

      body: TabBarView(

        controller: _tabController,

        children: [

          _buildPostResults(theme, colorScheme, query),

          _buildUserResults(theme, colorScheme, query),

          _buildHashtagResults(theme, colorScheme, query),

        ],

      ),

    );

  }



  Widget _buildPostResults(

    ThemeData theme,

    ColorScheme colorScheme,

    String query,

  ) {

    if (query.isEmpty) {

      return _buildHint(

        theme,

        colorScheme,

        'キーワードを入力して Cweet を検索\n（本文・名前・ID、部分一致）',

      );

    }

    if (_isSearching) {

      return const Center(child: CircularProgressIndicator());

    }

    if (_errorMessage != null) {

      return Center(

        child: Padding(

          padding: const EdgeInsets.all(24),

          child: Text('検索に失敗しました: $_errorMessage'),

        ),

      );

    }

    if (_postResults.isEmpty) {

      return _buildHint(theme, colorScheme, '該当する Cweet は見つかりませんでした');

    }



    return ListView.separated(

      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

      itemCount: _postResults.length,

      separatorBuilder: (_, __) => const SizedBox(height: 12),

      itemBuilder: (context, index) {

        return CwitterPostCard(post: _postResults[index]);

      },

    );

  }



  Widget _buildUserResults(

    ThemeData theme,

    ColorScheme colorScheme,

    String query,

  ) {

    if (query.isEmpty) {

      return _buildHint(

        theme,

        colorScheme,

        '@ または ID の一部を入力（部分一致）',

      );

    }

    if (_isSearching) {

      return const Center(child: CircularProgressIndicator());

    }

    if (_errorMessage != null) {

      return Center(

        child: Padding(

          padding: const EdgeInsets.all(24),

          child: Text('検索に失敗しました: $_errorMessage'),

        ),

      );

    }

    if (_userResults.isEmpty) {

      return _buildHint(theme, colorScheme, '該当するユーザーは見つかりませんでした');

    }



    final currentUid = ref.watch(currentUserIdProvider);



    return ListView.separated(

      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

      itemCount: _userResults.length,

      separatorBuilder: (_, __) => const SizedBox(height: 8),

      itemBuilder: (context, index) {

        return _SearchUserTile(

          user: _userResults[index],

          currentUid: currentUid,

        );

      },

    );

  }



  Widget _buildHashtagResults(

    ThemeData theme,

    ColorScheme colorScheme,

    String query,

  ) {

    final hashtagsAsync = ref.watch(cwitterRegisteredHashtagsProvider);



    return hashtagsAsync.when(

      loading: () => const Center(child: CircularProgressIndicator()),

      error: (error, _) => Center(

        child: Padding(

          padding: const EdgeInsets.all(24),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text('ハッシュタグ一覧の取得に失敗しました: $error'),

              const SizedBox(height: 12),

              FilledButton(

                onPressed: () {

                  ref.invalidate(cwitterRegisteredHashtagsProvider);

                },

                child: const Text('再読み込み'),

              ),

            ],

          ),

        ),

      ),

      data: (registeredHashtags) => _buildHashtagResultsBody(

        theme,

        colorScheme,

        query,

        registeredHashtags,

      ),

    );

  }



  Widget _buildHashtagResultsBody(

    ThemeData theme,

    ColorScheme colorScheme,

    String query,

    List<CwitterHashtagSummary> registeredHashtags,

  ) {

    final filteredTags = _filteredHashtags(registeredHashtags, query);

    final showUserResults = query.isNotEmpty;



    if (!showUserResults && registeredHashtags.isEmpty) {

      return _buildHint(

        theme,

        colorScheme,

        'まだ登録されているハッシュタグはありません\nプロフィールからタグを設定できます',

      );

    }



    if (showUserResults && _isSearching) {

      return const Center(child: CircularProgressIndicator());

    }



    if (showUserResults && _errorMessage != null) {

      return Center(

        child: Padding(

          padding: const EdgeInsets.all(24),

          child: Text('検索に失敗しました: $_errorMessage'),

        ),

      );

    }



    final currentUid = ref.watch(currentUserIdProvider);



    return ListView(

      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

      children: [

        if (filteredTags.isNotEmpty) ...[

          Text(

            showUserResults ? '一致するタグ' : '登録されているハッシュタグ',

            style: theme.textTheme.titleSmall?.copyWith(

              fontWeight: FontWeight.bold,

              color: colorScheme.onSurface.withValues(alpha: 0.75),

            ),

          ),

          const SizedBox(height: 10),

          Wrap(

            spacing: 8,

            runSpacing: 8,

            children: filteredTags

                .map(

                  (summary) => _HashtagChip(

                    summary: summary,

                    onTap: () => _openHashtagUsers(summary.tag),

                  ),

                )

                .toList(),

          ),

          const SizedBox(height: 20),

        ] else if (showUserResults) ...[

          Text(

            '一致するタグは見つかりませんでした',

            style: theme.textTheme.bodyMedium?.copyWith(

              color: colorScheme.onSurface.withValues(alpha: 0.6),

            ),

          ),

          const SizedBox(height: 20),

        ],

        if (showUserResults) ...[

          Text(

            '該当ユーザー',

            style: theme.textTheme.titleSmall?.copyWith(

              fontWeight: FontWeight.bold,

              color: colorScheme.onSurface.withValues(alpha: 0.75),

            ),

          ),

          const SizedBox(height: 10),

          if (_tagUserResults.isEmpty)

            Text(

              '該当するユーザーは見つかりませんでした',

              style: theme.textTheme.bodyMedium?.copyWith(

                color: colorScheme.onSurface.withValues(alpha: 0.6),

              ),

            )

          else

            ..._tagUserResults.map(

              (user) => Padding(

                padding: const EdgeInsets.only(bottom: 8),

                child: _SearchUserTile(

                  user: user,

                  currentUid: currentUid,

                  showTags: true,

                  showFollowButton: true,

                ),

              ),

            ),

        ] else ...[

          Text(

            'タグをタップするとユーザー一覧が表示されます',

            style: theme.textTheme.bodySmall?.copyWith(

              color: colorScheme.onSurface.withValues(alpha: 0.55),

            ),

          ),

        ],

      ],

    );

  }



  Widget _buildHint(

    ThemeData theme,

    ColorScheme colorScheme,

    String message,

  ) {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(24),

        child: Text(

          message,

          textAlign: TextAlign.center,

          style: theme.textTheme.bodyMedium?.copyWith(

            color: colorScheme.onSurface.withValues(alpha: 0.6),

          ),

        ),

      ),

    );

  }

}



class _HashtagChip extends StatelessWidget {

  const _HashtagChip({

    required this.summary,

    required this.onTap,

  });



  final CwitterHashtagSummary summary;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final textColor =

        isDark ? const Color(0xFF9AE6A0) : const Color(0xFF2E7D32);

    final backgroundColor = isDark

        ? textColor.withValues(alpha: 0.22)

        : const Color(0xFF4CAF50).withValues(alpha: 0.12);

    final borderColor = isDark

        ? textColor.withValues(alpha: 0.55)

        : const Color(0xFF4CAF50).withValues(alpha: 0.28);



    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(999),

        child: Container(

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

          decoration: BoxDecoration(

            color: backgroundColor,

            borderRadius: BorderRadius.circular(999),

            border: Border.all(color: borderColor),

          ),

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(

                '#${summary.tag}',

                style: theme.textTheme.labelLarge?.copyWith(

                  color: textColor,

                  fontWeight: FontWeight.w600,

                ),

              ),

              const SizedBox(width: 6),

              Text(

                '${summary.userCount}',

                style: theme.textTheme.labelSmall?.copyWith(

                  color: textColor.withValues(alpha: 0.75),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _SearchUserTile extends ConsumerWidget {
  const _SearchUserTile({
    required this.user,
    required this.currentUid,
    this.showTags = false,
    this.showFollowButton = false,
  });

  final CwitterFollowUser user;
  final String? currentUid;
  final bool showTags;
  final bool showFollowButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelf = currentUid != null && currentUid == user.authorId;
    final canFollow = showFollowButton && !isSelf && currentUid != null;
    final tags =
        ref.watch(cwitterUserTagsProvider(user.authorId)).valueOrNull ??
            user.tags;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelf) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CwitterProfileScreen(),
              ),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CwitterProfileScreen(user: user.toProfileUser()),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CwitterAvatar(
                authorId: user.authorId,
                displayName: user.displayName,
                cwitterId: user.cwitterId,
                profileImageUrl: user.profileImageUrl,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CwitterHandleText(
                      cwitterId: user.cwitterId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    if (showTags && tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      CwitterTagsRow(tags: tags, compact: true),
                    ],
                  ],
                ),
              ),
              if (canFollow) ...[
                const SizedBox(width: 8),
                CwitterFollowButton(
                  followerId: currentUid!,
                  followeeId: user.authorId,
                  compact: true,
                ),
              ] else if (!showFollowButton)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

