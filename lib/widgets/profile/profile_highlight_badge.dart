import 'package:flutter/material.dart';

/// 未設定・未確認の項目向け（赤丸＋白の「！」）。
class ProfileHighlightBadge extends StatelessWidget {
  const ProfileHighlightBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
      child: const Text(
        '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
