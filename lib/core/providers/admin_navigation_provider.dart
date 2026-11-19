import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'settings_provider.dart';

const adminTabVisibleKey = 'adminTabVisible';
final adminTabVisibleProvider = StateProvider<bool>(
  (ref) =>
      ref.watch(sharedPreferencesProvider).getBool(adminTabVisibleKey) ?? true,
);
