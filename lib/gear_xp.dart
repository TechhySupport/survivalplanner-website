import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/cloud_sync_service.dart';
// Premium removed — fully free on web
import 'services/analytics_service.dart';
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

class GearXPCalculator extends StatefulWidget {
  const GearXPCalculator({super.key});

  @override
  _GearXPCalculatorState createState() => _GearXPCalculatorState();
}

class _GearXPCalculatorState extends State<GearXPCalculator> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Gear 1',
  );
  final TextEditingController _currentLevelController = TextEditingController();
  final TextEditingController _desiredLevelController = TextEditingController();
  int? _currentLevel;
  int? _desiredLevel;
  late int _xpNeeded;
  late Map<String, int> _breakdown;
  List<GearEntry> _entries = [];

  // FocusNodes for numeric inputs (to show tick toolbar)
  final FocusNode _currentLevelFocus = FocusNode();
  final FocusNode _desiredLevelFocus = FocusNode();

  KeyboardActionsConfig get _keyboardConfig => KeyboardActionsConfig(
    keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
    actions: [
      KeyboardActionsItem(
        focusNode: _currentLevelFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _desiredLevelFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
    ],
  );

  int get _maxSlots => 3;

  // Removed legacy upgrade dialog; paywall shown inline where needed.

  // Full XP table for levels 1–100
  final Map<int, int> xpTable = {
    1: 10,
    2: 15,
    3: 20,
    4: 25,
    5: 30,
    6: 35,
    7: 40,
    8: 45,
    9: 50,
    10: 55,
    11: 60,
    12: 65,
    13: 70,
    14: 75,
    15: 80,
    16: 85,
    17: 90,
    18: 95,
    19: 100,
    20: 105,
    21: 110,
    22: 115,
    23: 120,
    24: 125,
    25: 130,
    26: 135,
    27: 140,
    28: 145,
    29: 150,
    30: 160,
    31: 170,
    32: 180,
    33: 190,
    34: 200,
    35: 210,
    36: 220,
    37: 230,
    38: 240,
    39: 250,
    40: 270,
    41: 290,
    42: 310,
    43: 330,
    44: 350,
    45: 370,
    46: 390,
    47: 410,
    48: 430,
    49: 450,
    50: 470,
    51: 490,
    52: 510,
    53: 530,
    54: 550,
    55: 570,
    56: 590,
    57: 610,
    58: 630,
    59: 650,
    60: 680,
    61: 710,
    62: 740,
    63: 770,
    64: 800,
    65: 830,
    66: 860,
    67: 890,
    68: 920,
    69: 950,
    70: 990,
    71: 1030,
    72: 1070,
    73: 1110,
    74: 1150,
    75: 1190,
    76: 1230,
    77: 1270,
    78: 1310,
    79: 1350,
    80: 1400,
    81: 1450,
    82: 1500,
    83: 1550,
    84: 1600,
    85: 1650,
    86: 1700,
    87: 1750,
    88: 1800,
    89: 1850,
    90: 1900,
    91: 1950,
    92: 2000,
    93: 2050,
    94: 2100,
    95: 2150,
    96: 2200,
    97: 2250,
    98: 2300,
    99: 2350,
    100: 2400,
  };

  // Shard types in desired order:
  final List<_GearItem> gearItems = [
    _GearItem('Purple Gear (100xp)', 100),
    _GearItem('Green Gear (10xp)', 10),
    _GearItem('Purple Gear (150xp)', 150),
    _GearItem('Blue Gear (60xp)', 60),
    _GearItem('Green Glove (30xp)', 30),
    _GearItem('Common Gear (10xp)', 10),
  ];

  Timer? _cloudTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('GearXPCalculator');
    _xpNeeded = 0;
    _breakdown = {};
    _loadEntries();
    _loadCloud();
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gear_entries');
    if (data != null) {
      final List list = jsonDecode(data);
      setState(() {
        _entries = list.map((e) => GearEntry.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString('gear_entries', data);
  }

  // --- Cloud Sync ---
  Future<void> _saveCloud() async {
    await CloudSyncService.save('gear_xp_calculator', {
      'entries': _entries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('gear_xp_calculator');
    if (data == null || !mounted) return;
    setState(() {
      if (data['entries'] != null) {
        _entries = List<Map<String, dynamic>>.from(
          data['entries'],
        ).map((e) => GearEntry.fromJson(e)).toList();
      }
    });
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    _nameController.dispose();
    _currentLevelController.dispose();
    _desiredLevelController.dispose();
    _currentLevelFocus.dispose();
    _desiredLevelFocus.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_currentLevel != null &&
        _desiredLevel != null &&
        _desiredLevel! > _currentLevel!) {
      int total = 0;
      for (int lvl = _currentLevel!; lvl < _desiredLevel!; lvl++) {
        total += xpTable[lvl] ?? 0;
      }
      final breakdown = <String, int>{};
      for (var item in gearItems) {
        breakdown[item.asset] = (total + item.xp - 1) ~/ item.xp;
      }
      _xpNeeded = total;
      _breakdown = breakdown;
    } else {
      _xpNeeded = 0;
      _breakdown = {};
    }
  }

  void _addGear() {
    _calculate();
    final entry = GearEntry(
      name: _nameController.text,
      xpNeeded: _xpNeeded,
      breakdown: Map.from(_breakdown),
    );
    setState(() => _entries.add(entry));
    _saveEntries();
    _saveCloud();
  }

  @override
  Widget build(BuildContext context) {
    final totalAllXp = _entries.fold<int>(0, (sum, e) => sum + e.xpNeeded);
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
                  config: _keyboardConfig,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionCard(
                          context,
                          title: 'Gear Entries',
                          icon: Icons.extension,
                          color: Colors.indigo,
                          chipValue: totalAllXp,
                          child: Column(
                            children: [
                              _entryFormCard(),
                              const SizedBox(height: 12),
                              ..._entries.asMap().entries.map(
                                (e) => _gearEntryTile(e.key, e.value),
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
                    Row(
                      children: [
                        const Icon(Icons.summarize, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All Gears Total XP: $totalAllXp',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
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
                        if (_entries.isNotEmpty)
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _entries.clear());
                              _saveEntries();
                              _saveCloud();
                            },
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

  // --- Light theme helpers & cards ---
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
              '$chipValue',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.build_circle, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                'Add Gear Entry',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _textField(_nameController, 'Name'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _levelField(
                  _currentLevelController,
                  'Current Level',
                  (v) => _currentLevel = v,
                  _currentLevelFocus,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _levelField(
                  _desiredLevelController,
                  'Desired Level',
                  (v) => _desiredLevel = v,
                  _desiredLevelFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: (_entries.length >= _maxSlots)
                    ? Colors.grey.shade300
                    : Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                if (_entries.length >= _maxSlots) return;
                _addGear();
              },
              icon: Icon(
                (_entries.length >= _maxSlots) ? Icons.lock : Icons.add,
                color: (_entries.length >= _maxSlots)
                    ? Colors.black87
                    : Colors.white,
              ),
              label: Text(
                (_entries.length >= _maxSlots)
                    ? 'Max entries reached'
                    : 'Add Gear',
                style: TextStyle(
                  color: (_entries.length >= _maxSlots)
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gearEntryTile(int idx, GearEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total XP: ${e.xpNeeded}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black54),
            onPressed: () {
              setState(() => _entries.removeAt(idx));
              _saveEntries();
              _saveCloud();
            },
          ),
        ],
      ),
    );
  }

  // No locked card — free site

  Widget _textField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: _lightInputDecoration(label),
    );
  }

  Widget _levelField(
    TextEditingController controller,
    String label,
    ValueChanged<int?> onValid,
    FocusNode focusNode,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.black87),
      decoration: _lightInputDecoration(label),
      onEditingComplete: () => focusNode.unfocus(),
      onChanged: (val) {
        final parsed = int.tryParse(val);
        int? clamped = parsed;
        if (parsed != null) {
          if (parsed > 100) clamped = 100;
          if (parsed < 1) clamped = 1;
        }
        if (clamped != null && clamped.toString() != val) {
          controller.text = clamped.toString();
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
        setState(
          () => onValid(
            (clamped != null && clamped >= 1 && clamped <= 100)
                ? clamped
                : null,
          ),
        );
      },
    );
  }

  InputDecoration _lightInputDecoration(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.indigo),
    ),
  );
}

class _GearItem {
  final String asset;
  final int xp;
  _GearItem(this.asset, this.xp);
}

class GearEntry {
  final String name;
  final int xpNeeded;
  final Map<String, int> breakdown;
  GearEntry({
    required this.name,
    required this.xpNeeded,
    required this.breakdown,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'xpNeeded': xpNeeded,
    'breakdown': breakdown,
  };
  factory GearEntry.fromJson(Map<String, dynamic> j) => GearEntry(
    name: j['name'],
    xpNeeded: j['xpNeeded'],
    breakdown: Map<String, int>.from(j['breakdown']),
  );
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
