import 'package:flutter/material.dart';
import '../../models/bulletin/bulletin_model.dart';

/// 画像なしの投稿に使う、カテゴリごとの共通カバー。
class BulletinCategoryImage extends StatelessWidget {
  const BulletinCategoryImage({super.key, required this.category});
  final BulletinCategory category;
  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.tryParse(category.color.replaceFirst('#', 'ff'), radix: 16) ??
          0xff607d8b,
    );
    final icon = switch (category.icon) {
      'event' => Icons.event_outlined,
      'group' => Icons.groups_outlined,
      'school' => Icons.school_outlined,
      'announcement' => Icons.campaign_outlined,
      'work' => Icons.work_outline,
      'local_offer' => Icons.local_offer_outlined,
      _ => Icons.dashboard_outlined,
    };
    return Semantics(
      image: true,
      label: '${category.name}のカテゴリ画像',
      child: ColoredBox(
        color: Color.alphaBlend(color.withValues(alpha: .13), Colors.white),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -22,
              top: -36,
              child: Icon(icon, size: 190, color: color.withValues(alpha: .07)),
            ),
            Positioned(
              left: -30,
              bottom: -48,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .05),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(icon, size: 40, color: color),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.lerp(color, Colors.black, .4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'CIT App 掲示板',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
