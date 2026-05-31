import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_poll.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../services/community/cwitter_service.dart';

class CwitterPollWidget extends ConsumerStatefulWidget {
  const CwitterPollWidget({super.key, required this.post});

  final CwitterPost post;

  @override
  ConsumerState<CwitterPollWidget> createState() => _CwitterPollWidgetState();
}

class _CwitterPollWidgetState extends ConsumerState<CwitterPollWidget> {
  CwitterPoll? _pollOverride;
  bool _isVoting = false;

  CwitterPoll get _poll => _pollOverride ?? widget.post.poll!;

  Future<void> _vote(String optionId) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    if (_poll.hasVoted(uid) || _isVoting) return;

    setState(() => _isVoting = true);
    try {
      final updated = await CwitterService.castPollVote(
        postId: widget.post.id,
        userId: uid,
        optionId: optionId,
      );
      if (!mounted) return;
      setState(() {
        _pollOverride = updated;
        _isVoting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVoting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uid = ref.watch(currentUserIdProvider);
    final poll = _poll;
    final hasVoted = poll.hasVoted(uid);
    final selectedId = poll.votedOptionId(uid);
    final showResults = hasVoted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...poll.options.map((option) {
          final ratio = poll.voteRatioFor(option.id);
          final isSelected = selectedId == option.id;
          final canTap = uid != null && !hasVoted && !_isVoting;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canTap ? () => _vote(option.id) : null,
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : colorScheme.outlineVariant.withValues(alpha: 0.6),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (showResults)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: ratio.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (isSelected
                                          ? const Color(0xFF4CAF50)
                                          : colorScheme.primary)
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (showResults) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${(ratio * 100).round()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        Text(
          poll.totalVotes > 0
              ? '${poll.totalVotes}票'
              : hasVoted
                  ? '0票'
                  : 'タップして投票',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
