import 'package:flutter/material.dart';
import 'premium_paywall.dart';

class PaywallHelper {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return const FractionallySizedBox(
          heightFactor: 0.7, // half screen
          child: PremiumPaywall(),
        );
      },
    );
  }
}
