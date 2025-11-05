import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/cloud_sync_service.dart';
import 'dart:async';
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

class CommandCentreStatsSection extends StatelessWidget {
  final int wood;
  final int meat;
  final int coal;
  final int iron;
  final String totalTime;
  final String rawTime;
  const CommandCentreStatsSection({
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

class CommandCentreCalculatorPage extends StatefulWidget {
  const CommandCentreCalculatorPage({super.key});

  @override
  _CommandCentreCalculatorPageState createState() =>
      _CommandCentreCalculatorPageState();
}

class _CommandCentreCalculatorPageState
    extends State<CommandCentreCalculatorPage> {
  int _startLevel = 2;
  int _endLevel = 30;
  double _constructionSpeedBonus = 0.0;
  final TextEditingController _speedController = TextEditingController();
  Timer? _cloudTimer;

  final List<Map<String, dynamic>> _levels = [
    {'level': 1, 'wood': 0, 'meat': 0, 'coal': 0, 'iron': 0, 'time': '0s'},
    {
      'level': 2,
      'wood': 5300,
      'meat': 0,
      'coal': 1000,
      'iron': 0,
      'time': '10s',
    },
    {
      'level': 3,
      'wood': 88000,
      'meat': 0,
      'coal': 17000,
      'iron': 4400,
      'time': '21m 30s',
    },
    {
      'level': 4,
      'wood': 420000,
      'meat': 420000,
      'coal': 84000,
      'iron': 21000,
      'time': '1h 4m 30s',
    },
    {
      'level': 5,
      'wood': 1400000,
      'meat': 1400000,
      'coal': 290000,
      'iron': 74000,
      'time': '3h 39m',
    },
    {
      'level': 6,
      'wood': 5300000,
      'meat': 5300000,
      'coal': 1000000,
      'iron': 260000,
      'time': '9h 52m 30s',
    },
    {
      'level': 7,
      'wood': 15000000,
      'meat': 15000000,
      'coal': 3000000,
      'iron': 750000,
      'time': '1d 13h 44m',
    },
    {
      'level': 8,
      'wood': 37000000,
      'meat': 37000000,
      'coal': 7400000,
      'iron': 1800000,
      'time': '3d 55m',
    },
    {
      'level': 9,
      'wood': 61000000,
      'meat': 61000000,
      'coal': 12000000,
      'iron': 3000000,
      'time': '4d 26m',
    },
    {
      'level': 10,
      'wood': 75000000,
      'meat': 75000000,
      'coal': 15000000,
      'iron': 3700000,
      'time': '4d 19h 44m',
    },
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('CommandCentreCalculatorPage');
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
    await prefs.setInt('command_start', _startLevel);
    await prefs.setInt('command_end', _endLevel);
    await prefs.setDouble('command_speed_bonus', _constructionSpeedBonus);
    _saveCloud();
  }

  // --- Cloud Sync ---
  Future<void> _saveCloud() async {
    await CloudSyncService.save('command_centre_calculator', {
      'startLevel': _startLevel,
      'endLevel': _endLevel,
      'constructionSpeedBonus': _constructionSpeedBonus,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('command_centre_calculator');
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
    // Flexible parser supporting any subset of d/h/m/s
    final regex = RegExp(
      r'(?:(\\d+)d)?\\s*(?:(\\d+)h)?\\s*(?:(\\d+)m)?\\s*(?:(\\d+)s)?',
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
      if (level["level"] > _startLevel && level["level"] <= _endLevel) {
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
                      CommandCentreStatsSection(
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


