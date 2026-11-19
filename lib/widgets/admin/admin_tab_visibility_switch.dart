import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/admin_navigation_provider.dart';
import '../../core/providers/settings_provider.dart';

class AdminTabVisibilitySwitch extends ConsumerStatefulWidget {
  const AdminTabVisibilitySwitch({super.key});
  @override
  ConsumerState<AdminTabVisibilitySwitch> createState() =>
      _AdminTabVisibilitySwitchState();
}

class _AdminTabVisibilitySwitchState
    extends ConsumerState<AdminTabVisibilitySwitch> {
  bool _saving = false;
  Future<void> _setVisible(bool visible) async {
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(sharedPreferencesProvider)
          .setBool(adminTabVisibleKey, visible);
      if (!saved) throw StateError('Preference was not saved');
      if (mounted) ref.read(adminTabVisibleProvider.notifier).state = visible;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('表示設定を保存できませんでした。もう一度お試しください。')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: SwitchListTile.adaptive(
      key: const Key('admin_tab_visibility'),
      title: const Text('ボトムの管理タブを表示'),
      subtitle: const Text('この端末での表示を切り替えます。非表示のときはマイページから管理センターを開けます。'),
      value: ref.watch(adminTabVisibleProvider),
      onChanged: _saving ? null : _setVisible,
    ),
  );
}
