import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../survival_planner_calculator/bottom_nav_bar.dart';
import '../services/cloud_sync_service.dart';
import '../services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../survival_planner_calculator/utc_badge.dart';
import '../survival_planner_calculator/settings_page.dart';
import '../services/loginscreen.dart';
import '../survival_planner_calculator/web_landing.dart';
import '../survival_planner_calculator/chief_page.dart';
import '../survival_planner_calculator/hero_page.dart';
import '../survival_planner_calculator/building_page.dart';
import '../survival_planner_calculator/event_page.dart';
import '../survival_planner_calculator/troops_page.dart';

class FurnaceBuildingCalculatorPage extends StatefulWidget {
  final void Function(int crystals, int days)? onCalculate;

  const FurnaceBuildingCalculatorPage({super.key, this.onCalculate});

  @override
  State<FurnaceBuildingCalculatorPage> createState() =>
      _FurnaceBuildingCalculatorPageState();
}

class _FurnaceBuildingCalculatorPageState
    extends State<FurnaceBuildingCalculatorPage> {
  final NumberFormat _formatter = NumberFormat('#,###');

  int _currentLevel = 31;
  int _targetLevel = 32;

  String _resultText = '';
  bool _showResult = false;

  late SharedPreferences _prefs;
  double _constructionBonus = 0;

  Timer? _cloudTimer; // single periodic sync timer

  void _enforceFreeLimits() {
    // No premium limits on the web
  }

  // Level 31–40 data
  final Map<int, Map<String, int>> furnaceData = {
    31: {'crystals': 660, 'refined': 0, 'days': 35},
    32: {'crystals': 790, 'refined': 0, 'days': 45},
    33: {'crystals': 1190, 'refined': 0, 'days': 55},
    34: {'crystals': 1400, 'refined': 0, 'days': 65},
    35: {'crystals': 1675, 'refined': 0, 'days': 75},
    36: {'crystals': 1800, 'refined': 60, 'days': 85},
    37: {'crystals': 1950, 'refined': 90, 'days': 95},
    38: {'crystals': 2100, 'refined': 120, 'days': 105},
    39: {'crystals': 2250, 'refined': 180, 'days': 115},
    40: {'crystals': 2400, 'refined': 420, 'days': 125},
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('FurnaceBuildingCalculatorPage');
    _initPrefs();
    _loadBonus();
    _loadCloud();

    // Save once shortly after load, then every 60s
    Future.delayed(const Duration(seconds: 2), _saveCloud);
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    _enforceFreeLimits();
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLevel = _prefs.getInt('furnace_current_level') ?? 31;
    _targetLevel = _prefs.getInt('furnace_target_level') ?? 32;
    _enforceFreeLimits();
    if (mounted) setState(() {});
    _saveCloud();
  }

  Future<void> _loadBonus() async {
    final prefs = await SharedPreferences.getInstance();
    _constructionBonus =
        prefs.getDouble('fire_crystal_construction_bonus') ?? 0;
    if (mounted) setState(() {});
    _saveCloud();
  }

  Duration _adjustWithBonus(Duration base) {
    final adjustedSeconds = (base.inSeconds / (1 + _constructionBonus / 100))
        .round();
    return Duration(seconds: adjustedSeconds);
  }

  Future<void> _calculateAndSave() async {
    _prefs.setInt('furnace_current_level', _currentLevel);
    _prefs.setInt('furnace_target_level', _targetLevel);
    // Always reload the latest construction bonus before calculating
    final prefs = await SharedPreferences.getInstance();
    _constructionBonus =
        prefs.getDouble('fire_crystal_construction_bonus') ?? 0;
    _enforceFreeLimits();
    _calculateUpgrade();
    setState(() => _showResult = true);
    _saveCloud();
  }

  // ---------- Cloud Sync ----------
  Future<void> _saveCloud() async {
    await CloudSyncService.save('furnace_building_calculator', {
      'currentLevel': _currentLevel,
      'targetLevel': _targetLevel,
      'constructionBonus': _constructionBonus,
      'resultText': _resultText,
      'showResult': _showResult,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('furnace_building_calculator');
    if (data == null || !mounted) return;

    setState(() {
      _currentLevel = (data['currentLevel'] ?? _currentLevel) as int;
      _targetLevel = (data['targetLevel'] ?? _targetLevel) as int;
      final bonusRaw = data['constructionBonus'] ?? _constructionBonus;
      _constructionBonus = bonusRaw is num
          ? bonusRaw.toDouble()
          : _constructionBonus;
      if (data['resultText'] is String) _resultText = data['resultText'];
      if (data['showResult'] is bool) _showResult = data['showResult'];
      _enforceFreeLimits();
    });
  }

  void _calculateUpgrade() {
    if (_targetLevel <= _currentLevel) {
      _resultText = 'Target level must be higher than current level.';
      return;
    }

    int totalCrystals = 0;
    int totalRefinedCrystals = 0;
    int totalDays = 0;

    for (int level = _currentLevel + 1; level <= _targetLevel; level++) {
      final data = furnaceData[level];
      if (data != null) {
        totalCrystals += data['crystals'] ?? 0;
        totalRefinedCrystals += data['refined'] ?? 0;
        totalDays += data['days'] ?? 0;
      }
    }

    widget.onCalculate?.call(totalCrystals, totalDays);

    final adjustedDays = _adjustWithBonus(Duration(days: totalDays)).inDays;

    _resultText =
        '''
To upgrade from level $_currentLevel to $_targetLevel you need:
• ${_formatter.format(totalCrystals)} Fire Crystals
• ${_formatter.format(totalRefinedCrystals)} Refined Fire Crystals
• $totalDays days total upgrade time
• With Construction Bonus ${_constructionBonus.toStringAsFixed(1)}% → $adjustedDays days
''';
  }

  Widget _buildImageSelector(
    String label,
    int selectedLevel,
    ValueChanged<int> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10, // levels 31..40
            itemBuilder: (context, index) {
              final level = 31 + index;
              final imagePath = 'lib/assets/firecrystals/fc${index + 1}.png';
              final isSelected = selectedLevel == level;

              return GestureDetector(
                onTap: () async {
                  setState(() {
                    if (label.contains('Current')) {
                      onSelect(level);
                      if (_targetLevel <= level) _targetLevel = level + 1;
                    } else {
                      onSelect(level);
                      if (level <= _currentLevel) {
                        _targetLevel = _currentLevel + 1;
                      }
                    }
                    _enforceFreeLimits();
                    _showResult = false; // hide stale result
                  });
                  _saveCloud();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(imagePath, width: 60),
                ),
              );
            },
          ),
        ),
      ],
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Furnace • Fire Crystal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildImageSelector('Current Level:', _currentLevel, (level) {
                    _currentLevel = level;
                    setState(() {});
                    _saveCloud();
                  }),
                  const SizedBox(height: 16),
                  _buildImageSelector('Target Level:', _targetLevel, (level) {
                    _targetLevel = level;
                    setState(() {});
                    _saveCloud();
                  }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _calculateAndSave,
                    child: const Text('Calculate'),
                  ),
                  const SizedBox(height: 24),
                  if (_showResult)
                    Text(_resultText, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
      bottomSheet: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Save to Cloud'),
              onPressed: () async {
                final session = Supabase.instance.client.auth.currentSession;
                if (session == null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  setState(() {});
                  return;
                }
                await _saveCloud();
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saved to cloud')));
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              onPressed: () async {
                setState(() {
                  _currentLevel = 31;
                  _targetLevel = 32;
                  _resultText = '';
                  _showResult = false;
                });
                await _saveCloud();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            const Text('Fire Crystal Furnace'),
          ],
        ),
      ),
    );
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
