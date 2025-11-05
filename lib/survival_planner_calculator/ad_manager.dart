import 'package:flutter/material.dart';

class AdManager {
  // Web-safe stub: disable ads entirely. Keep upgrade popup hook.
  static void loadAppOpenAd(BuildContext context) {}
  static void showAppOpenAd(BuildContext context) {}

  static void registerUserInteraction(BuildContext context) {
    // Could trigger soft upsell after N interactions in the future.
  }

  static void showUpgradePopup(BuildContext context) {
    // No-op — site is 100% free and ad-free
  }
}
