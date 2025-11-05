import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/cloud_sync_service.dart';
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

/// =====================
///  REUSABLE STAT TILE
/// =====================
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? emoji;
  final bool emphasis;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.emoji,
    this.emphasis = false,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasis ? const Color(0xFFFFFAEC) : Colors.white;
    final border = emphasis ? const Color(0xFFFFE7A8) : const Color(0x1A000000);

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final NumberFormat _fmt = NumberFormat('#,###');
String fmtInt(num n) => _fmt.format(n);

class FurnaceStatsSection extends StatelessWidget {
  final int wood;
  final int meat;
  final int coal;
  final int iron;
  final String totalTime;
  final String rawTime;

  const FurnaceStatsSection({
    super.key,
    required this.wood,
    required this.meat,
    required this.coal,
    required this.iron,
    required this.totalTime,
    required this.rawTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StatTile(label: 'Wood', value: fmtInt(wood)),
        StatTile(label: 'Meat', value: fmtInt(meat)),
        StatTile(label: 'Coal', value: fmtInt(coal)),
        StatTile(label: 'Iron', value: fmtInt(iron)),
        const SizedBox(height: 6),
        StatTile(
          label: 'Total Construction Time',
          value: totalTime,
          emphasis: true,
        ),
        StatTile(label: 'Without Speed Bonus', value: rawTime),
      ],
    );
  }
}

class FurnaceBuildingCalculatorPage extends StatefulWidget {
  const FurnaceBuildingCalculatorPage({super.key});

  @override
  FurnaceBuildingCalculatorPageState createState() =>
      FurnaceBuildingCalculatorPageState();
}

class FurnaceBuildingCalculatorPageState
    extends State<FurnaceBuildingCalculatorPage> {
  int _startLevel = 2;
  int _endLevel = 30;
  double _constructionSpeedBonus = 0.0;
  final TextEditingController _speedController = TextEditingController();

  final List<Map<String, dynamic>> _levels = [
    {
      "level": 2,
      "wood": 180,
      "coal": 0,
      "iron": 0,
      "meat": 0,
      "time": "0d 0h 0m 6s",
    },
    {
      "level": 3,
      "wood": 805,
      "coal": 0,
      "iron": 0,
      "meat": 0,
      "time": "0d 0h 1m",
    },
    {
      "level": 4,
      "wood": 1800,
      "coal": 360,
      "iron": 0,
      "meat": 0,
      "time": "0d 0h 3m",
    },
    {
      "level": 5,
      "wood": 7600,
      "coal": 1500,
      "iron": 0,
      "meat": 0,
      "time": "0d 0h 10m",
    },
    {
      "level": 6,
      "wood": 19000,
      "coal": 3800,
      "iron": 960,
      "meat": 0,
      "time": "0d 0h 30m",
    },
    {
      "level": 7,
      "wood": 69000,
      "coal": 13000,
      "iron": 3400,
      "meat": 0,
      "time": "0d 1h 0m",
    },
    {
      "level": 8,
      "wood": 120000,
      "coal": 25000,
      "iron": 6300,
      "meat": 0,
      "time": "0d 2h 30m",
    },
    {
      "level": 9,
      "wood": 260000,
      "coal": 52000,
      "iron": 13000,
      "meat": 0,
      "time": "0d 4h 30m",
    },
    {
      "level": 10,
      "wood": 460000,
      "coal": 92000,
      "iron": 23000,
      "meat": 0,
      "time": "0d 6h 0m",
    },
    {
      "level": 11,
      "wood": 1300000,
      "coal": 260000,
      "iron": 65000,
      "meat": 1300000,
      "time": "0d 7h 30m",
    },
    {
      "level": 12,
      "wood": 1600000,
      "coal": 330000,
      "iron": 84000,
      "meat": 1600000,
      "time": "0d 9h 0m",
    },
    {
      "level": 13,
      "wood": 2300000,
      "coal": 470000,
      "iron": 110000,
      "meat": 2300000,
      "time": "0d 11h 0m",
    },
    {
      "level": 14,
      "wood": 3100000,
      "coal": 630000,
      "iron": 150000,
      "meat": 3100000,
      "time": "0d 14h 0m",
    },
    {
      "level": 15,
      "wood": 4600000,
      "coal": 930000,
      "iron": 230000,
      "meat": 4600000,
      "time": "0d 18h 0m",
    },
    {
      "level": 16,
      "wood": 5900000,
      "coal": 1100000,
      "iron": 290000,
      "meat": 5900000,
      "time": "1d 6h 28m",
    },
    {
      "level": 17,
      "wood": 9300000,
      "coal": 1800000,
      "iron": 460000,
      "meat": 9300000,
      "time": "1d 12h 34m",
    },
    {
      "level": 18,
      "wood": 12000000,
      "coal": 2500000,
      "iron": 620000,
      "meat": 12000000,
      "time": "1d 19h 53m",
    },
    {
      "level": 19,
      "wood": 15000000,
      "coal": 3100000,
      "iron": 780000,
      "meat": 15000000,
      "time": "2d 17h 50m",
    },
    {
      "level": 20,
      "wood": 21000000,
      "coal": 4300000,
      "iron": 1000000,
      "meat": 21000000,
      "time": "3d 10h 18m",
    },
    {
      "level": 21,
      "wood": 27000000,
      "coal": 5400000,
      "iron": 1300000,
      "meat": 27000000,
      "time": "4d 10h 59m",
    },
    {
      "level": 22,
      "wood": 36000000,
      "coal": 7200000,
      "iron": 1800000,
      "meat": 36000000,
      "time": "6d 16h 29m",
    },
    {
      "level": 23,
      "wood": 44000000,
      "coal": 8900000,
      "iron": 2200000,
      "meat": 44000000,
      "time": "9d 8h 40m",
    },
    {
      "level": 24,
      "wood": 60000000,
      "coal": 12000000,
      "iron": 3000000,
      "meat": 60000000,
      "time": "13d 2h 33m",
    },
    {
      "level": 25,
      "wood": 81000000,
      "coal": 16000000,
      "iron": 4000000,
      "meat": 81000000,
      "time": "18d 8h 22m",
    },
    {
      "level": 26,
      "wood": 100000000,
      "coal": 21000000,
      "iron": 5200000,
      "meat": 100000000,
      "time": "21d 2h 26m",
    },
    {
      "level": 27,
      "wood": 140000000,
      "coal": 24000000,
      "iron": 7400000,
      "meat": 140000000,
      "time": "25d 7h 43m",
    },
    {
      "level": 28,
      "wood": 190000000,
      "coal": 39000000,
      "iron": 9900000,
      "meat": 190000000,
      "time": "29d 2h 52m",
    },
    {
      "level": 29,
      "wood": 240000000,
      "coal": 49000000,
      "iron": 12000000,
      "meat": 240000000,
      "time": "33d 11h 42m",
    },
    {
      "level": 30,
      "wood": 300000000,
      "coal": 60000000,
      "iron": 15000000,
      "meat": 300000000,
      "time": "40d 4h 27m",
    },
  ];

  // --- Cloud Sync ---
  Future<void> saveCloud() async {
    await CloudSyncService.save('furnace_building_calculator', {
      'startLevel': _startLevel,
      'endLevel': _endLevel,
      'constructionSpeedBonus': _constructionSpeedBonus,
    });
  }

  Future<void> loadCloud() async {
    final data = await CloudSyncService.load('furnace_building_calculator');
    if (data == null || !mounted) return;
    setState(() {
      _startLevel = data['startLevel'] ?? _startLevel;
      _endLevel = data['endLevel'] ?? _endLevel;
      _constructionSpeedBonus = (data['constructionSpeedBonus'] ?? 0.0)
          .toDouble();
      _speedController.text = _constructionSpeedBonus.toString();
    });
  }

  Future<void> loadLevels() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startLevel = prefs.getInt('furnace_start') ?? 2;
      _endLevel = prefs.getInt('furnace_end') ?? 30;
      _speedController.text = (prefs.getDouble('furnace_speed_bonus') ?? 0)
          .toString();
      _constructionSpeedBonus = double.tryParse(_speedController.text) ?? 0.0;
    });
    saveCloud();
  }

  Future<void> saveLevels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('furnace_start', _startLevel);
    await prefs.setInt('furnace_end', _endLevel);
    await prefs.setDouble('furnace_speed_bonus', _constructionSpeedBonus);
    saveCloud();
  }

  @override
  void initState() {
    super.initState();
    loadLevels();
    loadCloud();
    Timer.periodic(const Duration(seconds: 60), (_) => saveCloud());
    Future.delayed(const Duration(seconds: 2), saveCloud);
  }

  // Removed legacy upgrade dialog; paywall handled via PaywallHelper.show.

  String formatDuration(Duration d) {
    int days = d.inDays;
    int hours = d.inHours % 24;
    int minutes = d.inMinutes % 60;
    int seconds = d.inSeconds % 60;
    String result = '';
    if (days > 0) result += '${days}d ';
    if (hours > 0 || days > 0) result += '${hours}h ';
    if (minutes > 0 || hours > 0 || days > 0) result += '${minutes}m ';
    result += '${seconds}s';
    return result.trim();
  }

  Map<String, dynamic> calculateTotals() {
    int wood = 0, meat = 0, coal = 0, iron = 0;
    Duration totalTime = Duration.zero;
    Duration originalTime = Duration.zero;

    for (var level in _levels) {
      int lvl = level["level"];
      if (lvl > _startLevel && lvl <= _endLevel) {
        wood += ((level["wood"] ?? 0) as num).toInt();
        meat += ((level["meat"] ?? 0) as num).toInt();
        coal += ((level["coal"] ?? 0) as num).toInt();
        iron += ((level["iron"] ?? 0) as num).toInt();

        // Parse time string to Duration
        String timeStr = level["time"];
        RegExp reg = RegExp(r'(?:(\d+)d )?(?:(\d+)h )?(?:(\d+)m )?(?:(\d+)s)?');
        Match? match = reg.firstMatch(timeStr);
        int days = int.tryParse(match?.group(1) ?? '0') ?? 0;
        int hours = int.tryParse(match?.group(2) ?? '0') ?? 0;
        int minutes = int.tryParse(match?.group(3) ?? '0') ?? 0;
        int seconds = int.tryParse(match?.group(4) ?? '0') ?? 0;
        Duration d = Duration(
          days: days,
          hours: hours,
          minutes: minutes,
          seconds: seconds,
        );
        originalTime += d;
      }
    }

    double speedBonus = _constructionSpeedBonus;
    if (speedBonus > 0) {
      totalTime = Duration(
        seconds: (originalTime.inSeconds / (1 + speedBonus / 100)).round(),
      );
    } else {
      totalTime = originalTime;
    }

    return {
      "wood": wood,
      "meat": meat,
      "coal": coal,
      "iron": iron,
      "totalTime": totalTime,
      "originalTime": originalTime,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totals = calculateTotals();
    final Duration adjusted = totals["totalTime"];
    final Duration original = totals["originalTime"];

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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text("Start Level")),
                          DropdownButton<int>(
                            value: _startLevel,
                            items: List.generate(29, (i) => i + 2).map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(level.toString()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _startLevel = val!);
                              saveLevels();
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(child: Text("Desired Level")),
                          DropdownButton<int>(
                            value: _endLevel,
                            items: List.generate(29, (i) => i + 2).map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(level.toString()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _endLevel = val!);
                              saveLevels();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _speedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Construction Speed Bonus (%)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _constructionSpeedBonus =
                                double.tryParse(value) ?? 0.0;
                            saveLevels();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      FurnaceStatsSection(
                        wood: totals["wood"],
                        meat: totals["meat"],
                        coal: totals["coal"],
                        iron: totals["iron"],
                        totalTime: formatDuration(adjusted),
                        rawTime: formatDuration(original),
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
                        await saveCloud();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to cloud')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _startLevel = 2;
                          _endLevel = 30;
                          _constructionSpeedBonus = 0.0;
                          _speedController.text = '0.0';
                        });
                        await saveLevels();
                        await saveCloud();
                      },
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

