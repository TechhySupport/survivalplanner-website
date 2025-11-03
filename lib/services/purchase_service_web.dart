import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

class PurchaseService {
  static const String _prefsKey = 'is_premium';
  static bool isPremium = true; // Web: premium by default

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Persist premium true for web to disable ads/IAP flows
    isPremium = prefs.getBool(_prefsKey) ?? true;
    await prefs.setBool(_prefsKey, isPremium);
    await AnalyticsService.setPremiumStatus(isPremium);
  }

  static Future<void> buyPremium() async {
    // No-op on web
  }

  static void dispose() {}

  static Future<bool> restorePurchases() async {
    // No purchases to restore on web
    return false;
  }
}
