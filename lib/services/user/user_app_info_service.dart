import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_constants.dart';
import 'runtime_info_stub.dart' if (dart.library.io) 'runtime_info_io.dart';

Future<Map<String, String>> loadUserAppInfo() async {
  PackageInfo? package;
  try {
    package = await PackageInfo.fromPlatform();
  } catch (_) {}
  final info = <String, String>{
    ...runtimeInfo(),
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    'appVersion': package?.version ?? AppConstants.appVersion,
    'buildNumber': package?.buildNumber ?? '',
    'packageName': package?.packageName ?? '',
    'locale': WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
  };
  return info.map(
    (key, value) =>
        MapEntry(key, value.length > 240 ? value.substring(0, 240) : value),
  );
}

class UserAppInfoService {
  UserAppInfoService({
    required this.firestore,
    required this.auth,
    this.loadInfo = loadUserAppInfo,
  });
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Future<Map<String, String>> Function() loadInfo;
  final _saved = <String>{};
  final _pending = <String, Future<void>>{};

  Future<void> sync(String uid) async {
    if (_saved.contains(uid)) return;
    final pending = _pending[uid];
    if (pending != null) return pending;
    final task = _sync(uid);
    _pending[uid] = task;
    try {
      await task;
    } finally {
      _pending.remove(uid);
    }
  }

  Future<void> _sync(String uid) async {
    final user = auth.currentUser;
    if (user?.uid != uid || user?.emailVerified != true) return;
    final info = await loadInfo();
    if (auth.currentUser?.uid != uid || auth.currentUser?.emailVerified != true)
      return;
    await firestore
        .collection('users')
        .doc(uid)
        .collection('support_info')
        .doc('client')
        .set({...info, 'updatedAt': FieldValue.serverTimestamp()});
    _saved.add(uid);
  }
}
