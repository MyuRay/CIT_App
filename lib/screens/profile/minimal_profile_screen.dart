import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/theme_provider.dart';

class MinimalProfileScreen extends ConsumerWidget {
  const MinimalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔧 MinimalProfileScreen build開始');
    
    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    
    print('🔧 テーマモード取得成功: $themeMode');

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'マイページ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('テーマ設定'),
                subtitle: Text('現在: ${_getThemeDisplayName(themeMode)}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  print('🔧 テーマ設定がタップされました');
                  _showThemeDialog(context, themeModeNotifier, themeMode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'ライト';
      case ThemeMode.dark:
        return 'ダーク';
      case ThemeMode.system:
        return 'システム';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeModeNotifier notifier, ThemeMode current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('ライトモード'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (value) {
                notifier.setLightMode();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ダークモード'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (value) {
                notifier.setDarkMode();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('システム設定'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (value) {
                notifier.setSystemMode();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}