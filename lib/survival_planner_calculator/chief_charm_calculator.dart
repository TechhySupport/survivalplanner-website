import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloud_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/purchase_service.dart';
import '../services/paywall_helper.dart';
import '../services/analytics_service.dart';
import 'utc_badge.dart';
import 'settings_page.dart';
import '../services/loginscreen.dart';
import 'bottom_nav_bar.dart';
import 'web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'event_page.dart';
import 'troops_page.dart';

class ChiefCharmCalculatorPage extends StatefulWidget {
  const ChiefCharmCalculatorPage({super.key});

  @override
  State<ChiefCharmCalculatorPage> createState() =>
      _ChiefCharmCalculatorPageState();
}

class _ChiefCharmCalculatorPageState extends State<ChiefCharmCalculatorPage> {
  final List<String> _lockedGears = ['Pants', 'Ring', 'Staff'];
  bool get _isPremium => PurchaseService.isPremium;
  // ---------- Cloud sync ----------
  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('chief_charm_calculator');
    if (data == null || !mounted) return;

    setState(() {
      if (data['startLevels'] != null) {
        startLevels
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(
              data['startLevels'],
            ).map((k, v) => MapEntry(k, List<int?>.from(v))),
          );
      }
      if (data['endLevels'] != null) {
        endLevels
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(
              data['endLevels'],
            ).map((k, v) => MapEntry(k, List<int?>.from(v))),
          );
      }
      _calculate();
      // If nothing selected, auto pick the first gear that has data
      selectedGear ??= gearParts.firstWhere(
        (g) => (endLevels[g] ?? const [0, 0, 0]).any((e) => (e ?? 0) > 0),
        orElse: () => '',
      );
      if (selectedGear == '') selectedGear = null;
    });
  }

  Timer? _cloudTimer;
  Future<void> _saveCloud() async {
    await CloudSyncService.save('chief_charm_calculator', {
      'startLevels': startLevels,
      'endLevels': endLevels,
    });
  }

  // ---------- Data ----------
  final List<String> gearParts = [
    "Helm",
    "Watch",
    "Coat",
    "Pants",
    "Ring",
    "Staff",
  ];
  final List<String> charmLabels = ["Charm 1", "Charm 2", "Charm 3"];
  final List<int> levels = List.generate(12, (i) => i); // 0..11 (0 = None)

  // [Charm Guide, Charm Design, Jewel Secrets, Power]
  final List<List<int>> data = [
    [5, 5, 0, 205700],
    [40, 15, 0, 288000],
    [60, 40, 0, 370000],
    [80, 100, 0, 452000],
    [100, 200, 0, 576000],
    [120, 300, 0, 700000],
    [140, 400, 0, 824000],
    [200, 400, 0, 948000],
    [300, 400, 0, 1072000],
    [420, 420, 0, 1196000],
    [560, 420, 0, 1320000],
  ];

  late SharedPreferences _prefs;
  String? selectedGear;

  final Map<String, List<int?>> startLevels = {};
  final Map<String, List<int?>> endLevels = {};
  List<int> total = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('ChiefCharmCalculatorPage');

    // 1) Load local prefs first (instant UX)
    _initPrefs().then((_) {
      // 2) Then load cloud to override with server truth
      _loadCloud();
    });

    // 3) Periodic cloud save (plus we save on every user change too)
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );

    // first “lazy” save so a new user gets a row soon after opening
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    for (final gear in gearParts) {
      startLevels[gear] = List<int?>.generate(
        3,
        (i) => _prefs.getInt('${gear}_start_$i') ?? 0,
      );
      endLevels[gear] = List<int?>.generate(
        3,
        (i) => _prefs.getInt('${gear}_end_$i') ?? 0,
      );
    }
    _calculate();

    // Preselect a gear if any data exists locally
    selectedGear ??= gearParts.firstWhere(
      (g) => (endLevels[g] ?? const [0, 0, 0]).any((e) => (e ?? 0) > 0),
      orElse: () => '',
    );

    if (mounted) setState(() {});
  }

  // ---------- Logic ----------
  Future<void> _onLevelChanged(
    String gear,
    int index,
    bool isStart,
    int? value,
  ) async {
    setState(() {
      if (isStart) {
        startLevels[gear]![index] = value ?? 0;
        _prefs.setInt('${gear}_start_$index', value ?? 0);

        if ((endLevels[gear]![index] ?? 0) < (value ?? 0)) {
          endLevels[gear]![index] = value ?? 0;
          _prefs.setInt('${gear}_end_$index', value ?? 0);
        }
      } else {
        endLevels[gear]![index] = value ?? 0;
        _prefs.setInt('${gear}_end_$index', value ?? 0);
      }
      _calculate();
    });

    await _saveCloud();
  }

  Future<void> _applyToAll(String fromGear, int charmIndex) async {
    final start = startLevels[fromGear]![charmIndex] ?? 0;
    final end = endLevels[fromGear]![charmIndex] ?? 0;

    for (final gear in gearParts) {
      startLevels[gear]![charmIndex] = start;
      endLevels[gear]![charmIndex] = end;
      _prefs.setInt('${gear}_start_$charmIndex', start);
      _prefs.setInt('${gear}_end_$charmIndex', end);
    }
    _calculate();
    setState(() {});
    await _saveCloud();
  }

  void _calculate() {
    total = [0, 0, 0, 0];
    for (final gear in gearParts) {
      if (!_isPremium && _lockedGears.contains(gear)) continue;
      for (int i = 0; i < 3; i++) {
        final start = startLevels[gear]![i] ?? 0;
        final end = endLevels[gear]![i] ?? 0;
        if (start >= end || end > data.length) continue;

        // Materials
        for (int lvl = start + 1; lvl <= end; lvl++) {
          final idx = lvl - 1;
          for (int j = 0; j < 3; j++) {
            total[j] += data[idx][j];
          }
        }
        // Power delta: if starting from None (0), baseline power is 0
        if (start == 0) {
          total[3] += data[end - 1][3];
        } else {
          total[3] += data[end - 1][3] - data[start - 1][3];
        }
      }
    }
  }

  Future<void> _resetAll() async {
    for (final gear in gearParts) {
      for (int i = 0; i < 3; i++) {
        startLevels[gear]![i] = 0;
        endLevels[gear]![i] = 0;
        _prefs.setInt('${gear}_start_$i', 0);
        _prefs.setInt('${gear}_end_$i', 0);
      }
    }
    _calculate();
    setState(() => selectedGear = null);
    await _saveCloud();
  }

  // ---------- UI helpers ----------
  Color _getGearColor(String gear) {
    final list = startLevels[gear];
    if (list == null) return Colors.grey[300]!;
    int maxStart = list
        .where((e) => e != null)
        .fold(0, (p, v) => (v! > p ? v : p));
    if (maxStart >= 8) return Colors.amber[400]!;
    if (maxStart >= 5) return Colors.purple[300]!;
    if (maxStart >= 3) return Colors.blue[300]!;
    if (maxStart >= 1) return Colors.green[300]!;
    return Colors.grey[300]!;
  }

  Color _getCharmColor(int level) {
    if (level >= 8) return Colors.amber[400]!;
    if (level >= 5) return Colors.purple[300]!;
    if (level >= 3) return Colors.blue[300]!;
    if (level >= 1) return Colors.green[300]!;
    return Colors.transparent;
  }

  Widget _gearButton(String gear) {
    final bool isSelected = selectedGear == gear;
    final List<int?> starts = startLevels[gear] ?? [0, 0, 0];
    final Color tierColor = _getGearColor(gear);
    final locked = !_isPremium && _lockedGears.contains(gear);

    final charmStars = starts
        .where((v) => (v ?? 0) > 0)
        .map(
          (v) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _getCharmColor(v!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "★",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
        .toList();

    return GestureDetector(
      onTap: locked
          ? () => _showUpgradeDialog()
          : () => setState(() => selectedGear = isSelected ? null : gear),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tierColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    gear,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: locked ? Colors.white70 : null,
                    ),
                  ),
                ),
                if (locked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white70,
                        size: 34,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (charmStars.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: charmStars,
              ),
            ),
        ],
      ),
    );
  }

  void _ensureGearInitialized(String gear) {
    startLevels[gear] ??= [0, 0, 0];
    endLevels[gear] ??= [0, 0, 0];
  }

  Widget _gearPopup(String gear) {
    if (!_isPremium && _lockedGears.contains(gear)) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Text(
            '$gear is Premium',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: _showUpgradeDialog,
            child: const Text('Upgrade to Unlock'),
          ),
        ],
      );
    }
    _ensureGearInitialized(gear);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => selectedGear = null),
            child: const Text("Hide"),
          ),
        ),
        ...List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charmLabels[i],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: startLevels[gear]![i],
                        items: levels
                            .map(
                              (lvl) => DropdownMenuItem(
                                value: lvl,
                                child: Text(lvl == 0 ? "None" : "Start: $lvl"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => _onLevelChanged(gear, i, true, val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: endLevels[gear]![i],
                        items: levels
                            .map(
                              (lvl) => DropdownMenuItem(
                                value: lvl,
                                child: Text(lvl == 0 ? "None" : "End: $lvl"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            _onLevelChanged(gear, i, false, val),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _applyToAll(gear, i),
                    child: const Text("Apply to All"),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###');
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
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: gearParts
                            .map(
                              (gear) => SizedBox(
                                width: 90,
                                child: Column(children: [_gearButton(gear)]),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      if (selectedGear != null) _gearPopup(selectedGear!),
                      const SizedBox(height: 20),
                      const Text(
                        "Stat Bonuses",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Power Gain: ${f.format(total[3])}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Enhancement Cost",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text("Charm Guide"),
                              Text(f.format(total[0])),
                            ],
                          ),
                          Column(
                            children: [
                              const Text("Charm Design"),
                              Text(f.format(total[1])),
                            ],
                          ),
                          Column(
                            children: [
                              const Text("Jewel Secrets"),
                              Text(f.format(total[2])),
                            ],
                          ),
                        ],
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
                      onPressed: _resetAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
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

  void _showUpgradeDialog() {
    if (!PurchaseService.isPremium) {
      PaywallHelper.show(context);
      return; // stop locked action
    }
  }

  @override
  void dispose() {
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
