import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

final supabase = Supabase.instance.client;

class CloudSyncService {
  static Future<void> saveCalculatorData(String page, Map<String, dynamic> data) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('calculator_data').upsert({
      'user_id': user.id,
      'page': page,
      'data': jsonEncode(data),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> loadCalculatorData(String page) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('calculator_data')
        .select('data')
        .eq('user_id', user.id)
        .eq('page', page)
        .maybeSingle();

    if (response != null && response['data'] != null) {
      return jsonDecode(response['data']);
    }
    return null;
  }
}
