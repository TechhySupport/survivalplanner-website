import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

class PurchaseService {
  static const String _premiumIdAndroid = 'premium_upgrade';
  static const String _premiumIdIOS = 'premium_upgradev2';

  static String get premiumId => defaultTargetPlatform == TargetPlatform.iOS
      ? _premiumIdIOS
      : _premiumIdAndroid;

  static const String _prefsKey = 'is_premium';
  static bool isPremium = false;
  static final iap.InAppPurchase _iap = iap.InAppPurchase.instance;
  static StreamSubscription<List<iap.PurchaseDetails>>? _subscription;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium = prefs.getBool(_prefsKey) ?? false;
    await AnalyticsService.setPremiumStatus(isPremium);

    final available = await _iap.isAvailable();
    if (!available) {
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(_handlePurchaseUpdates);
    await _iap.restorePurchases();
  }

  static Future<iap.ProductDetails?> getPremiumProduct() async {
    final response = await _iap.queryProductDetails({premiumId});
    if (response.productDetails.isNotEmpty) {
      return response.productDetails.first;
    }
    return null;
  }

  static Future<void> buyPremium() async {
    final product = await getPremiumProduct();
    if (product == null) return;
    final purchaseParam = iap.PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static void _handlePurchaseUpdates(List<iap.PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      if (purchase.productID == premiumId) {
        if (purchase.status == iap.PurchaseStatus.purchased ||
            purchase.status == iap.PurchaseStatus.restored) {
          _setPremium(true, productId: purchase.productID);
        }
        if (purchase.pendingCompletePurchase) {
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
      await AnalyticsService.logUpgradePremiumV2(productId: productId);
    }
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static Future<bool> restorePurchases() async {
    final available = await _iap.isAvailable();
    if (!available) return false;
    try {
      await _iap.restorePurchases();
      return true;
    } catch (_) {
      return false;
    }
  }
}
