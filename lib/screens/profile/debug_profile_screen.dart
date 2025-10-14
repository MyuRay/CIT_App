import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/theme_provider.dart';

class DebugProfileScreen extends ConsumerWidget {
  const DebugProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔧 DebugProfileScreen build開始');
    
    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    
    print('🔧 テーマモード: $themeMode');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ（デバッグ版）'),
        backgroundColor: Colors.red,
      ),
      body: Container(
        color: Colors.yellow[100],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'デバッグ版マイページ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            Container(
              width: double.infinity,
              color: Colors.blue[100],
              child: Card(
                color: Colors.white,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '設定',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    
                    Container(
                      color: Colors.green[100],
                      child: ListTile(
                        leading: const Icon(Icons.palette, color: Colors.red),
                        title: const Text('テーマ設定', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '現在: ${_getThemeDisplayName(themeMode)}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
                        onTap: () {
                          print('🔧 テーマ設定がタップされました！');
                          _showThemeDialog(context, themeModeNotifier, themeMode);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () {
                print('🔧 直接テーマ変更ボタンがタップされました');
                if (themeMode == ThemeMode.light) {
                  themeModeNotifier.setDarkMode();
                } else {
                  themeModeNotifier.setLightMode();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('直接テーマ切り替え（現在: ${_getThemeDisplayName(themeMode)}）'),
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
    print('🔧 テーマダイアログを表示します');
    
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
                print('🔧 ライトモード選択');
                notifier.setLightMode();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ダークモード'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (value) {
                print('🔧 ダークモード選択');
                notifier.setDarkMode();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('システム設定'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (value) {
                print('🔧 システム設定選択');
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