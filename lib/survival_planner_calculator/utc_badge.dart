import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';

/// Reusable UTC time badge. Shows live updating UTC clock every second.
class UtcBadge extends StatelessWidget {
  final bool use24;
  const UtcBadge({super.key, this.use24 = true});

  @override
  Widget build(BuildContext context) {
    final locTag = Localizations.localeOf(context).toLanguageTag();
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
          const Duration(seconds: 1), (_) => DateTime.now().toUtc()),
      builder: (context, snapshot) {
        final utc = snapshot.data ?? DateTime.now().toUtc();
        final formatted = use24
            ? DateFormat.Hms(locTag).format(utc)
            : DateFormat('hh:mm:ss a', locTag).format(utc);
        final loc = AppLocalizations.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.lightBlue),
          ),
          child: Text(
            '${loc?.utcTime ?? 'UTC'}: $formatted',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.lightBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
