import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/app_update_service.dart';
import '../../widgets/common/app_update_prompt.dart';

final appNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final appUpdateObserverProvider = Provider<AppUpdateNavigatorObserver>((ref) {
  final observer = AppUpdateNavigatorObserver();
  ref.onDispose(observer.dispose);
  return observer;
});

final appUpdateCheckProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  if (kIsWeb) return null;
  return AppUpdateService.firebase(defaultTargetPlatform).check();
});
