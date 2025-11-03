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

class FireCrystalCommandCentreCalculatorPage extends StatefulWidget {
  const FireCrystalCommandCentreCalculatorPage({super.key, this.onCalculate});
  final void Function(int crystals, int days)? onCalculate;

  @override
  State<FireCrystalCommandCentreCalculatorPage> createState() =>
      _CommandCentreCalculatorPageState();
}

class _CommandCentreCalculatorPageState
    extends State<FireCrystalCommandCentreCalculatorPage> {
  final NumberFormat _formatter = NumberFormat('#,###');
  final Map<String, int> _currentLevels = {'Command Centre': 1};
  final Map<String, int> _targetLevels = {'Command Centre': 2};
  final Map<String, String> _resultsPerCamp = {'Command Centre': ''};
  String _grandTotalText = '';
  String _resourceText = '';
  bool _showResult = false;
  bool _showResources = false;
  double _constructionBonus = 0;
  Timer? _cloudTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('FireCrystalCommandCentreCalculatorPage');
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
  }

  Duration _adjustWithBonus(Duration base) {
    final adjustedSeconds = (base.inSeconds / (1 + _constructionBonus / 100))
        .round();
    return Duration(seconds: adjustedSeconds);
  }

  // --- Cloud Sync ---
  Future<void> _saveCloud() async {
    await CloudSyncService.save('fire_crystal_command_calculator', {
      'currentLevels': _currentLevels,
      'targetLevels': _targetLevels,
      'grandTotalText': _grandTotalText,
      'resourceText': _resourceText,
      'constructionBonus': _constructionBonus,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('fire_crystal_command_calculator');
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
      final bonus = data['constructionBonus'];
      if (bonus is num) _constructionBonus = bonus.toDouble();
    });
  }

  final Map<int, Map<String, int>> campData = {
    1: {
      'meat': 100000000,
      'wood': 100000000,
      'coal': 20000000,
      'iron': 5000000,
      'fc': 140,
      'rfc': 0,
      'days': 4,
      'hours': 4,
      'minutes': 45,
    },
    2: {
      'meat': 105000000,
      'wood': 105000000,
      'coal': 21500000,
      'iron': 5000000,
      'fc': 155,
      'rfc': 0,
      'days': 16,
      'hours': 11,
      'minutes': 0,
    },
    3: {
      'meat': 115000000,
      'wood': 115000000,
      'coal': 23500000,
      'iron': 5500000,
      'fc': 235,
      'rfc': 0,
      'days': 6,
      'hours': 14,
      'minutes': 20,
    },
    4: {
      'meat': 120000000,
      'wood': 120000000,
      'coal': 24500000,
      'iron': 6000000,
      'fc': 280,
      'rfc': 0,
      'days': 7,
      'hours': 4,
      'minutes': 45,
    },
    5: {
      'meat': 125000000,
      'wood': 125000000,
      'coal': 25000000,
      'iron': 6000000,
      'fc': 335,
      'rfc': 0,
      'days': 8,
      'hours': 10,
      'minutes': 35,
    },
    6: {
      'meat': 145000000,
      'wood': 145000000,
      'coal': 29000000,
      'iron': 7000000,
      'fc': 180,
      'rfc': 13,
      'days': 9,
      'hours': 0,
      'minutes': 0,
    },
    7: {
      'meat': 160000000,
      'wood': 160000000,
      'coal': 32500000,
      'iron': 7500000,
      'fc': 216,
      'rfc': 18,
      'days': 10,
      'hours': 7,
      'minutes': 30,
    },
    8: {
      'meat': 195000000,
      'wood': 195000000,
      'coal': 39500000,
      'iron': 9500000,
      'fc': 216,
      'rfc': 24,
      'days': 17,
      'hours': 12,
      'minutes': 0,
    },
    9: {
      'meat': 215000000,
      'wood': 215000000,
      'coal': 43500000,
      'iron': 10500000,
      'fc': 252,
      'rfc': 36,
      'days': 7,
      'hours': 19,
      'minutes': 10,
    },
    10: {
      'meat': 250000000,
      'wood': 250000000,
      'coal': 50000000,
      'iron': 12500000,
      'fc': 315,
      'rfc': 84,
      'days': 12,
      'hours': 0,
      'minutes': 0,
    },
  };

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
        _buildImageSelector('Current Level:', camp, true),
        const SizedBox(height: 8),
        _buildImageSelector('Target Level:', camp, false),
        const SizedBox(height: 8),
        Text(_resultsPerCamp[camp] ?? '', style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
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
                  _buildCampSection('Command Centre'),
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
                  _currentLevels['Command Centre'] = 1;
                  _targetLevels['Command Centre'] = 2;
                  _resultsPerCamp['Command Centre'] = '';
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
            const Text('Fire Crystal Command Centre'),
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
