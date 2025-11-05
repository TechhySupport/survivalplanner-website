import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
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

/// =====================
///  REUSABLE STAT TILE (shared look)
/// =====================
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasis ? const Color(0xFFFFFAEC) : Colors.white;
    final border = emphasis ? const Color(0xFFFFE7A8) : const Color(0x1A000000);
    return Container(
      margin: margin,
      padding: padding,
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

class EmbassyStatsSection extends StatelessWidget {
  final int wood;
  final int meat;
  final int coal;
  final int iron;
  final String totalTime;
  final String rawTime;
  const EmbassyStatsSection({
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
    final fmt = NumberFormat('#,###');
    String fmtInt(num n) => fmt.format(n);
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

class EmbassyCalculatorPage extends StatefulWidget {
  const EmbassyCalculatorPage({super.key});

  @override
  _EmbassyCalculatorPageState createState() => _EmbassyCalculatorPageState();
}

class _EmbassyCalculatorPageState extends State<EmbassyCalculatorPage> {
  int _startLevel = 2;
  int _endLevel = 30;
  double _constructionSpeedBonus = 0.0;
  final TextEditingController _speedController = TextEditingController();

  final List<Map<String, dynamic>> _levels = [
    {'level': 1, 'wood': 60, 'meat': 0, 'coal': 0, 'iron': 0, 'time': '2s'},
    {'level': 2, 'wood': 90, 'meat': 0, 'coal': 0, 'iron': 0, 'time': '10s'},
    {'level': 3, 'wood': 400, 'meat': 0, 'coal': 0, 'iron': 0, 'time': '1m'},
    {'level': 4, 'wood': 900, 'meat': 0, 'coal': 180, 'iron': 0, 'time': '2m'},
    {
      'level': 5,
      'wood': 3800,
      'meat': 0,
      'coal': 760,
      'iron': 0,
      'time': '6m 40s',
    },
    {
      'level': 6,
      'wood': 9600,
      'meat': 0,
      'coal': 1900,
      'iron': 480,
      'time': '13m 20s',
    },
    {
      'level': 7,
      'wood': 34000,
      'meat': 0,
      'coal': 6900,
      'iron': 1700,
      'time': '25m',
    },
    {
      'level': 8,
      'wood': 63000,
      'meat': 0,
      'coal': 12000,
      'iron': 3100,
      'time': '45m',
    },
    {
      'level': 9,
      'wood': 130000,
      'meat': 0,
      'coal': 26000,
      'iron': 6500,
      'time': '2h',
    },
    {
      'level': 10,
      'wood': 230000,
      'meat': 0,
      'coal': 46000,
      'iron': 11000,
      'time': '3h 57m 30s',
    },
    {
      'level': 11,
      'wood': 260000,
      'meat': 260000,
      'coal': 52000,
      'iron': 13000,
      'time': '4h 57m',
    },
    {
      'level': 12,
      'wood': 330000,
      'meat': 330000,
      'coal': 67000,
      'iron': 16000,
      'time': '5h 56m',
    },
    {
      'level': 13,
      'wood': 470000,
      'meat': 470000,
      'coal': 95000,
      'iron': 23000,
      'time': '7h 15m 30s',
    },
    {
      'level': 14,
      'wood': 630000,
      'meat': 630000,
      'coal': 120000,
      'iron': 31000,
      'time': '9h 14m',
    },
    {
      'level': 15,
      'wood': 930000,
      'meat': 930000,
      'coal': 180000,
      'iron': 46000,
      'time': '11h 52m 30s',
    },
    {
      'level': 16,
      'wood': 1100000,
      'meat': 1100000,
      'coal': 230000,
      'iron': 59000,
      'time': '19h 43m 20s',
    },
    {
      'level': 17,
      'wood': 1800000,
      'meat': 1800000,
      'coal': 370000,
      'iron': 93000,
      'time': '1d 8m',
    },
    {
      'level': 18,
      'wood': 2500000,
      'meat': 2500000,
      'coal': 500000,
      'iron': 120000,
      'time': '1d 4h 58m',
    },
    {
      'level': 19,
      'wood': 3100000,
      'meat': 3100000,
      'coal': 620000,
      'iron': 150000,
      'time': '1d 19h 27m',
    },
    {
      'level': 20,
      'wood': 4300000,
      'meat': 4300000,
      'coal': 860000,
      'iron': 210000,
      'time': '2d 6h 19m',
    },
    {
      'level': 21,
      'wood': 5400000,
      'meat': 5400000,
      'coal': 1000000,
      'iron': 270000,
      'time': '2d 22h 36m',
    },
    {
      'level': 22,
      'wood': 7200000,
      'meat': 7200000,
      'coal': 1400000,
      'iron': 360000,
      'time': '4d 9h 55m',
    },
    {
      'level': 23,
      'wood': 8900000,
      'meat': 8900000,
      'coal': 1700000,
      'iron': 440000,
      'time': '6d 4h 17m',
    },
    {
      'level': 24,
      'wood': 12000000,
      'meat': 12000000,
      'coal': 2400000,
      'iron': 600000,
      'time': '8d 15h 36m',
    },
    {
      'level': 25,
      'wood': 16000000,
      'meat': 16000000,
      'coal': 3200000,
      'iron': 810000,
      'time': '12d 2h 38m',
    },
    {
      'level': 26,
      'wood': 21000000,
      'meat': 21000000,
      'coal': 4200000,
      'iron': 1000000,
      'time': '13d 22h 14m',
    },
    {
      'level': 27,
      'wood': 29000000,
      'meat': 29000000,
      'coal': 5900000,
      'iron': 1400000,
      'time': '16d 17h 5m',
    },
    {
      'level': 28,
      'wood': 39000000,
      'meat': 39000000,
      'coal': 7900000,
      'iron': 1900000,
      'time': '19d 5h 15m',
    },
    {
      'level': 29,
      'wood': 49000000,
      'meat': 49000000,
      'coal': 9800000,
      'iron': 2400000,
      'time': '22d 2h 26m',
    },
    {
      'level': 30,
      'wood': 60000000,
      'meat': 60000000,
      'coal': 12000000,
      'iron': 3000000,
      'time': '26d 12h 32m',
    },
  ];

  Timer? _cloudTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('EmbassyCalculatorPage');
    _loadLevels();
    _loadCloud();
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  // Removed legacy upgrade dialog; using PaywallHelper.show(context).

  Future<void> _loadLevels() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startLevel = prefs.getInt('embassy_start') ?? 2;
      _endLevel = prefs.getInt('embassy_end') ?? 30;
      _speedController.text = (prefs.getDouble('embassy_speed_bonus') ?? 0)
          .toString();
      _constructionSpeedBonus = double.tryParse(_speedController.text) ?? 0.0;
    });
    _saveCloud();
  }

  Future<void> _saveLevels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('embassy_start', _startLevel);
    await prefs.setInt('embassy_end', _endLevel);
    await prefs.setDouble('embassy_speed_bonus', _constructionSpeedBonus);
    _saveCloud();
  }

  // --- Cloud Sync ---
  Future<void> _saveCloud() async {
    await CloudSyncService.save('embassy_calculator', {
      'startLevel': _startLevel,
      'endLevel': _endLevel,
      'constructionSpeedBonus': _constructionSpeedBonus,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('embassy_calculator');
    if (data == null || !mounted) return;
    setState(() {
      _startLevel = data['startLevel'] ?? _startLevel;
      _endLevel = data['endLevel'] ?? _endLevel;
      _constructionSpeedBonus =
          (data['constructionSpeedBonus'] ?? _constructionSpeedBonus)
              .toDouble();
      _speedController.text = _constructionSpeedBonus.toString();
    });
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    _speedController.dispose();
    super.dispose();
  }

  Duration parseDuration(String timeStr) {
    // More flexible duration parser supporting any subset of d/h/m/s
    final regex = RegExp(
      r'(?:(\d+)d)?\s*(?:(\d+)h)?\s*(?:(\d+)m)?\s*(?:(\d+)s)?',
    );
    final match = regex.firstMatch(timeStr.trim());
    if (match == null) return Duration();
    return Duration(
      days: int.tryParse(match.group(1) ?? '') ?? 0,
      hours: int.tryParse(match.group(2) ?? '') ?? 0,
      minutes: int.tryParse(match.group(3) ?? '') ?? 0,
      seconds: int.tryParse(match.group(4) ?? '') ?? 0,
    );
  }

  Map<String, dynamic> calculateTotals() {
    int totalWood = 0, totalCoal = 0, totalIron = 0, totalMeat = 0;
    Duration totalDuration = Duration();

    for (var level in _levels) {
      if (level["level"] >= _startLevel && level["level"] <= _endLevel) {
        totalWood += (level["wood"] as num?)?.toInt() ?? 0;
        totalCoal += (level["coal"] as num?)?.toInt() ?? 0;
        totalIron += (level["iron"] as num?)?.toInt() ?? 0;
        totalMeat += (level["meat"] as num?)?.toInt() ?? 0;
        totalDuration += parseDuration(level["time"]);
      }
    }

    final adjustedSeconds =
        (totalDuration.inSeconds / (1 + (_constructionSpeedBonus / 100)))
            .round();
    final adjustedDuration = Duration(seconds: adjustedSeconds);

    return {
      "wood": totalWood,
      "coal": totalCoal,
      "iron": totalIron,
      "meat": totalMeat,
      "originalTime": totalDuration,
      "totalTime": adjustedDuration,
    };
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return "${d.inSeconds}s";
    int days = d.inDays;
    int hours = d.inHours % 24;
    int minutes = d.inMinutes % 60;
    int seconds = d.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add("${days}d");
    if (hours > 0) parts.add("${hours}h");
    if (minutes > 0) parts.add("${minutes}m");
    if (seconds > 0) parts.add("${seconds}s");
    return parts.join(" ");
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
                              _saveLevels();
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
                              _saveLevels();
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
                            _saveLevels();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      EmbassyStatsSection(
                        wood: totals["wood"],
                        meat: totals["meat"],
                        coal: totals["coal"],
                        iron: totals["iron"],
                        totalTime: _formatDuration(adjusted),
                        rawTime: _formatDuration(original),
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
                      onPressed: () async {
                        setState(() {
                          _startLevel = 2;
                          _endLevel = 30;
                          _constructionSpeedBonus = 0.0;
                          _speedController.text = '0.0';
                        });
                        await _saveLevels();
                        await _saveCloud();
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


