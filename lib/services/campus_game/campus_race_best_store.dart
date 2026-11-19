import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Serializes local writes so a slower previous finish cannot replace a best.
class CampusRaceBestStore {
  CampusRaceBestStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;
  Future<void> _queue = Future<void>.value();
  static final keyPattern = RegExp(
    r'^cit_bus_best_(?:v1_(?:outward|return)|v2_pop_(?:outward|return|s_bay|neon_city))_[0-9a-f]{8}$',
  );
  static bool valid(Object? key, Object? time) =>
      key is String &&
      keyPattern.hasMatch(key) &&
      time is int &&
      time > 0 &&
      time <= 3600000;

  Future<Map<String, int>> load() async {
    try {
      await _queue;
      final prefs = await _preferences();
      final values = <String, int>{};
      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);
        if (valid(key, value)) values[key] = value as int;
      }
      return values;
    } catch (_) {
      return {};
    }
  }

  Future<bool> save(Object? key, Object? milliseconds) {
    if (!valid(key, milliseconds)) return Future<bool>.value(false);
    final result = Completer<bool>();
    _queue = _queue.then((_) async {
      try {
        final prefs = await _preferences();
        final prior = prefs.get(key as String);
        if (prior is int &&
            valid(key, prior) &&
            prior <= (milliseconds as int)) {
          result.complete(true);
        } else {
          result.complete(await prefs.setInt(key, milliseconds as int));
        }
      } catch (_) {
        result.complete(false);
      }
    });
    return result.future;
  }
}
