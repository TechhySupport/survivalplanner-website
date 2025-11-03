import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloud_sync_service.dart';
import '../services/analytics_service.dart';
import '../utc_badge.dart';
import '../settings_page.dart';
import '../services/loginscreen.dart';
import '../bottom_nav_bar.dart';
import '../web/web_landing.dart';
import '../chief_page.dart';
import '../hero_page.dart';
import '../building_page.dart';
import '../event_page.dart';
import '../troops_page.dart';

class FireCrystalCampsCalculatorPage extends StatefulWidget {
  final void Function(int crystals, int days)? onCalculate;

  const FireCrystalCampsCalculatorPage({super.key, this.onCalculate});

  @override
  State<FireCrystalCampsCalculatorPage> createState() =>
      _FireCrystalCampsCalculatorPageState();
}

class _FireCrystalCampsCalculatorPageState
    extends State<FireCrystalCampsCalculatorPage> {
  final NumberFormat _formatter = NumberFormat('#,###');
  final Map<String, int> _currentLevels = {
    'Infantry': 1,
    'Marksmen': 1,
    'Lancers': 1,
  };
  final Map<String, int> _targetLevels = {
    'Infantry': 2,
    'Marksmen': 2,
    'Lancers': 2,
  };
  final Map<String, String> _resultsPerCamp = {
    'Infantry': '',
    'Marksmen': '',
    'Lancers': '',
  };
  String _grandTotalText = '';
  String _resourceText = '';
  bool _showResult = false;
  bool _showResources = false;

  double _constructionBonus = 0;
  Timer? _cloudTimer;

  final Map<int, Map<String, int>> campData = {
    1: {
      'meat': 115000000,
      'wood': 115000000,
      'coal': 23500000,
      'iron': 5500000,
      'fc': 295,
      'rfc': 0,
      'days': 5,
      'hours': 6,
      'minutes': 0,
    },
    2: {
      'meat': 125000000,
      'wood': 125000000,
      'coal': 25000000,
      'iron': 6000000,
      'fc': 355,
      'rfc': 0,
      'days': 6,
      'hours': 18,
      'minutes': 0,
    },
    3: {
      'meat': 135000000,
      'wood': 135000000,
      'coal': 27500000,
      'iron': 6500000,
      'fc': 535,
      'rfc': 0,
      'days': 8,
      'hours': 6,
      'minutes': 0,
    },
    4: {
      'meat': 140000000,
      'wood': 140000000,
      'coal': 28500000,
      'iron': 7000000,
      'fc': 630,
      'rfc': 0,
      'days': 9,
      'hours': 0,
      'minutes': 0,
    },
    5: {
      'meat': 145000000,
      'wood': 145000000,
      'coal': 29500000,
      'iron': 7000000,
      'fc': 750,
      'rfc': 0,
      'days': 10,
      'hours': 12,
      'minutes': 0,
    },
    6: {
      'meat': 150000000,
      'wood': 150000000,
      'coal': 30500000,
      'iron': 7500000,
      'fc': 405,
      'rfc': 25,
      'days': 11,
      'hours': 12,
      'minutes': 0,
    },
    7: {
      'meat': 160000000,
      'wood': 160000000,
      'coal': 31500000,
      'iron': 8000000,
      'fc': 486,
      'rfc': 33,
      'days': 13,
      'hours': 0,
      'minutes': 0,
    },
    8: {
      'meat': 165000000,
      'wood': 165000000,
      'coal': 32500000,
      'iron': 8500000,
      'fc': 486,
      'rfc': 55,
      'days': 14,
      'hours': 0,
      'minutes': 0,
    },
    9: {
      'meat': 170000000,
      'wood': 170000000,
      'coal': 33500000,
      'iron': 9000000,
      'fc': 576,
      'rfc': 79,
      'days': 15,
      'hours': 6,
      'minutes': 0,
    },
    10: {
      'meat': 175000000,
      'wood': 175000000,
      'coal': 34500000,
      'iron': 9500000,
      'fc': 706,
      'rfc': 187,
      'days': 16,
      'hours': 0,
      'minutes': 0,
    },
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('FireCrystalCampsCalculatorPage');
    _loadBonus();
    _updateCampTotals(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBonus();
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
          '''
Fire Crystal: ${_formatter.format(fc)}
${rfc > 0 ? "Refined Fire Crystal: ${_formatter.format(rfc)}\n" : ""}Time: ${d}d ${h}h ${m}m
With Construction Bonus ${_constructionBonus.toStringAsFixed(1)}% → ${ad}d ${ah}h ${am}m
''';
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
          '''
Fire Crystal: ${_formatter.format(gFC)}
${gRFC > 0 ? "Refined Fire Crystal: ${_formatter.format(gRFC)}\n" : ""}Time: ${gd}d ${gh}h ${gm}m
With Construction Bonus ${_constructionBonus.toStringAsFixed(1)}% → ${ad}d ${ah}h ${am}m
''';

      _resourceText =
          '''
Meat: ${_formatter.format(gMeat)}
Wood: ${_formatter.format(gWood)}
Coal: ${_formatter.format(gCoal)}
Iron: ${_formatter.format(gIron)}''';

      _showResult = true;
      _showResources = false;
    });

    widget.onCalculate?.call(gFC, gd);
    _saveCloud();
  }

  Future<void> _saveCloud() async {
    await CloudSyncService.save('fire_crystal_camps_calculator', {
      'currentLevels': _currentLevels,
      'targetLevels': _targetLevels,
      'constructionBonus': _constructionBonus,
      'resultsPerCamp': _resultsPerCamp,
      'grandTotalText': _grandTotalText,
      'resourceText': _resourceText,
    });
  }

  Widget _buildImageSelector(String label, String camp, bool isCurrent) {
    int selected = isCurrent ? _currentLevels[camp]! : _targetLevels[camp]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, idx) {
              int level = idx + 1;
              // Use the correct fire crystal asset path
              String imagePath = 'lib/assets/firecrystals/fc$level.png';
              // all levels unlocked on free site
              return GestureDetector(
                onTap: () async {
                  // no locking in free site
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
                child: Stack(
                  children: [
                    Container(
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
                  ],
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
  void dispose() {
    _cloudTimer?.cancel();
    super.dispose();
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
                  _buildCampSection('Infantry'),
                  _buildCampSection('Marksmen'),
                  _buildCampSection('Lancers'),
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
                  _currentLevels['Infantry'] = 1;
                  _currentLevels['Marksmen'] = 1;
                  _currentLevels['Lancers'] = 1;
                  _targetLevels['Infantry'] = 2;
                  _targetLevels['Marksmen'] = 2;
                  _targetLevels['Lancers'] = 2;
                  _resultsPerCamp.updateAll((key, value) => '');
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
            const Text('Fire Crystal Camps'),
          ],
        ),
      ),
    );
  }

  void _enforceFreeLimits() {
    // No limits in free site
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
