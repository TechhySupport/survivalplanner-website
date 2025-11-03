
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';

class PrefsCloudBackup {
  static const String pageKey = 'all_prefs';
  static Future<void> backupAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (final k in keys) {
      final v = prefs.get(k);
      if (v is String || v is int || v is double || v is bool) {
        data[k] = v;
      } else if (v is List<String>) {
        data[k] = v;
      }
    }
    await CloudSyncService.save(pageKey, data);
  }
  static Future<int> restoreAllPrefs() async {
    final cloud = await CloudSyncService.load(pageKey);
    if (cloud == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    for (final e in cloud.entries) {
      final k = e.key; final v = e.value;
      if (v is String) { await prefs.setString(k, v); count++; }
      else if (v is int) { await prefs.setInt(k, v); count++; }
      else if (v is double) { await prefs.setDouble(k, v); count++; }
      else if (v is bool) { await prefs.setBool(k, v); count++; }
      else if (v is List) {
        await prefs.setStringList(k, v.whereType<String>().toList()); count++;
      }
    }
    return count;
  }
}
