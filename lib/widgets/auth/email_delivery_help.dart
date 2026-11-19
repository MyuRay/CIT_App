import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailDeliveryHelp extends StatelessWidget {
  const EmailDeliveryHelp({super.key});
  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
      }
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('メールアドレスが正しく、迷惑メールフォルダにも認証メールが届かない場合は、以下へご連絡ください。'),
      Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => _open(context, Uri.parse('https://x.com/citapp')),
            child: const Text(
              'X（旧Twitter）@citapp',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
          TextButton(
            onPressed:
                () => _open(context, Uri.parse('mailto:citapp919@gmail.com')),
            child: const Text(
              'citapp919@gmail.com',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    ],
  );
}
