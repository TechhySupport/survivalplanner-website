import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

class PurchaseService {
  // Platform-specific product IDs
  static const String _premiumIdAndroid = 'premium_upgrade';
  static const String _premiumIdIOS = 'premium_upgradev2';

  static String get premiumId {
    if (kIsWeb) return _premiumIdAndroid; // default fallback
    try {
      if (Platform.isIOS) return _premiumIdIOS;
      // Android and others
      return _premiumIdAndroid;
    } catch (_) {
      // In case Platform is unavailable
      return _premiumIdAndroid;
    }
  }

  static const String _prefsKey = 'is_premium';

  static bool isPremium = false;
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Call this at app startup
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
  isPremium = prefs.getBool(_prefsKey) ?? false;
  // Reflect current status in Analytics on startup
  // productId unknown here; we only set premium_status
  await AnalyticsService.setPremiumStatus(isPremium);

    // Optional build-time override: pass --dart-define=FORCE_PREMIUM=true
    const forcePremium = String.fromEnvironment('FORCE_PREMIUM');
    if (forcePremium.toLowerCase() == 'true') {
      isPremium = true;
    }

    // For web builds, default to premium and persist it
    if (kIsWeb) {
      if (!isPremium) {
        isPremium = true;
        await prefs.setBool(_prefsKey, true);
      }
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      // Helpful during StoreKit tests
      // ignore: avoid_print
      print('[IAP] Store not available (simulator without StoreKit config or device offline).');
      return;
    }

    // listen for new purchases
    _subscription ??= _iap.purchaseStream.listen(_handlePurchaseUpdates);

    // restore existing purchases (new API)
    await _iap.restorePurchases();
  }

  /// Query product info from store
  static Future<ProductDetails?> getPremiumProduct() async {
    if (kIsWeb) return null;

    // ignore: avoid_print
    print('[IAP] Querying product details for: $premiumId');

    final response = await _iap.queryProductDetails({premiumId});
    if (response.notFoundIDs.isNotEmpty) {
      // ignore: avoid_print
      print('[IAP] Not found IDs: ${response.notFoundIDs.join(',')}');
    }
    if (response.productDetails.isNotEmpty) {
      // ignore: avoid_print
      print('[IAP] Product found: ${response.productDetails.first.title}');
      return response.productDetails.first;
    }
    // ignore: avoid_print
    print('[IAP] No product details returned.');
    return null;
  }

  /// Start purchase flow
  static Future<void> buyPremium() async {
    if (kIsWeb) return;
    final product = await getPremiumProduct();
    if (product == null) return;
    // ignore: avoid_print
    print('[IAP] Starting purchase for: ${product.id}');
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Handle purchase results
  static void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      // ignore: avoid_print
      print('[IAP] Update: id=${purchase.productID} status=${purchase.status}');
      if (purchase.productID == premiumId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          // ignore: avoid_print
          print('[IAP] Premium unlocked.');
          _setPremium(true, productId: purchase.productID);
        }
        if (purchase.pendingCompletePurchase) {
          // ignore: avoid_print
          print('[IAP] Completing pending purchase.');
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  static Future<void> _setPremium(bool value, {String? productId}) async {
    isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    await AnalyticsService.setPremiumStatus(value, productId: productId);
    if (value && productId == _premiumIdIOS) {
      // iOS V2 upgrade event for conversion counting
      await AnalyticsService.logUpgradePremiumV2(productId: productId);
    }
  }

  /// Dispose listener
  static void dispose() {
    _subscription?.cancel();
  }

  /// Manually trigger restore purchases (for Settings screen)
  static Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    final available = await _iap.isAvailable();
    if (!available) return false;
    try {
      // ignore: avoid_print
      print('[IAP] Restoring purchases...');
      await _iap.restorePurchases();
      return true;
    } catch (_) {
      // ignore: avoid_print
      print('[IAP] Restore failed.');
      return false;
    }
  }
}
