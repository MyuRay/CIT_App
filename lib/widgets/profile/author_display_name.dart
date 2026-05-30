import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/user_provider.dart';

/// 作者の最新表示名を表示するテキスト
class AuthorDisplayName extends ConsumerWidget {
  const AuthorDisplayName({
    super.key,
    required this.authorId,
    required this.fallback,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String authorId;
  final String fallback;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(
      authorDisplayNameProvider((authorId: authorId, fallback: fallback)),
    );
    final name = resolveAuthorDisplayName(nameAsync, fallback);

    return Text(
      name,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
