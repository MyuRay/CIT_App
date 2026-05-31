import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/train_provider.dart'
    show
        trainHomeDecisionProvider,
        trainInfoAvailableProvider,
        trainInfoUseMockProvider,
        TrainHomeVm;
import '../../models/train/train_snapshot.dart';
import '../../services/train/train_departure_decision.dart';

const String kOfficialTrainOperationUrl =
    'https://traininfo.jreast.co.jp/train_info/kanto.aspx';

/// 試験実装の注意書き（カード下部）
const String _footnote =
    '※試験的な実装です。一部の電車（路線・方面）のみ実装中であり、データは順次追加予定です。\n'
    '※表示は目安です。最新の発車・運行情報は公式運転情報でご確認ください。';

/// キャンパス別のカード見出し（津田沼は JR 表記）
String trainHomeCardTitle(String campusKey) {
  switch (campusKey) {
    case 'narashino':
      return 'JR新習志野駅発　電車';
    default:
      return 'JR津田沼駅発　電車';
  }
}

/// 学バス（primary / オレンジ系）と区別する電車カード用アクセント
abstract final class TrainAccessColors {
  static const Color accent = Color(0xFF1565C0);
  static const Color accentDark = Color(0xFF0D47A1);

  static Color gradientStart(BuildContext context) {
    final hsl = HSLColor.fromColor(accent);
    final boost = Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.32;
    return hsl.withLightness((hsl.lightness + boost).clamp(0.0, 1.0)).toColor();
  }

  static Color gradientEnd(BuildContext context) {
    final hsl = HSLColor.fromColor(accent);
    final boost = Theme.of(context).brightness == Brightness.dark ? 0.30 : 0.42;
    return hsl.withLightness((hsl.lightness + boost).clamp(0.0, 1.0)).toColor();
  }

  static Color labelBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.92);
  }

  static Color labelText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }
}

/// ホーム「最寄駅電車情報」カード（学バスカードと同レイアウト・電車色で区別）
class TrainAccessHomeCard extends ConsumerWidget {
  const TrainAccessHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(trainHomeDecisionProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(context, ref, campusKey: ref.watch(preferredBusCampusProvider)),
            const SizedBox(height: 12),
            asyncVm.when(
              data: (vm) => _TrainAccessBody(vm: vm),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => _TrainErrorPanel(theme: Theme.of(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    WidgetRef ref, {
    required String campusKey,
  }) {
    final theme = Theme.of(context);
    final snap = ref.watch(trainHomeDecisionProvider).valueOrNull?.snapshot;
    final showDirection =
        snap != null && snap.directions.length > 1;

    return Row(
      children: [
        const Icon(
          Icons.directions_railway,
          color: TrainAccessColors.accent,
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            trainHomeCardTitle(campusKey),
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showDirection)
          IconButton(
            onPressed: () => _showDirectionPicker(context, ref, snap),
            icon: const Icon(Icons.swap_horiz),
            tooltip: '方面を変更',
            iconSize: 20,
            color: TrainAccessColors.accent,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        TextButton.icon(
          onPressed: () async {
            final uri = Uri.parse(kOfficialTrainOperationUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(
            Icons.open_in_new,
            size: 16,
            color: TrainAccessColors.accent,
          ),
          label: const Text(
            '公式運転情報',
            style: TextStyle(fontSize: 11, color: TrainAccessColors.accent),
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }
}

class _TrainErrorPanel extends StatelessWidget {
  const _TrainErrorPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text(
            '電車情報の読み込みに失敗しました',
            style: TextStyle(color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }
}

class _TrainAccessBody extends ConsumerWidget {
  const _TrainAccessBody({required this.vm});

  final TrainHomeVm vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snap = vm.snapshot;

    if (snap == null) {
      return _TrainEmptyPanel(ref: ref);
    }

    final dir = vm.direction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vm.delay != null && vm.delay!.status != TrainDelayStatus.normal) ...[
          _DelayBanner(delay: vm.delay!),
          const SizedBox(height: 8),
        ],
        _TrainGradientPanel(
          direction: dir,
          child: dir == null
              ? _innerInfoBox(
                  context,
                  child: Text(
                    '方面データがありません',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _TrainCountdownPanel(vm: vm, direction: dir),
        ),
        const SizedBox(height: 8),
        _TrainFootnote(theme: theme),
      ],
    );
  }
}

class _TrainEmptyPanel extends ConsumerWidget {
  const _TrainEmptyPanel({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final available = ref.watch(trainInfoAvailableProvider);
    final useMock = ref.watch(trainInfoUseMockProvider);
    final emptyMsg = useMock
        ? 'モックデータを取得できません'
        : available
            ? '時刻データを取得できません'
            : 'API未設定（デバッグはモック自動）';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TrainAccessColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: TrainAccessColors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.directions_railway_outlined,
                size: 40,
                color: TrainAccessColors.accent,
              ),
              const SizedBox(height: 8),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!available && !useMock && kDebugMode) ...[
                const SizedBox(height: 6),
                Text(
                  'URL: ${AppConstants.trainInfoApiBaseUrl.isEmpty ? '(空)' : AppConstants.trainInfoApiBaseUrl}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _TrainFootnote(theme: theme),
      ],
    );
  }
}

class _TrainGradientPanel extends StatelessWidget {
  const _TrainGradientPanel({
    required this.direction,
    required this.child,
  });

  final TrainDirectionSnapshot? direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TrainAccessColors.gradientStart(context),
            TrainAccessColors.gradientEnd(context),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TrainAccessColors.accent.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: TrainAccessColors.accent.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: TrainAccessColors.labelBg(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.train,
                  color: TrainAccessColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TrainLineDirectionLabels(direction: direction),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

}

/// 路線名・方面名（2行）
class _TrainLineDirectionLabels extends StatelessWidget {
  const _TrainLineDirectionLabels({required this.direction});

  final TrainDirectionSnapshot? direction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = TrainAccessColors.labelText(context);
    final lineStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
      height: 1.2,
    );
    final dirStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: textColor.withValues(alpha: 0.88),
      height: 1.2,
    );

    final dir = direction;
    if (dir == null) {
      return Text(
        '中央・総武線各駅停車',
        style: lineStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final line = dir.lineLabel?.trim();
    final dirLabel = dir.directionLabel.isEmpty
        ? dir.directionKey
        : dir.directionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (line != null && line.isNotEmpty)
          Text(line, style: lineStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (dirLabel.isNotEmpty)
          Text(dirLabel, style: dirStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _TrainCountdownPanel extends StatelessWidget {
  const _TrainCountdownPanel({
    required this.vm,
    required this.direction,
  });

  final TrainHomeVm vm;
  final TrainDirectionSnapshot direction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departure = vm.decision.effectiveNextDeparture;
    if (vm.decision.category == TrainDecisionCategory.noData ||
        departure == null) {
      return _innerInfoBox(
        context,
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '発車時刻を確認中',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final remaining = departure.difference(now);
    final hours = remaining.inHours.clamp(0, 99);
    final minutes = remaining.inMinutes.remainder(60).abs();
    final seconds = remaining.inSeconds.remainder(60).abs();

    final depTime = DateFormat('H:mm').format(departure);
    final second = direction.secondDepartureAt;
    final secondStr =
        second != null ? DateFormat('H:mm').format(second) : null;
    final label = trainDecisionCategoryLabelJa(vm.decision.category);

    return _innerInfoBox(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule,
                color: TrainAccessColors.accent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '次の電車: $depTime',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (secondStr != null)
                        TextSpan(
                          text: ' （その次: $secondStr）',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.65),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimeUnit(context, hours.toString().padLeft(2, '0'), '時間'),
              const SizedBox(width: 8),
              _buildTimeUnit(
                context,
                minutes.toString().padLeft(2, '0'),
                '分',
              ),
              const SizedBox(width: 8),
              _buildTimeUnit(
                context,
                seconds.toString().padLeft(2, '0'),
                '秒',
              ),
              const Spacer(),
              const Icon(
                Icons.train,
                color: TrainAccessColors.accent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _categoryColor(vm.decision.category),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(TrainDecisionCategory c) {
    switch (c) {
      case TrainDecisionCategory.plenty:
        return Colors.green.shade700;
      case TrainDecisionCategory.slight:
        return Colors.teal.shade700;
      case TrainDecisionCategory.tight:
        return Colors.orange.shade800;
      case TrainDecisionCategory.recommendNext:
        return Colors.red.shade700;
      case TrainDecisionCategory.noData:
        return Colors.grey;
    }
  }

  Widget _buildTimeUnit(BuildContext context, String value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: TrainAccessColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

Widget _innerInfoBox(BuildContext context, {required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

class _TrainFootnote extends StatelessWidget {
  const _TrainFootnote({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _footnote,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// ホームカード編集シート内: 最寄駅のキャンパス選択（メインキャンパスと共通）
class TrainHomeCardCampusSetting extends ConsumerWidget {
  const TrainHomeCardCampusSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final campus = ref.watch(preferredBusCampusProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JR津田沼駅発　電車',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '表示キャンパス（学バス・プロフィールのメインキャンパスと共通）',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tsudanuma', label: Text('津田沼')),
              ButtonSegment(value: 'narashino', label: Text('新習志野')),
            ],
            selected: {campus},
            onSelectionChanged: (selected) {
              final next = selected.first;
              ref.read(settingsProvider.notifier).setPreferredBusCampus(next);
            },
          ),
        ],
      ),
    );
  }
}

/// 残り時間を「あと◯分◯秒」形式に（0以下はまもなく発車）
/// ウィジェット等で利用する場合用。ホームカードは時分秒ボックス表示。
String formatTrainCountdown(Duration remaining) {
  final secs = remaining.inSeconds;
  if (secs <= 0) return 'まもなく発車';
  final m = secs ~/ 60;
  final s = secs % 60;
  if (m > 0) {
    return 'あと${m}分${s.toString().padLeft(2, '0')}秒';
  }
  return 'あと${s}秒';
}

Future<void> _showDirectionPicker(
  BuildContext context,
  WidgetRef ref,
  TrainSnapshot snap,
) async {
  final campus = ref.read(preferredBusCampusProvider);
  final settings = ref.read(settingsProvider);
  final current = campus == 'narashino'
      ? settings.trainPreferredDirectionNarashino
      : settings.trainPreferredDirectionTsudanuma;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '表示する方面',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final d in snap.directions)
              ListTile(
                dense: true,
                leading: const Icon(
                  Icons.train,
                  color: TrainAccessColors.accent,
                ),
                title: Text(
                  d.lineLabel?.trim().isNotEmpty == true
                      ? d.lineLabel!.trim()
                      : (d.directionLabel.isEmpty
                          ? d.directionKey
                          : d.directionLabel),
                ),
                subtitle: d.lineLabel?.trim().isNotEmpty == true
                    ? Text(
                        d.directionLabel.isEmpty
                            ? d.directionKey
                            : d.directionLabel,
                      )
                    : null,
                trailing:
                    (current.isEmpty
                            ? snap.directions.first.directionKey ==
                                d.directionKey
                            : current == d.directionKey)
                        ? const Icon(
                            Icons.check,
                            color: TrainAccessColors.accent,
                          )
                        : null,
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setTrainPreferredDirection(campus, d.directionKey);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _DelayBanner extends StatelessWidget {
  const _DelayBanner({required this.delay});

  final TrainDelayInfo delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (delay.status) {
      TrainDelayStatus.suspended => theme.colorScheme.errorContainer,
      TrainDelayStatus.delayed => theme.colorScheme.tertiaryContainer,
      _ => theme.colorScheme.surfaceContainerHighest,
    };
    final onColor = switch (delay.status) {
      TrainDelayStatus.suspended => theme.colorScheme.onErrorContainer,
      TrainDelayStatus.delayed => theme.colorScheme.onTertiaryContainer,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    final title = switch (delay.status) {
      TrainDelayStatus.delayed => '遅延情報あり',
      TrainDelayStatus.suspended => '運転見合わせ',
      TrainDelayStatus.unknown => '運行情報を確認',
      _ => '',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        delay.message?.trim().isNotEmpty == true
            ? '$title：${delay.message}'
            : title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: onColor,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
