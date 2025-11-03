import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class MapService {
  static final _client = Supabase.instance.client;

  // 2.1 Create a map (File → New Map)
  static Future<Map<String, dynamic>> createMap(
    String name,
    Map<String, dynamic> data,
  ) async {
    final user = _client.auth.currentUser!;
    final row = await _client
        .from('maps')
        .insert({
          'owner_id': user.id,
          'name': name,
          'data': data,
          'share_mode': 'private', // 'private' | 'view' | 'edit'
        })
        .select('id, slug, name, share_mode')
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  // 2.2 Update a map (save)
  static Future<void> saveMap(String slug, Map<String, dynamic> data) async {
    await _client.from('maps').update({'data': data}).eq('slug', slug);
  }

  // 2.3 Change sharing (File → Share)
  // mode: 'private' | 'view' | 'edit'
  static Future<void> setShareMode(String slug, String mode) async {
    await _client.from('maps').update({'share_mode': mode}).eq('slug', slug);
  }

  // 2.4 Build the two share links
  static String viewLink(String slug) =>
      'https://survival-planner.com/map/$slug';
  static String editLink(String slug) =>
      'https://survival-planner.com/map/$slug?edit=1';

  // 4) Load by slug
  static Future<Map<String, dynamic>?> loadMapBySlug(String slug) async {
    final row = await _client
        .from('maps')
        .select('id, slug, owner_id, name, data, share_mode')
        .eq('slug', slug)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row as Map);
  }

  // Helper to normalize stored data into a JSON-encodable objects list
  static List<dynamic> extractObjectsList(dynamic data) {
    if (data == null) return const [];
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['objects'] is List) {
          return decoded['objects'] as List;
        }
      } catch (_) {}
      return const [];
    }
    if (data is List) return data;
    if (data is Map && data['objects'] is List) return data['objects'] as List;
    return const [];
  }
}
