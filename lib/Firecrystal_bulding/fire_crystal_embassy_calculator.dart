import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cloud_sync_service.dart';
import '../services/analytics_service.dart';
import '../survival_planner_calculator/utc_badge.dart';
import '../survival_planner_calculator/settings_page.dart';
import '../services/loginscreen.dart';
import '../survival_planner_calculator/bottom_nav_bar.dart';
import '../survival_planner_calculator/web_landing.dart';
import '../survival_planner_calculator/chief_page.dart';
import '../survival_planner_calculator/hero_page.dart';
import '../survival_planner_calculator/building_page.dart';
import '../survival_planner_calculator/event_page.dart';
import '../survival_planner_calculator/troops_page.dart';

class FireCrystalEmbassyCalculatorPage extends StatefulWidget {
  final void Function(int crystals, int days)? onCalculate;
  const FireCrystalEmbassyCalculatorPage({super.key, this.onCalculate});

  @override
  State<FireCrystalEmbassyCalculatorPage> createState() =>
      _FireCrystalEmbassyCalculatorPageState();
}

class _FireCrystalEmbassyCalculatorPageState
    extends State<FireCrystalEmbassyCalculatorPage> {
  final NumberFormat _formatter = NumberFormat('#,###');

  // Levels (single building: Embassy)
  final Map<String, int> _currentLevels = {'Embassy': 1};
  final Map<String, int> _targetLevels = {'Embassy': 2};
  final Map<String, String> _resultsPerCamp = {'Embassy': ''};

  String _grandTotalText = '';
  String _resourceText = '';
  bool _showResult = false;
  bool _showResources = false;

  double _constructionBonus = 0; // pulled from shared prefs
  Timer? _cloudTimer;

  final Map<int, Map<String, int>> campData = {
    1: {
      'meat': 65000000,
      'wood': 65000000,
      'coal': 13500000,
      'iron': 3395000,
      'fc': 165,
      'rfc': 0,
      'days': 30,
      'hours': 20,
      'minutes': 0,
    },
    2: {
      'meat': 70000000,
      'wood': 70000000,
      'coal': 14500000,
      'iron': 3950000,
      'fc': 195,
      'rfc': 0,
      'days': 29,
      'hours': 16,
      'minutes': 45,
    },
    3: {
      'meat': 75000000,
      'wood': 75000000,
      'coal': 15500000,
      'iron': 3950000,
      'fc': 295,
      'rfc': 0,
      'days': 36,
      'hours': 7,
      'minutes': 10,
    },
    4: {
      'meat': 80000000,
      'wood': 80000000,
      'coal': 16500000,
      'iron': 4200000,
      'fc': 350,
      'rfc': 0,
      'days': 46,
      'hours': 4,
      'minutes': 45,
    },
    5: {
      'meat': 80000000,
      'wood': 80000000,
      'coal': 16500000,
      'iron': 4200000,
      'fc': 415,
      'rfc': 0,
      'days': 46,
      'hours': 4,
      'minutes': 45,
    },
    6: {
      'meat': 95000000,
      'wood': 95000000,
      'coal': 19000000,
      'iron': 4800000,
      'fc': 225,
      'rfc': 13,
      'days': 49,
      'hours': 12,
      'minutes': 0,
    },
    7: {
      'meat': 105000000,
      'wood': 105000000,
      'coal': 21500000,
      'iron': 5000000,
      'fc': 270,
      'rfc': 19,
      'days': 59,
      'hours': 9,
      'minutes': 35,
    },
    8: {
      'meat': 130000000,
      'wood': 130000000,
      'coal': 26500000,
      'iron': 6500000,
      'fc': 270,
      'rfc': 30,
      'days': 66,
      'hours': 0,
      'minutes': 0,
    },
    9: {
      'meat': 145000000,
      'wood': 145000000,
      'coal': 29000000,
      'iron': 7000000,
      'fc': 262,
      'rfc': 77,
      'days': 42,
      'hours': 21,
      'minutes': 35,
    },
    10: {
      'meat': 165000000,
      'wood': 165000000,
      'coal': 33500000,
      'iron': 8000000,
      'fc': 391,
      'rfc': 103,
      'days': 66,
      'hours': 0,
      'minutes': 0,
    },
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('FireCrystalEmbassyCalculatorPage');
    _loadBonus();
    _loadCloud();
    _updateCampTotals(null);
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBonus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _constructionBonus =
          prefs.getDouble('fire_crystal_construction_bonus') ?? 0;
    });
    _enforceFreeLimits();
  }

  Duration _adjustWithBonus(Duration base) {
    final adjustedSeconds = (base.inSeconds / (1 + _constructionBonus / 100))
        .round();
    return Duration(seconds: adjustedSeconds);
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('fire_crystal_embassy_calculator');
    if (data == null || !mounted) return;
    setState(() {
      if (data['currentLevels'] != null) {
        _currentLevels.addAll(Map<String, int>.from(data['currentLevels']));
      }
      if (data['targetLevels'] != null) {
        _targetLevels.addAll(Map<String, int>.from(data['targetLevels']));
      }
      if (data['grandTotalText'] is String) {
        _grandTotalText = data['grandTotalText'];
        _showResult = _grandTotalText.isNotEmpty;
      }
      if (data['resourceText'] is String) {
        _resourceText = data['resourceText'];
      }
    });
    _enforceFreeLimits();
    _updateCampTotals(null);
  }

  Future<void> _saveCloud() async {
    await CloudSyncService.save('fire_crystal_embassy_calculator', {
      'currentLevels': _currentLevels,
      'targetLevels': _targetLevels,
      'grandTotalText': _grandTotalText,
      'resourceText': _resourceText,
      'constructionBonus': _constructionBonus,
    });
  }

  void _updateCampTotals(String? onlyCamp) {
    final targets = onlyCamp == null ? _currentLevels.keys : [onlyCamp];
    for (var camp in targets) {
      int fc = 0, rfc = 0, mins = 0;
      int start = _currentLevels[camp]! + 1;
      int end = _targetLevels[camp]!;
      for (int i = start; i <= end; i++) {
        final data = campData[i]!;
        fc += data['fc']!;
        rfc += data['rfc']!;
        mins +=
            (data['days']! * 1440) + (data['hours']! * 60) + data['minutes']!;
      }
      final d = mins ~/ 1440, h = (mins % 1440) ~/ 60, m = mins % 60;
      final adjusted = _adjustWithBonus(Duration(minutes: mins));
      final ad = adjusted.inDays,
          ah = adjusted.inHours % 24,
          am = adjusted.inMinutes % 60;
      _resultsPerCamp[camp] =
          'Fire Crystal: ${_formatter.format(fc)}\n'
          '${rfc > 0 ? "Refined Fire Crystal: ${_formatter.format(rfc)}\n" : ""}'
          'Time: ${d}d ${h}h ${m}m\n'
          'With Construction Bonus ${_constructionBonus.toStringAsFixed(1)}% → ${ad}d ${ah}h ${am}m';
    }
    _saveCloud();
    setState(() {});
  }

  Future<void> _calculate() async {
    await _loadBonus();
    int gMeat = 0,
        gWood = 0,
        gCoal = 0,
        gIron = 0,
        gFC = 0,
        gRFC = 0,
        gMins = 0;

    for (var camp in _currentLevels.keys) {
      int start = _currentLevels[camp]! + 1;
      int end = _targetLevels[camp]!;
      for (int i = start; i <= end; i++) {
        final data = campData[i]!;
        gMeat += data['meat']!;
        gWood += data['wood']!;
        gCoal += data['coal']!;
        gIron += data['iron']!;
        gFC += data['fc']!;
        gRFC += data['rfc']!;
        gMins +=
            (data['days']! * 1440) + (data['hours']! * 60) + data['minutes']!;
      }
    }

    final gd = gMins ~/ 1440, gh = (gMins % 1440) ~/ 60, gm = gMins % 60;
    final adjusted = _adjustWithBonus(Duration(minutes: gMins));
    final ad = adjusted.inDays,
        ah = adjusted.inHours % 24,
        am = adjusted.inMinutes % 60;

    setState(() {
      _grandTotalText =
          'Fire Crystal: ${_formatter.format(gFC)}\n'
          '${gRFC > 0 ? "Refined Fire Crystal: ${_formatter.format(gRFC)}\n" : ""}'
          'Time: ${gd}d ${gh}h ${gm}m\n'
          'With Construction Bonus ${_constructionBonus.toStringAsFixed(1)}% → ${ad}d ${ah}h ${am}m';

      _resourceText =
          'Meat: ${_formatter.format(gMeat)}\n'
          'Wood: ${_formatter.format(gWood)}\n'
          'Coal: ${_formatter.format(gCoal)}\n'
          'Iron: ${_formatter.format(gIron)}';
      _showResult = true;
      _showResources = false;
    });

    widget.onCalculate?.call(gFC, gd);
    _saveCloud();
  }

  Widget _buildImageSelector(String label, String camp, bool isCurrent) {
    int selected = isCurrent ? _currentLevels[camp]! : _targetLevels[camp]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, idx) {
              final level = idx + 1;
              final imagePath = 'lib/assets/firecrystals/fc$level.png';
              return GestureDetector(
                onTap: () async {
                  setState(() {
                    if (isCurrent) {
                      _currentLevels[camp] = level;
                      if (_targetLevels[camp]! <= level) {
                        _targetLevels[camp] = level + 1;
                      }
                    } else {
                      _targetLevels[camp] = level;
                      if (level <= _currentLevels[camp]!) {
                        _targetLevels[camp] = _currentLevels[camp]! + 1;
                      }
                    }
                    _enforceFreeLimits();
                    _updateCampTotals(camp);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected == level
                          ? Colors.blueAccent
                          : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(imagePath, width: 50),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCampSection(String camp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSelector('Current Level:', camp, true),
        const SizedBox(height: 8),
        _buildImageSelector('Target Level:', camp, false),
        if (_resultsPerCamp[camp]!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _resultsPerCamp[camp]!,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _enforceFreeLimits() {
    // No premium limits on the web
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCampSection('Embassy'),
                  ElevatedButton(
                    onPressed: _calculate,
                    child: const Text('Calculate Total'),
                  ),
                  if (_showResult)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[200],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _grandTotalText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showResources = !_showResources;
                              });
                            },
                            child: Text(
                              _showResources
                                  ? 'Hide Resources'
                                  : 'Show Resources',
                            ),
                          ),
                          if (_showResources)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _resourceText,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                  _currentLevels['Embassy'] = 1;
                  _targetLevels['Embassy'] = 2;
                  _resultsPerCamp['Embassy'] = '';
                  _grandTotalText = '';
                  _resourceText = '';
                  _showResult = false;
                  _showResources = false;
                });
                await _saveCloud();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            const Text('Fire Crystal Embassy'),
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
