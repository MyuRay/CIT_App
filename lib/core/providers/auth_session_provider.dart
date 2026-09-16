import 'package:cit_app/core/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'bulletin_provider.dart';
import 'comment_provider.dart';
import 'cwitter_provider.dart';
import 'filtered_bulletin_provider.dart';
import 'simple_auth_provider.dart';
import 'user_block_provider.dart';
import 'schedule_provider.dart';
import 'notification_provider.dart' show userNotificationsProvider;
import '../../services/notification/notification_service.dart';

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
  ref.invalidate(scheduleProvider);
  ref.invalidate(scheduleListProvider);
  ref.invalidate(todayScheduleProvider);
  ref.invalidate(todayScheduleByIdProvider);
  ref.invalidate(nextClassProvider);
  ref.invalidate(selectedScheduleIdProvider);
  ref.invalidate(userNotificationsProvider);
}

/// アプリ全体で認証セッション変更を監視し、プロバイダーをリセットする。
final authSessionSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(simpleAuthStateProvider, (previous, next) {
    if (previous == null || !next.hasValue) return;

    if (next.asData?.value?.emailVerified == true) {
      NotificationService.refreshTokenRegistration();
    }

    final prevUid = previous.asData?.value?.uid;
    final nextUid = next.asData!.value?.uid;
    if (prevUid == nextUid) return;

    SecureLogger.debug(
      '🔐 認証セッション変更: ${prevUid ?? 'null'} -> ${nextUid ?? 'null'}',
    );
    invalidateAuthSessionProviders(ref);
  });
});
