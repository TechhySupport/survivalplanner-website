import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class DatabaseService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Example: Get all records from a table
  static Future<List<Map<String, dynamic>>> getAllRecords(
    String tableName,
  ) async {
    try {
      final response = await _client.from(tableName).select();
      return response;
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  // Example: Insert a new record
  static Future<void> insertRecord(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from(tableName).insert(data);
    } catch (e) {
      throw Exception('Error inserting data: $e');
    }
  }

  // Example: Update a record
  static Future<void> updateRecord(
    String tableName,
    Map<String, dynamic> data,
    String idField,
    dynamic id,
  ) async {
    try {
      await _client.from(tableName).update(data).eq(idField, id);
    } catch (e) {
      throw Exception('Error updating data: $e');
    }
  }

  // Example: Delete a record
  static Future<void> deleteRecord(
    String tableName,
    String idField,
    dynamic id,
  ) async {
    try {
      await _client.from(tableName).delete().eq(idField, id);
    } catch (e) {
      throw Exception('Error deleting data: $e');
    }
  }

  // Real-time subscription example
  static RealtimeChannel subscribeToTable(
    String tableName,
    Function(PostgresChangePayload) onData,
  ) {
    return _client
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: onData,
        )
        .subscribe();
  }
}
