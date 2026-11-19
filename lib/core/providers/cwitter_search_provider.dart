import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_follow_user.dart';
import '../../models/community/cwitter_post.dart';
import '../../services/community/cwitter_service.dart';

typedef CwitterSearchResults =
    ({
      List<CwitterPost> posts,
      List<CwitterFollowUser> users,
      List<CwitterFollowUser> tagUsers,
    });

typedef CwitterSearch = Future<CwitterSearchResults> Function(String query);

/// 各タブの検索を同時に開始し、同じキーワードの結果をまとめて返す。
final cwitterSearchProvider = Provider<CwitterSearch>((ref) {
  return (query) async {
    final (posts, users, tagUsers) =
        await (
          CwitterService.searchPosts(query),
          CwitterService.searchUsers(query),
          CwitterService.searchUsersByHashtag(query),
        ).wait;
    return (posts: posts, users: users, tagUsers: tagUsers);
  };
});
