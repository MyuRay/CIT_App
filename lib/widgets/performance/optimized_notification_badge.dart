import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/global_notification_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'memoized_consumer.dart';

/// 最適化された通知バッジウィジェット
/// 不要な再構築を避け、パフォーマンスを向上させる
class OptimizedNotificationBadge extends ConsumerWidget {
  final VoidCallback onTap;
  final String tooltip;
  
  const OptimizedNotificationBadge({
    super.key,
    required this.onTap,
    this.tooltip = '通知',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MemoizedAsyncConsumer<User?>(
      provider: authStateProvider,
      builder: (context, authState, child) {
        return authState.when(
          data: (user) => user != null 
              ? _AuthenticatedNotificationBadge(
                  user: user,
                  onTap: onTap,
                  tooltip: tooltip,
                )
              : _UnauthenticatedNotificationBadge(
                  onTap: onTap,
                  tooltip: '$tooltip（ログインが必要）',
                ),
          loading: () => _LoadingNotificationBadge(
            onTap: null,
            tooltip: '$tooltip（認証中）',
          ),
          error: (_, __) => _ErrorNotificationBadge(
            onTap: onTap,
            tooltip: '$tooltip（認証エラー）',
          ),
        );
      },
    );
  }
}

/// 認証済みユーザーの通知バッジ
class _AuthenticatedNotificationBadge extends ConsumerWidget {
  final User user;
  final VoidCallback onTap;
  final String tooltip;
  
  const _AuthenticatedNotificationBadge({
    required this.user,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // グローバル通知の未読数を取得
    final globalUnreadCount = ref.watch(
      unviewedNotificationCountProvider.select((count) => count)
    );
    
    // 個人通知の未読数を取得（メモ化されたConsumerで最適化）
    return MemoizedAsyncConsumer<int>(
      provider: unreadNotificationCountProvider(user.uid),
      builder: (context, regularCountAsync, child) {
        return regularCountAsync.when(
          data: (regularCount) {
            final totalCount = regularCount + globalUnreadCount;
            return _NotificationBadgeIcon(
              count: totalCount,
              onTap: onTap,
              tooltip: tooltip,
              isError: false,
            );
          },
          loading: () => _NotificationBadgeIcon(
            count: globalUnreadCount,
            onTap: onTap,
            tooltip: tooltip,
            isError: false,
          ),
          error: (_, __) => _NotificationBadgeIcon(
            count: 0,
            onTap: onTap,
            tooltip: '$tooltip（オフライン）',
            isError: true,
          ),
        );
      },
    );
  }
}

/// 未認証ユーザーの通知バッジ
class _UnauthenticatedNotificationBadge extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;
  
  const _UnauthenticatedNotificationBadge({
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_off),
      onPressed: onTap,
      tooltip: tooltip,
    );
  }
}

/// ローディング状態の通知バッジ
class _LoadingNotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final String tooltip;
  
  const _LoadingNotificationBadge({
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: onTap,
      tooltip: tooltip,
    );
  }
}

/// エラー状態の通知バッジ
class _ErrorNotificationBadge extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;
  
  const _ErrorNotificationBadge({
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_off),
      onPressed: onTap,
      tooltip: tooltip,
    );
  }
}

/// 通知バッジアイコン（メモ化済み）
class _NotificationBadgeIcon extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final String tooltip;
  final bool isError;
  
  const _NotificationBadgeIcon({
    required this.count,
    required this.onTap,
    required this.tooltip,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(isError ? Icons.notifications_off : Icons.notifications),
          onPressed: onTap,
          tooltip: tooltip,
        ),
        if (count > 0 && !isError)
          Positioned(
            right: 8,
            top: 8,
            child: _NotificationBadgeCounter(count: count),
          ),
      ],
    );
  }
}

/// 通知数カウンター（メモ化済み）
class _NotificationBadgeCounter extends StatelessWidget {
  final int count;
  
  const _NotificationBadgeCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}