import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ads/ad_management_query.dart';
import '../../models/ads/in_app_ad_model.dart';
import 'in_app_ad_editor_dialog.dart';
import 'sponsor_presentation.dart';

class AdStatusBadge extends StatelessWidget {
  const AdStatusBadge({super.key, required this.status});
  final AdDeliveryStatus status;
  @override
  Widget build(BuildContext context) {
    final seed = switch (status) {
      AdDeliveryStatus.running => Colors.green,
      AdDeliveryStatus.scheduled => Colors.blue,
      AdDeliveryStatus.paused => Colors.orange,
      AdDeliveryStatus.ended => Colors.blueGrey,
    };
    final surface = AppColors.tintedSurface(context, seed);
    final ink = AppColors.ensureContrast(seed, surface);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        adStatusLabel(status),
        style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AdManagementCard extends StatelessWidget {
  const AdManagementCard({
    super.key,
    required this.ad,
    required this.now,
    required this.busy,
    required this.onEdit,
    required this.onPreview,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
  });
  final InAppAd ad;
  final DateTime now;
  final bool busy;
  final VoidCallback onEdit, onPreview, onToggle, onDuplicate, onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gold = SponsorPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              ad.isSponsored
                  ? gold.border.withValues(alpha: .55)
                  : colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AdStatusBadge(status: adDeliveryStatus(ad, now)),
                const Spacer(),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                PopupMenuButton<String>(
                  key: ValueKey('ad_menu_${ad.id}'),
                  tooltip: '広告の操作',
                  enabled: !busy,
                  onSelected:
                      (value) =>
                          value == 'duplicate' ? onDuplicate() : onDelete(),
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text('複製して作成'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('広告を削除')),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ad.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (ad.isSponsored)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 18,
                      color: gold.ink,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ad.sponsorName.isEmpty ? 'スポンサー' : ad.sponsorName,
                        style: TextStyle(
                          color: gold.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _detail(
                  context,
                  Icons.dashboard_outlined,
                  adPlacementLabel(ad.placement),
                ),
                _detail(
                  context,
                  ad.actionType == AdActionType.external
                      ? Icons.open_in_new
                      : Icons.article_outlined,
                  ad.actionType == AdActionType.external ? '外部リンク' : '掲示板',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '掲載期間',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ad.startAt == null && ad.endAt == null
                        ? '期間の指定なし'
                        : '${ad.startAt == null ? '開始の指定なし' : adDateLabel(ad.startAt!)}\n→ ${ad.endAt == null ? '終了の指定なし' : adDateLabel(ad.endAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('編集'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onPreview,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('プレビュー'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onToggle,
                  icon: Icon(
                    ad.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 18,
                  ),
                  label: Text(ad.isActive ? '停止' : '有効にする'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(BuildContext context, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 5),
      Flexible(
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}
