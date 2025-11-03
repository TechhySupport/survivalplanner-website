import 'package:flutter/material.dart';
import 'dart:async';
import 'generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/purchase_service.dart'; // <-- add this import
import 'services/terms_and_services.dart';
import 'services/privacy_policy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/language.dart';
import 'services/account_settings.dart';
import 'services/analytics_service.dart';

// Use the same global supabase client as in main.dart
final supabase = Supabase.instance.client;

final ValueNotifier<Locale?> appLocale = ValueNotifier(null);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _versionLabel;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('SettingsPage');
    // Refresh premium status on settings open
    PurchaseService.init().then((_) => setState(() {}));
    _loadVersion();

    // Listen to auth changes to update login status
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {}); // Refresh UI when auth state changes
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _versionLabel = 'Version ${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    final user = session?.user;
    final bool isLoggedIn = user != null;
    final Color loginBg = isLoggedIn
        ? Colors.green.shade50
        : Colors.red.shade50;
    final Color loginFg = isLoggedIn
        ? Colors.green.shade800
        : Colors.red.shade800;
    final IconData loginIcon = isLoggedIn
        ? Icons.check_circle
        : Icons.error_outline;
    final Color loginIconColor = isLoggedIn ? Colors.green : Colors.red;
    // No premium state on web — everything is free
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsButton(
            title: user != null
                ? 'Account Settings'
                : AppLocalizations.of(context)!.login,
            background: loginBg,
            textColor: loginFg,
            leadingIcon: loginIcon,
            leadingColor: loginIconColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
              ).then((_) => setState(() {}));
            },
          ),
          SettingsButton(
            title: AppLocalizations.of(context)!.language,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LanguagePage()));
            },
          ),
          SettingsButton(
            title: 'Terms & Services',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsAndServicesPage()),
              );
            },
          ),
          SettingsButton(
            title: 'Privacy Policy',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),
          // Purchases/restore not applicable — site is 100% free
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.forum, color: Colors.indigo, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Community',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join our Discord chat to discuss strategy and share feedback.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        const url = 'https://discord.gg/yChmEzz4Mn';
                        final uri = Uri.parse(url);
                        if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open Discord link.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.forum),
                      label: const Text('Join our Discord chat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_versionLabel != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blueGrey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _versionLabel!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? background;
  final Color? textColor;
  final IconData? leadingIcon;
  final Color? leadingColor;

  const SettingsButton({
    super.key,
    required this.title,
    required this.onTap,
    this.background,
    this.textColor,
    this.leadingIcon,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      child: ListTile(
        leading: leadingIcon != null
            ? Icon(leadingIcon, color: leadingColor)
            : null,
        title: Text(
          title,
          style: textColor != null ? TextStyle(color: textColor) : null,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
