import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'bulletin_provider.dart';
import 'comment_provider.dart';
import 'cwitter_provider.dart';
import 'filtered_bulletin_provider.dart';
import 'simple_auth_provider.dart';
import 'user_block_provider.dart';

/// ログイン/ログアウトで UID が変わったとき、Firestore 依存プロバイダーを再取得する。
void invalidateAuthSessionProviders(Ref ref) {
  ref.invalidate(bulletinFeedProvider);
  ref.invalidate(filteredBulletinPostsProvider);
  ref.invalidate(filteredBulletinPostsByCategoryProvider);
  ref.invalidate(cwitterFeedProvider);
  ref.invalidate(cwitterPostsProvider);
  ref.invalidate(filteredCwitterPostsProvider);
  ref.invalidate(filteredFollowingFeedCwitterPostsProvider);
  ref.invalidate(likedCwitterPostsProvider);
  ref.invalidate(filteredLikedCwitterPostsProvider);
  ref.invalidate(myCwitterPostsProvider);
  ref.invalidate(currentAppUserStreamProvider);

  ref.invalidate(blockedUsersProvider);
  ref.invalidate(blockedUserIdsProvider);
  ref.invalidate(hiddenUserIdsProvider);
  ref.invalidate(blockedUsersListProvider);
  ref.invalidate(blockedUserCountProvider);

  ref.invalidate(postCommentsProvider);
}

/// アプリ全体で認証セッション変更を監視し、プロバイダーをリセットする。
final authSessionSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(simpleAuthStateProvider, (previous, next) {
    if (previous == null || !next.hasValue) return;

    final prevUid = previous.asData?.value?.uid;
    final nextUid = next.asData!.value?.uid;
    if (prevUid == nextUid) return;

    debugPrint(
      '🔐 認証セッション変更: ${prevUid ?? 'null'} -> ${nextUid ?? 'null'}',
    );
    invalidateAuthSessionProviders(ref);
  });
});
