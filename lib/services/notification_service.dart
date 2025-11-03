// Lightweight no-op notification service to avoid heavy native dependencies.
class NotificationService {
  static Future<void> init() async {
    // Intentionally left blank; integrate flutter_local_notifications in native builds if needed.
  }

  static Future<void> scheduleNotification(
    int id,
    String title,
    DateTime utcTime,
  ) async {
    // No-op: replace with actual scheduling in mobile builds.
    // For web, consider showing an in-app reminder or using Notifications API with permissions.
  }
}
