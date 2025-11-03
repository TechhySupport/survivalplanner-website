
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'purchase_service.dart';

final _sb = Supabase.instance.client;

class CloudSyncService {
  // local key prefix for storing page data on device
  static const _localPrefix = 'cloudsync_';

  /// Save page data locally always. If user is premium and logged in, also
  /// attempt to save it to the cloud.
  static Future<void> save(String page, Map<String, dynamic> data) async {
    // persist locally first so app will restore after restart
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_localPrefix$page', json.encode(data));

    // Only sync to cloud when user is premium and authenticated
    if (!PurchaseService.isPremium) return;
    final user = _sb.auth.currentUser;
    if (user == null) return;
    try {
      await _sb.from('calculator_data').upsert({
        'user_id': user.id,
        'page': page,
        'data': data,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,page');
    } catch (_) {
      // ignore network errors - local copy exists
    }
  }

  /// Load page data. Prefer cloud if premium + authenticated; otherwise use
  /// local stored copy when available.
  static Future<Map<String, dynamic>?> load(String page) async {
    final prefs = await SharedPreferences.getInstance();

    // Try cloud first when premium
    if (PurchaseService.isPremium) {
      final user = _sb.auth.currentUser;
      if (user != null) {
        try {
          final row = await _sb.from('calculator_data')
              .select('data')
              .eq('user_id', user.id)
              .eq('page', page)
              .maybeSingle();
          if (row != null) {
            final data = row['data'];
            if (data is Map<String, dynamic>) {
              // cache locally for offline access
              await prefs.setString('$_localPrefix$page', json.encode(data));
              return data;
            }
            if (data is Map) {
              final casted = Map<String, dynamic>.from(data);
              await prefs.setString('$_localPrefix$page', json.encode(casted));
              return casted;
            }
          }
        } catch (_) {
          // fallback to local copy below
        }
      }
    }

    // load local copy if present
    final raw = prefs.getString('$_localPrefix$page');
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // invalid local data
    }
    return null;
  }
}
