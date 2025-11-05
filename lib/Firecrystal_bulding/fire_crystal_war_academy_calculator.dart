import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../services/cloud_sync_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class FireCrystalWarAcademyCalculatorPage extends StatefulWidget {
  final void Function(int crystals, int days)? onCalculate;

  const FireCrystalWarAcademyCalculatorPage({super.key, this.onCalculate});

  @override
  State<FireCrystalWarAcademyCalculatorPage> createState() =>
      _FireCrystalWarAcademyCalculatorPageState();
}

class _FireCrystalWarAcademyCalculatorPageState
    extends State<FireCrystalWarAcademyCalculatorPage> {
  final NumberFormat _formatter = NumberFormat('#,###');
  final Map<String, int> _currentLevels = {'War Academy': 1};
  final Map<String, int> _targetLevels = {'War Academy': 2};
  final Map<String, String> _resultsPerCamp = {'War Academy': ''};
  String _grandTotalText = '';
  String _resourceText = '';
  bool _showResult = false;
  bool _showResources = false;
  Timer? _cloudTimer;

  double _constructionBonus = 0;
  void _enforceFreeLimits() {
    // No premium limits on the web
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('FireCrystalWarAcademyCalculatorPage');
    _loadCloud();
    _loadBonus();
    _updateCampTotals(null);
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    Future.delayed(const Duration(seconds: 2), _saveCloud);
    _enforceFreeLimits();
  }

  Future<void> _loadBonus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _constructionBonus =
          prefs.getDouble('fire_crystal_construction_bonus') ?? 0;
    });
  }

  Duration _adjustWithBonus(Duration base) {
    final adjustedSeconds = (base.inSeconds / (1 + _constructionBonus / 100))
        .round();
    return Duration(seconds: adjustedSeconds);
  }

  // --- Cloud Sync ---
  Future<void> _saveCloud() async {
    await CloudSyncService.save('fire_crystal_war_academy_calculator', {
      'currentLevels': _currentLevels,
      'targetLevels': _targetLevels,
      'grandTotalText': _grandTotalText,
      'resourceText': _resourceText,
      'constructionBonus': _constructionBonus,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load(
      'fire_crystal_war_academy_calculator',
    );
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
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    super.dispose();
  }

  final Map<int, Map<String, int>> campData = {
    1: {
      'meat': 0,
      'wood': 0,
      'coal': 0,
      'iron': 0,
      'fc': 0,
      'rfc': 0,
      'days': 0,
      'hours': 0,
      'minutes': 2,
    },
    2: {
      'meat': 180000000,
      'wood': 180000000,
      'coal': 36000000,
      'iron': 9000000,
      'fc': 355,
      'rfc': 0,
      'days': 9,
      'hours': 0,
      'minutes': 0,
    },
    3: {
      'meat': 195000000,
      'wood': 195000000,
      'coal': 39500000,
      'iron': 9500000,
      'fc': 535,
      'rfc': 0,
      'days': 11,
      'hours': 0,
      'minutes': 0,
    },
    4: {
      'meat': 205000000,
      'wood': 205000000,
      'coal': 41000000,
      'iron': 10000000,
      'fc': 640,
      'rfc': 0,
      'days': 12,
      'hours': 0,
      'minutes': 0,
    },
    5: {
      'meat': 210000000,
      'wood': 210000000,
      'coal': 41000000,
      'iron': 10500000,
      'fc': 750,
      'rfc': 0,
      'days': 14,
      'hours': 0,
      'minutes': 0,
    },
    6: {
      'meat': 240000000,
      'wood': 240000000,
      'coal': 48000000,
      'iron': 12000000,
      'fc': 405,
      'rfc': 25,
      'days': 15,
      'hours': 0,
      'minutes': 0,
    },
    7: {
      'meat': 270000000,
      'wood': 270000000,
      'coal': 50000000,
      'iron': 13500000,
      'fc': 486,
      'rfc': 37,
      'days': 18,
      'hours': 0,
      'minutes': 0,
    },
    8: {
      'meat': 330000000,
      'wood': 330000000,
      'coal': 65000000,
      'iron': 16500000,
      'fc': 540,
      'rfc': 45,
      'days': 20,
      'hours': 0,
      'minutes': 0,
    },
    9: {
      'meat': 360000000,
      'wood': 360000000,
      'coal': 70000000,
      'iron': 18000000,
      'fc': 630,
      'rfc': 79,
      'days': 13,
      'hours': 0,
      'minutes': 0,
    },
    10: {
      'meat': 420000000,
      'wood': 420000000,
      'coal': 80000000,
      'iron': 36000000,
      'fc': 706,
      'rfc': 187,
      'days': 20,
      'hours': 0,
      'minutes': 0,
    },
  };

  void _updateCampTotals(String? onlyCamp) {
    final targets = onlyCamp == null ? _currentLevels.keys : [onlyCamp];
    for (var camp in targets) {
      _enforceFreeLimits();
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
      final bonusDuration = _adjustWithBonus(Duration(minutes: mins));
      final bd = bonusDuration.inDays,
          bh = bonusDuration.inHours % 24,
          bm = bonusDuration.inMinutes % 60;
      _resultsPerCamp[camp] =
          'Fire Crystal: ${_formatter.format(fc)}\n'
          '${rfc > 0 ? "Refined Fire Crystal: ${_formatter.format(rfc)}\n" : ""}'
          'Time: ${d}d ${h}h ${m}m'
          '\nWith Construction Bonus ${_constructionBonus.toStringAsFixed(1)}% → ${bd}d ${bh}h ${bm}m';
    }
    _saveCloud();
    setState(() {});
  }

  void _calculate() {
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
    final bonusDuration = _adjustWithBonus(Duration(minutes: gMins));
    final bd = bonusDuration.inDays,
        bh = bonusDuration.inHours % 24,
        bm = bonusDuration.inMinutes % 60;

    _grandTotalText =
        'Fire Crystal: ${_formatter.format(gFC)}\n'
        '${gRFC > 0 ? "Refined Fire Crystal: ${_formatter.format(gRFC)}\n" : ""}'
        'Time: ${gd}d ${gh}h ${gm}m'
        '\nWith Construction Bonus ${_constructionBonus.toStringAsFixed(1)}% → ${bd}d ${bh}h ${bm}m';

    _resourceText =
        'Meat: ${_formatter.format(gMeat)}\n'
        'Wood: ${_formatter.format(gWood)}\n'
        'Coal: ${_formatter.format(gCoal)}\n'
        'Iron: ${_formatter.format(gIron)}';

    widget.onCalculate?.call(gFC, gd);

    setState(() {
      _showResult = true;
      _showResources = false;
    });
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
            itemBuilder: (context, index) {
              final level = index + 1;
              final imagePath = 'lib/assets/firecrystals/fc${index + 1}.png';
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
        const SizedBox(height: 8),
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
                  if (_resultsPerCamp['War Academy']!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'War Academy',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  _buildCampSection('War Academy'),
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
                  _currentLevels['War Academy'] = 1;
                  _targetLevels['War Academy'] = 2;
                  _resultsPerCamp['War Academy'] = '';
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
            const Text('Fire Crystal War Academy'),
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
