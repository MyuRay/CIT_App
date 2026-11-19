import 'dart:io';

Map<String, String> runtimeInfo() => {
  'os': Platform.operatingSystem,
  'osVersion': Platform.operatingSystemVersion,
};
