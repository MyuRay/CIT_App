import 'package:flutter/foundation.dart';

Map<String, String> runtimeInfo() => {
  'os': defaultTargetPlatform.name,
  'osVersion': 'ブラウザからは取得できません',
};
