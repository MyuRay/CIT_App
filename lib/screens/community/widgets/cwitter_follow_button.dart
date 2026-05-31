import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_follow_counts_override_provider.dart';
import '../../../core/providers/cwitter_provider.dart';
import '../../../services/community/cwitter_service.dart';
import 'cwitter_follow_feedback.dart';

class CwitterFollowButton extends ConsumerStatefulWidget {
  const CwitterFollowButton({
    super.key,
    required this.followerId,
    required this.followeeId,
    this.compact = false,
  });

  final String followerId;
  final String followeeId;
  final bool compact;

  @override
  ConsumerState<CwitterFollowButton> createState() =>
      _CwitterFollowButtonState();
}

class _CwitterFollowButtonState extends ConsumerState<CwitterFollowButton> {
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

    final followeeAsync =
        ref.read(cwitterFollowCountsProvider(widget.followeeId));
    final followerAsync =
        ref.read(cwitterFollowCountsProvider(widget.followerId));

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
      loading: () => SizedBox(
        width: widget.compact ? 20 : 24,
        height: widget.compact ? 20 : 24,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (streamFollowing) {
        final isFollowing = _optimisticFollowing ?? streamFollowing;
        final mutedColor =
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);

        if (isFollowing) {
          return OutlinedButton(
            onPressed: _isUpdating ? null : () => _toggleFollow(true),
            style: _buttonStyle(context, mutedColor, filled: false),
            child: Text(widget.compact ? 'フォロー中' : 'フォロー中'),
          );
        }

        return FilledButton(
          onPressed: _isUpdating ? null : () => _toggleFollow(false),
          style: _buttonStyle(
            context,
            Colors.white,
            filled: true,
          ),
          child: Text(widget.compact ? 'フォロー' : 'フォローする'),
        );
      },
    );
  }

  ButtonStyle _buttonStyle(
    BuildContext context,
    Color foregroundColor, {
    required bool filled,
  }) {
    if (widget.compact) {
      final base = filled
          ? FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: Theme.of(context).textTheme.labelMedium,
            )
          : OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: Theme.of(context).textTheme.labelMedium,
            );
      return base;
    }

    if (filled) {
      return FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 10),
      );
    }

    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      side: BorderSide(
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
    );
  }
}
