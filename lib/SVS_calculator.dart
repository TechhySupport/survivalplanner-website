import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/paywall_helper.dart';
import 'services/purchase_service.dart';
import 'services/analytics_service.dart';
import 'services/cloud_sync_service.dart';
import 'utc_badge.dart';
import 'settings_page.dart';
import 'services/loginscreen.dart';
import 'bottom_nav_bar.dart';
import 'web/web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'event_page.dart';
import 'troops_page.dart';

class SVSCalculatorPage extends StatefulWidget {
  const SVSCalculatorPage({super.key});

  // For EventPage to fetch last SVS total
  static Future<int> getLastSVSTotal() async {
    final prefs = await SharedPreferences.getInstance();
    int getTotalMinutes(String dKey, String hKey, String mKey) {
      final d = int.tryParse(prefs.getString(dKey) ?? '') ?? 0;
      final h = int.tryParse(prefs.getString(hKey) ?? '') ?? 0;
      final m = int.tryParse(prefs.getString(mKey) ?? '') ?? 0;
      return d * 24 * 60 + h * 60 + m;
    }

    final c = getTotalMinutes(
      'construction_days',
      'construction_hours',
      'construction_minutes',
    );
    final r = getTotalMinutes(
      'research_days',
      'research_hours',
      'research_minutes',
    );
    final t = getTotalMinutes('troop_days', 'troop_hours', 'troop_minutes');
    final g = getTotalMinutes(
      'general_days',
      'general_hours',
      'general_minutes',
    );

    final widgets =
        (int.tryParse(prefs.getString('hero_widgets') ?? '') ?? 0) * 8000;
    final rare =
        (int.tryParse(prefs.getString('rare_shards') ?? '') ?? 0) * 350;
    final epic =
        (int.tryParse(prefs.getString('epic_shards') ?? '') ?? 0) * 1220;
    final mystic =
        (int.tryParse(prefs.getString('mystic_shards') ?? '') ?? 0) * 3040;
    final mithril =
        (int.tryParse(prefs.getString('mithril') ?? '') ?? 0) * 144000;

    final speedupPoints = (c + r + t + g) * 30;
    final total = speedupPoints + widgets + rare + epic + mystic + mithril;
    return total;
  }

  @override
  State<SVSCalculatorPage> createState() => _SVSCalculatorPageState();
}

class _SVSCalculatorPageState extends State<SVSCalculatorPage> {
  late SharedPreferences _prefs;
  final _formatter = NumberFormat('#,###');

  // Controllers for all inputs
  final Map<String, TextEditingController> _controllers = {
    'construction_days': TextEditingController(),
    'construction_hours': TextEditingController(),
    'construction_minutes': TextEditingController(),
    'research_days': TextEditingController(),
    'research_hours': TextEditingController(),
    'research_minutes': TextEditingController(),
    'troop_days': TextEditingController(),
    'troop_hours': TextEditingController(),
    'troop_minutes': TextEditingController(),
    'general_days': TextEditingController(),
    'general_hours': TextEditingController(),
    'general_minutes': TextEditingController(),
    'hero_widgets': TextEditingController(),
    'rare_shards': TextEditingController(),
    'epic_shards': TextEditingController(),
    'mystic_shards': TextEditingController(),
    'mithril': TextEditingController(),
    'refined_fire_crystal': TextEditingController(),
    'fire_crystal': TextEditingController(),
    'refined_fire_crystal_shards': TextEditingController(),
    'essence_stone': TextEditingController(),
  };

  // Focus nodes to drive the Done toolbar
  final Map<String, FocusNode> _focusNodes = {};

  String _result = 'Total SVS Points: 0';
  int _speedupPoints = 0;
  int _heroPoints = 0;
  int _fireCrystalPoints = 0;

  final BorderRadius _cardRadius = BorderRadius.circular(14);
  final Color _cardBg = const Color(0xFFF7F8FA);
  final Color _accent = const Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('SVSCalculatorPage');
    for (final key in _controllers.keys) {
      _focusNodes[key] = FocusNode();
    }
    _initPrefsAndListeners();
    // Try to load previously saved cloud data
    _loadCloud();
  }

  Future<void> _initPrefsAndListeners() async {
    _prefs = await SharedPreferences.getInstance();
    _controllers.forEach((key, ctrl) {
      final saved = _prefs.getString(key);
      if (saved != null) ctrl.text = saved;
      ctrl.addListener(() {
        _prefs.setString(key, ctrl.text);
        _calculate();
      });
    });
    _calculate();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  int _getTotalMinutes(String dKey, String hKey, String mKey) {
    final d = int.tryParse(_controllers[dKey]!.text) ?? 0;
    final h = int.tryParse(_controllers[hKey]!.text) ?? 0;
    final m = int.tryParse(_controllers[mKey]!.text) ?? 0;
    return d * 24 * 60 + h * 60 + m;
  }

  void _calculate() {
    final c = _getTotalMinutes(
      'construction_days',
      'construction_hours',
      'construction_minutes',
    );
    final r = _getTotalMinutes(
      'research_days',
      'research_hours',
      'research_minutes',
    );
    final t = _getTotalMinutes('troop_days', 'troop_hours', 'troop_minutes');
    final g = _getTotalMinutes(
      'general_days',
      'general_hours',
      'general_minutes',
    );

    final widgets =
        (int.tryParse(_controllers['hero_widgets']!.text) ?? 0) * 8000;
    final rare = (int.tryParse(_controllers['rare_shards']!.text) ?? 0) * 350;
    final epic = (int.tryParse(_controllers['epic_shards']!.text) ?? 0) * 1220;
    final mystic =
        (int.tryParse(_controllers['mystic_shards']!.text) ?? 0) * 3040;
    final mithril = (int.tryParse(_controllers['mithril']!.text) ?? 0) * 144000;

    final refinedFireCrystal =
        (int.tryParse(_controllers['refined_fire_crystal']!.text) ?? 0) * 30000;
    final fireCrystal =
        (int.tryParse(_controllers['fire_crystal']!.text) ?? 0) * 2000;
    final refinedFireCrystalShards =
        (int.tryParse(_controllers['refined_fire_crystal_shards']!.text) ?? 0) *
        1000;
    final essenceStone =
        (int.tryParse(_controllers['essence_stone']!.text) ?? 0) * 4000;

    _speedupPoints = (c + r + t + g) * 30;
    _heroPoints = widgets + rare + epic + mystic + mithril + essenceStone;
    _fireCrystalPoints =
        refinedFireCrystal + fireCrystal + refinedFireCrystalShards;

    final total = _speedupPoints + _heroPoints + _fireCrystalPoints;
    setState(() {
      _result = 'Total SVS Points: ${_formatter.format(total)}';
    });
  }

  void _resetAll() {
    _controllers.forEach((key, ctrl) {
      ctrl.clear();
      _prefs.remove(key);
    });
    setState(() {
      _result = 'Total SVS Points: 0';
      _speedupPoints = 0;
      _heroPoints = 0;
      _fireCrystalPoints = 0;
    });
    _saveCloud();
  }

  KeyboardActionsConfig _keyboardConfig() {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      actions: _controllers.keys
          .map(
            (key) => KeyboardActionsItem(
              focusNode: _focusNodes[key]!,
              toolbarButtons: [
                (node) => IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Done',
                  onPressed: () => node.unfocus(),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildTimeRow(String label, String d, String h, String m) {
    final bool gated =
        !PurchaseService.isPremium &&
        (label == 'Construction' || label == 'Research');
    InputDecoration dec(String lbl) => InputDecoration(
      labelText: lbl,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );

    final content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _cardRadius,
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: _accent.withOpacity(.75),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controllers[d],
                  focusNode: _focusNodes[d],
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: dec('Days'),
                  enabled: !gated,
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controllers[h],
                  focusNode: _focusNodes[h],
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: dec('Hours'),
                  enabled: !gated,
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controllers[m],
                  focusNode: _focusNodes[m],
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: dec('Minutes'),
                  enabled: !gated,
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!gated) return content;
    return Stack(
      children: [
        content,
        Positioned.fill(
          child: Material(
            color: Colors.white.withOpacity(0.65),
            borderRadius: _cardRadius,
            child: InkWell(
              borderRadius: _cardRadius,
              onTap: () => PaywallHelper.show(context),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock, size: 18, color: Colors.black54),
                    SizedBox(width: 6),
                    Text(
                      'Premium Required',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericInput(String label, String key) {
    final bool gated =
        !PurchaseService.isPremium &&
        (label == 'Mystic Hero Shards' ||
            label == 'Mithril' ||
            label == 'Refined Fire Crystal Shards');

    final container = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _cardRadius,
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.adjust_rounded,
                size: 18,
                color: _accent.withOpacity(.75),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers[key],
            focusNode: _focusNodes[key],
            keyboardType: const TextInputType.numberWithOptions(
              signed: false,
              decimal: false,
            ),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Enter amount',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            enabled: !gated,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );

    if (!gated) return container;
    return Stack(
      children: [
        container,
        Positioned.fill(
          child: Material(
            color: Colors.white.withOpacity(0.65),
            borderRadius: _cardRadius,
            child: InkWell(
              borderRadius: _cardRadius,
              onTap: () => PaywallHelper.show(context),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock, size: 18, color: Colors.black54),
                    SizedBox(width: 6),
                    Text(
                      'Premium Required',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required int chipValue,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: color,
          collapsedIconColor: color,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(.35)),
            ),
            child: Text(
              _formatter.format(chipValue),
              style: TextStyle(
                color: color.darken(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: UtcBadge(use24: true),
        ),
        bottom: isWide
            ? PreferredSize(
                preferredSize: const Size.fromHeight(42),
                child: _WebTopNav(
                  onNavigate: (label) {
                    switch (label) {
                      case 'Home':
                        if (kIsWeb) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WebLandingPage(),
                            ),
                          );
                        } else {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                        break;
                      case 'Chief':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChiefPage()),
                        );
                        break;
                      case 'Heroes':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HeroPage()),
                        );
                        break;
                      case 'Building':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuildingPage(),
                          ),
                        );
                        break;
                      case 'Event':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EventPage()),
                        );
                        break;
                      case 'Troops':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TroopsPage()),
                        );
                        break;
                    }
                  },
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ).then((_) => setState(() {})),
          ),
          if (Supabase.instance.client.auth.currentSession != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                setState(() {});
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => setState(() {}));
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Expanded(
                child: KeyboardActions(
                  config: _keyboardConfig(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionCard(
                          context,
                          title: 'Speed Ups',
                          icon: Icons.flash_auto_rounded,
                          color: Colors.blueAccent,
                          chipValue: _speedupPoints,
                          child: Column(
                            children: [
                              _buildTimeRow(
                                'Construction',
                                'construction_days',
                                'construction_hours',
                                'construction_minutes',
                              ),
                              _buildTimeRow(
                                'Research',
                                'research_days',
                                'research_hours',
                                'research_minutes',
                              ),
                              _buildTimeRow(
                                'Troop Training',
                                'troop_days',
                                'troop_hours',
                                'troop_minutes',
                              ),
                              _buildTimeRow(
                                'General',
                                'general_days',
                                'general_hours',
                                'general_minutes',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionCard(
                          context,
                          title: 'Heroes & Items',
                          icon: Icons.shield_moon_outlined,
                          color: Colors.deepPurple,
                          chipValue: _heroPoints,
                          child: Column(
                            children: [
                              _buildNumericInput(
                                'Hero Widgets',
                                'hero_widgets',
                              ),
                              _buildNumericInput(
                                'Rare Hero Shards',
                                'rare_shards',
                              ),
                              _buildNumericInput(
                                'Epic Hero Shards',
                                'epic_shards',
                              ),
                              _buildNumericInput(
                                'Mystic Hero Shards',
                                'mystic_shards',
                              ),
                              _buildNumericInput('Mithril', 'mithril'),
                              _buildNumericInput(
                                'Essence Stone',
                                'essence_stone',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionCard(
                          context,
                          title: 'Fire Crystal',
                          icon: Icons.local_fire_department_outlined,
                          color: Colors.redAccent,
                          chipValue: _fireCrystalPoints,
                          child: Column(
                            children: [
                              _buildNumericInput(
                                'Fire Crystal',
                                'fire_crystal',
                              ),
                              _buildNumericInput(
                                'Refined Fire Crystal',
                                'refined_fire_crystal',
                              ),
                              _buildNumericInput(
                                'Refined Fire Crystal Shards',
                                'refined_fire_crystal_shards',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Save to Cloud'),
                          onPressed: () async {
                            final session =
                                Supabase.instance.client.auth.currentSession;
                            if (session == null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                              setState(() {});
                              return;
                            }
                            await _saveCloud();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved to cloud')),
                            );
                          },
                        ),
                        ElevatedButton(
                          onPressed: _resetAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
    );
  }

  Future<void> _saveCloud() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final data = <String, dynamic>{
      'fields': _controllers.map((k, v) => MapEntry(k, v.text)),
      'result': _result,
    };
    try {
      await CloudSyncService.save('svs_calculator', data);
    } catch (_) {}
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('svs_calculator');
    if (data == null) return;
    final fields = data['fields'];
    if (fields is Map) {
      fields.forEach((k, v) {
        if (_controllers.containsKey(k)) {
          _controllers[k]!.text = (v ?? '').toString();
        }
      });
      _calculate();
      setState(() {});
    }
  }
}

extension _ColorShade on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    final adjusted = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return adjusted.toColor();
  }
}

class _WebTopNav extends StatelessWidget {
  final void Function(String label) onNavigate;
  const _WebTopNav({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final labels = const [
      'Home',
      'Chief',
      'Heroes',
      'Building',
      'Event',
      'Troops',
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            for (final l in labels) ...[
              TextButton(
                onPressed: () => onNavigate(l),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
