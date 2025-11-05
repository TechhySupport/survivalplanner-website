import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';
import '../survival_planner_calculator/settings_page.dart'
    show appLocale; // reuse global notifier
import 'analytics_service.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('LanguagePage');
    _selectedCode = (appLocale.value ?? const Locale('en')).languageCode;
    // Enforce English as default/only selectable for now
    if (_selectedCode != 'en') {
      _selectedCode = 'en';
      // Persist immediately so the app reflects English
      // (no setState needed here)
      _save('en');
    }
  }

  Future<void> _save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', code);
    appLocale.value = Locale(code);
  }

  @override
  Widget build(BuildContext context) {
    final locales = AppLocalizations.supportedLocales;
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: locales.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final loc = locales[i];
                final code = loc.languageCode;
                final isSelected = code == _selectedCode;
                final label = _displayName(code);
                final disabled = code != 'en';
                return ListTile(
                  title: Text(
                    label,
                    style: disabled
                        ? TextStyle(color: Colors.grey.shade500)
                        : null,
                  ),
                  subtitle: disabled
                      ? Text(
                          'Work in progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        )
                      : null,
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : (disabled
                            ? Icon(Icons.lock, color: Colors.grey.shade400)
                            : null),
                  onTap: disabled
                      ? null
                      : () async {
                          if (_selectedCode != code) {
                            setState(() => _selectedCode = code);
                            await _save(code);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Languages other than English are still a work in progress.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'id':
        return 'Bahasa Indonesia';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'sv':
        return 'Svenska';
      case 'zh':
        return '中文';
      default:
        return code;
    }
  }
}
