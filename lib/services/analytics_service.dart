// AnalyticsService is currently a no-op stub to keep builds lightweight.

/// Centralized analytics helper
class AnalyticsService {
  /// Log an Analytics screen view with a readable page name.
  static Future<void> logPage(String name) async {
    // No-op stub: integrate firebase_analytics and replace this body in production
    return;
  }

  /// Set a user property representing premium status so you can segment users.
  /// Values: 'paid' | 'free'
  static Future<void> setPremiumStatus(
    bool isPremium, {
    String? productId,
  }) async {
    // No-op stub
    return;
  }

  /// Log a one-time upgrade event for iOS Premium v2.
  /// Use this to count conversions. For lifetime counts, prefer user property segmentation,
  /// or BigQuery export for deduped user counts.
  static Future<void> logUpgradePremiumV2({String? productId}) async {
    // No-op stub
    return;
  }

  // Platform helper kept for future analytics expansion; currently unused.
}
