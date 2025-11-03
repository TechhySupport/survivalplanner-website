import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/cloud_sync_service.dart';
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

class EssenceCalculator extends StatefulWidget {
  const EssenceCalculator({super.key});

  @override
  _EssenceCalculatorState createState() => _EssenceCalculatorState();
}

class _EssenceCalculatorState extends State<EssenceCalculator> {
  // ---------------- Cloud sync ----------------
  static const String _cloudPageKey = 'essence_calculator';
  Timer? _cloudTimer;
  Timer? _debounce;

  // What we send to Supabase
  Map<String, dynamic> _toCloudMap() => {'essenceGears': _essenceGears};

  // How we apply data coming back from Supabase
  void _applyCloudMap(Map<String, dynamic> data) {
    final list = data['essenceGears'];
    if (list is List) {
      _essenceGears = List<Map<String, dynamic>>.from(
        list.map((e) => Map<String, dynamic>.from(e as Map)),
      );
      // keep local mirror fresh too
      _saveEssenceGears();
      setState(() {});
    }
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load(_cloudPageKey);
    if (!mounted || data == null) return;
    _applyCloudMap(data);
  }

  void _queueCloudSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveCloud);
  }

  Future<void> _saveCloud() async {
    try {
      await CloudSyncService.save(_cloudPageKey, _toCloudMap());
    } catch (e) {
      // Useful if RLS/policies fail
      // ignore: avoid_print
      print('Essence cloud save error: $e');
    }
  }

  // ---------------- Local state ----------------
  static const List<int> _shardTable = [
    10, 20, 30, 40, 50, 60, 70, 80, 90, 100, // 1-10
    110, 120, 130, 140, 150, 160, 170, 180, 190, 200, // 11-20
  ];
  late SharedPreferences _prefs;

  List<Map<String, dynamic>> _essenceGears = [];
  // Premium gating removed for web: allow up to 3 slots
  int get _maxSlots => 3;

  // Premium UI removed

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('EssenceCalculator');
    _init();
  }

  Future<void> _init() async {
    await _loadPrefsAndInit(); // local first (instant UI)
    // then hydrate from cloud if any
    unawaited(_loadCloud());
    // periodic cloud save as a safety net
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    // small initial save to ensure a record exists
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  Future<void> _loadPrefsAndInit() async {
    _prefs = await SharedPreferences.getInstance();
    final savedData = _prefs.getString('essence_stone_data');
    if (savedData != null) {
      try {
        _essenceGears = List<Map<String, dynamic>>.from(
          json.decode(savedData) as List,
        );
      } catch (_) {
        _essenceGears = [_defaultEssenceGear(1)];
      }
    } else {
      _essenceGears = [_defaultEssenceGear(1)];
    }
    setState(() {});
  }

  Map<String, dynamic> _defaultEssenceGear(int idx) => {
    'label': 'Gear $idx',
    'start': 0,
    'desired': 0,
  };

  void _saveEssenceGears() {
    _prefs.setString('essence_stone_data', json.encode(_essenceGears));
  }

  void _updateEssenceGear(int index, String key, dynamic value) {
    setState(() {
      _essenceGears[index][key] = value;
    });
    _saveEssenceGears();
    _queueCloudSave(); // <<--- cloud mirror
  }

  int _calculateEssence(int start, int desired) {
    if (desired <= start) return 0;
    int sum = 0;
    for (int lvl = start; lvl < desired; lvl++) {
      sum += _shardTable[lvl];
    }
    return sum;
  }

  int _calculateMythicHeroGears(int start, int desired) {
    if (desired <= 10) return 0;
    int gears = 0;
    for (int lvl = start; lvl < desired; lvl++) {
      if (lvl >= 10) gears += 1;
    }
    return gears;
  }

  int _totalEssence() => _essenceGears.fold(
    0,
    (total, g) => total + _calculateEssence(g['start'], g['desired']),
  );

  @override
  Widget build(BuildContext context) {
    final total = _totalEssence();
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard(
                        context,
                        title: 'Essence Gears',
                        icon: Icons.auto_fix_high,
                        color: Colors.blueAccent,
                        chipValue: total,
                        child: Column(
                          children: [
                            ..._essenceGears.asMap().entries.map(
                              (e) => _gearCard(e.key, e.value),
                            ),
                            if (_essenceGears.length < _maxSlots)
                              _addGearButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
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
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _essenceGears = [_defaultEssenceGear(1)];
                        });
                        _saveEssenceGears();
                        _queueCloudSave();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total Essence Needed: $total',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
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

  Widget _gearCard(int idx, Map<String, dynamic> data) {
    final essence = _calculateEssence(data['start'], data['desired']);
    final mythic = _calculateMythicHeroGears(data['start'], data['desired']);
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: data['label'],
                  decoration: _lightInputDecoration('Gear Name'),
                  onChanged: (t) => _updateEssenceGear(idx, 'label', t),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black54),
                onPressed: () {
                  setState(() => _essenceGears.removeAt(idx));
                  _saveEssenceGears();
                  _queueCloudSave();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _levelSelectorLight(
                'Start',
                data['start'],
                (v) => _updateEssenceGear(idx, 'start', v),
              ),
              const SizedBox(width: 12),
              _levelSelectorLight(
                'Desired',
                data['desired'],
                (v) => _updateEssenceGear(idx, 'desired', v),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Essence',
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$essence',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (mythic > 0)
                      Text(
                        '$mythic Mythic Gear${mythic > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelSelectorLight(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            value: value,
            isDense: true,
            items: List.generate(
              21,
              (i) => DropdownMenuItem(value: i, child: Text('$i')),
            ),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            decoration: _lightInputDecoration(''),
          ),
        ],
      ),
    );
  }

  Widget _addGearButton() {
    return InkWell(
      onTap: () {
        if (_essenceGears.length >= _maxSlots) return;
        final idx = _essenceGears.length + 1;
        setState(() => _essenceGears.add(_defaultEssenceGear(idx)));
        _saveEssenceGears();
        _queueCloudSave();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Add Gear',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed locked slot card (premium removed)

  // Light input style similar to SVS_calculator
  InputDecoration _lightInputDecoration(String label) => InputDecoration(
    labelText: label.isEmpty ? null : label,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blueAccent),
    ),
  );

  // Removed dark theme helpers in favor of light-themed components

  @override
  void dispose() {
    _debounce?.cancel();
    _cloudTimer?.cancel();
    super.dispose();
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
