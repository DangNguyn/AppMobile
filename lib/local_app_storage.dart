import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hive storage for growing local app data, with SharedPreferences fallback for
/// widget tests and migration of existing chat/inbox data on first launch.
class LocalAppStorage {
  LocalAppStorage._();

  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    if (_box?.isOpen == true) return;
    try {
      final directory = await getApplicationSupportDirectory();
      Hive.init(directory.path);
      final box = await Hive.openBox<dynamic>('fomogo_app_data');
      final preferences = await SharedPreferences.getInstance();
      for (final key in preferences.getKeys()) {
        if (!_isMigratedKey(key) || box.containsKey(key)) continue;
        final value = preferences.get(key);
        if (value is String) await box.put(key, value);
      }
      _box = box;
    } catch (_) {
      // Keep the existing SharedPreferences-backed flow if local DB startup
      // fails, so the rest of the app remains usable.
    }
  }

  static bool _isMigratedKey(String key) =>
      key == 'fomogo_saved_conversations' ||
      key.startsWith('fomogo_notifications_');

  static Future<String?> getString(String key) async {
    final value = _box?.get(key);
    if (value is String) return value;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final box = _box;
    if (box?.isOpen == true) {
      await box!.put(key, value);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }
}
