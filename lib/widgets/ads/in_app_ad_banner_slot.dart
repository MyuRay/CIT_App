import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/in_app_ad_provider.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'in_app_ad_card.dart';

/// 指定配置用のバナー広告スロット（広告がなければ非表示）
class InAppAdBannerSlot extends ConsumerWidget {
  const InAppAdBannerSlot({
    super.key,
    required this.placement,
    this.margin,
  });

  final AdPlacement placement;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adAsync = ref.watch(inAppAdProvider(placement));

    return adAsync.maybeWhen(
      data: (ad) {
        if (ad == null) return const SizedBox.shrink();
        return InAppAdCard(
          ad: ad,
          placement: placement,
          margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
