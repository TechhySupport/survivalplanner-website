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

class CampsStatsSection extends StatelessWidget {
  final int wood;
  final int meat;
  final int coal;
  final int iron;
  final String totalTime;
  final String rawTime;
  const CampsStatsSection({
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
// ✅ Paste into: lib/normal_building/camps_calculator.dart

class CampsCalculatorPage extends StatefulWidget {
  const CampsCalculatorPage({super.key});

  @override
  State<CampsCalculatorPage> createState() => _CampsCalculatorPageState();
}

class _CampsCalculatorPageState extends State<CampsCalculatorPage> {
  final List<Map<String, dynamic>> _levels = [
    {"level": 1, "wood": 105, "coal": 0, "iron": 0, "meat": 0, "time": "2s"},
    {"level": 2, "wood": 160, "coal": 0, "iron": 0, "meat": 0, "time": "9s"},
    {"level": 3, "wood": 725, "coal": 0, "iron": 0, "meat": 0, "time": "45s"},
    {
      "level": 4,
      "wood": 1600,
      "coal": 320,
      "iron": 0,
      "meat": 0,
      "time": "2m 15s",
    },
    {
      "level": 5,
      "wood": 6800,
      "coal": 1300,
      "iron": 0,
      "meat": 0,
      "time": "4m 30s",
    },
    {
      "level": 6,
      "wood": 17000,
      "coal": 3400,
      "iron": 860,
      "meat": 0,
      "time": "9m",
    },
    {
      "level": 7,
      "wood": 62000,
      "coal": 12000,
      "iron": 3100,
      "meat": 0,
      "time": "18m",
    },
    {
      "level": 8,
      "wood": 110000,
      "coal": 22000,
      "iron": 5600,
      "meat": 0,
      "time": "27m",
    },
    {
      "level": 9,
      "wood": 230000,
      "coal": 47000,
      "iron": 11000,
      "meat": 0,
      "time": "40m 30s",
    },
    {
      "level": 10,
      "wood": 410000,
      "coal": 82000,
      "iron": 20000,
      "meat": 0,
      "time": "54m",
    },
    {
      "level": 11,
      "wood": 520000,
      "coal": 100000,
      "iron": 26000,
      "meat": 520000,
      "time": "1h 7m 30s",
    },
    {
      "level": 12,
      "wood": 670000,
      "coal": 130000,
      "iron": 33000,
      "meat": 670000,
      "time": "1h 21m",
    },
    {
      "level": 13,
      "wood": 950000,
      "coal": 190000,
      "iron": 47000,
      "meat": 950000,
      "time": "1h 39m",
    },
    {
      "level": 14,
      "wood": 1200000,
      "coal": 250000,
      "iron": 63000,
      "meat": 1200000,
      "time": "2h 6m",
    },
    {
      "level": 15,
      "wood": 1800000,
      "coal": 370000,
      "iron": 93000,
      "meat": 1800000,
      "time": "2h 42m",
    },
    {
      "level": 16,
      "wood": 2300000,
      "coal": 470000,
      "iron": 110000,
      "meat": 2300000,
      "time": "4h 34m",
    },
    {
      "level": 17,
      "wood": 3700000,
      "coal": 740000,
      "iron": 180000,
      "meat": 3700000,
      "time": "5h 29m",
    },
    {
      "level": 18,
      "wood": 5000000,
      "coal": 1000000,
      "iron": 250000,
      "meat": 5000000,
      "time": "6h 35m",
    },
    {
      "level": 19,
      "wood": 6200000,
      "coal": 1200000,
      "iron": 310000,
      "meat": 6200000,
      "time": "9h 52m",
    },
    {
      "level": 20,
      "wood": 8600000,
      "coal": 1700000,
      "iron": 430000,
      "meat": 8600000,
      "time": "12h 20m 30s",
    },
    {
      "level": 21,
      "wood": 10000000,
      "coal": 2100000,
      "iron": 540000,
      "meat": 10000000,
      "time": "16h 2m 30s",
    },
    {
      "level": 22,
      "wood": 14000000,
      "coal": 2800000,
      "iron": 720000,
      "meat": 14000000,
      "time": "1d 4m",
    },
    {
      "level": 23,
      "wood": 17000000,
      "coal": 3500000,
      "iron": 890000,
      "meat": 17000000,
      "time": "1d 9h 42m",
    },
    {
      "level": 24,
      "wood": 24000000,
      "coal": 4800000,
      "iron": 1200000,
      "meat": 24000000,
      "time": "1d 23h 11m",
    },
    {
      "level": 25,
      "wood": 32000000,
      "coal": 6500000,
      "iron": 1600000,
      "meat": 32000000,
      "time": "2d 18h 3m",
    },
    {
      "level": 26,
      "wood": 42000000,
      "coal": 8400000,
      "iron": 2100000,
      "meat": 42000000,
      "time": "3d 3h 57m",
    },
    {
      "level": 27,
      "wood": 59000000,
      "coal": 11000000,
      "iron": 2900000,
      "meat": 59000000,
      "time": "3d 19h 9m",
    },
    {
      "level": 28,
      "wood": 79000000,
      "coal": 15000000,
      "iron": 3900000,
      "meat": 79000000,
      "time": "4d 8h 49m",
    },
    {
      "level": 29,
      "wood": 98000000,
      "coal": 19000000,
      "iron": 4900000,
      "meat": 98000000,
      "time": "5d 33m",
    },
    {
      "level": 30,
      "wood": 120000000,
      "coal": 24000000,
      "iron": 6000000,
      "meat": 120000000,
      "time": "6d 40m",
    },
  ];

  final Map<String, int> _start = {'Infantry': 1, 'Marksmen': 1, 'Lancers': 1};
  final Map<String, int> _end = {'Infantry': 30, 'Marksmen': 30, 'Lancers': 30};
  final Map<String, bool> _show = {
    'Infantry': false,
    'Marksmen': false,
    'Lancers': false,
  };

  double _speedBonus = 0;
  final _controller = TextEditingController();
  final _fmt = NumberFormat('#,###');
  Timer? _cloudTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('CampsCalculatorPage');
    _load();
    _loadCloud(); // Load from cloud after local
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  // Removed legacy upgrade dialog; using PaywallHelper.show(context).

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var t in _start.keys) {
        _start[t] = prefs.getInt('camp_${t}_start') ?? 1;
        _end[t] = prefs.getInt('camp_${t}_end') ?? 30;
      }
      _speedBonus = prefs.getDouble('camp_speed_bonus') ?? 0;
      _controller.text = _speedBonus.toString();
    });
    _saveCloud(); // Save to cloud after loading local
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    for (var t in _start.keys) {
      await prefs.setInt('camp_${t}_start', _start[t]!);
      await prefs.setInt('camp_${t}_end', _end[t]!);
    }
    await prefs.setDouble('camp_speed_bonus', _speedBonus);
    _saveCloud(); // Save to cloud after saving local
  }

  // --- Cloud Sync ---
  Future<void> _saveCloud() async {
    await CloudSyncService.save('camps_calculator', {
      'start': Map<String, int>.from(_start),
      'end': Map<String, int>.from(_end),
      'speedBonus': _speedBonus,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('camps_calculator');
    if (data == null || !mounted) return;
    setState(() {
      if (data['start'] != null) {
        _start.addAll(Map<String, int>.from(data['start']));
      }
      if (data['end'] != null) {
        _end.addAll(Map<String, int>.from(data['end']));
      }
      if (data['speedBonus'] != null) {
        _speedBonus = (data['speedBonus'] as num).toDouble();
        _controller.text = _speedBonus.toString();
      }
    });
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Duration _parse(String time) {
    final m = RegExp(
      r'(?:(\d+)d)?\s*(?:(\d+)h)?\s*(?:(\d+)m)?\s*(?:(\d+)s)?',
    ).firstMatch(time.trim());
    return Duration(
      days: int.parse(m?.group(1) ?? '0'),
      hours: int.parse(m?.group(2) ?? '0'),
      minutes: int.parse(m?.group(3) ?? '0'),
      seconds: int.parse(m?.group(4) ?? '0'),
    );
  }

  Map<String, dynamic> _calc(String type) {
    int wood = 0, meat = 0, coal = 0, iron = 0;
    Duration time = Duration();

    for (var l in _levels) {
      final lv = l['level'];
      if (lv > _start[type]! && lv <= _end[type]!) {
        wood += l['wood'] as int;
        meat += l['meat'] as int;
        coal += l['coal'] as int;
        iron += l['iron'] as int;
        time += _parse(l['time']);
      }
    }

    final adj = Duration(
      seconds: (time.inSeconds / (1 + _speedBonus / 100)).round(),
    );

    return {
      'wood': wood,
      'meat': meat,
      'coal': coal,
      'iron': iron,
      'time': time,
      'adjusted': adj,
    };
  }

  String _fmtDuration(Duration d) =>
      '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';

  Widget _buildDropdown(String label, String type, bool isStart) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        DropdownButton<int>(
          value: isStart ? _start[type] : _end[type],
          items: List.generate(30, (i) => i + 1)
              .map(
                (level) =>
                    DropdownMenuItem(value: level, child: Text('$level')),
              )
              .toList(),
          onChanged: (val) {
            setState(() {
              isStart ? _start[type] = val! : _end[type] = val!;
              _save();
            });
          },
        ),
      ],
    );
  }

  Widget _buildTroopSection(String type) {
    final totals = _calc(type);
    return Container(
      width: 260,
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
          _buildDropdown('Start', type, true),
          _buildDropdown('End', type, false),
          TextButton(
            onPressed: () => setState(() => _show[type] = !_show[type]!),
            child: Text(_show[type]! ? 'Close Detail' : 'More Detail'),
          ),
          if (_show[type]!) ...[
            const Divider(),
            Text(
              'Wood: ${_fmt.format(totals['wood'])}',
              style: const TextStyle(color: Colors.brown),
            ),
            Text(
              'Meat: ${_fmt.format(totals['meat'])}',
              style: const TextStyle(color: Colors.red),
            ),
            Text(
              'Coal: ${_fmt.format(totals['coal'])}',
              style: const TextStyle(color: Colors.black),
            ),
            Text(
              'Iron: ${_fmt.format(totals['iron'])}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text('Time (w/ Bonus): ${_fmtDuration(totals['adjusted'])}'),
            Text('Time (no Bonus): ${_fmtDuration(totals['time'])}'),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> total = {
      'wood': 0,
      'meat': 0,
      'coal': 0,
      'iron': 0,
      'time': Duration(),
      'adjusted': Duration(),
    };

    for (var t in _start.keys) {
      final c = _calc(t);
      total['wood'] += c['wood'] as int;
      total['meat'] += c['meat'] as int;
      total['coal'] += c['coal'] as int;
      total['iron'] += c['iron'] as int;
      total['time'] += c['time'] as Duration;
      total['adjusted'] += c['adjusted'] as Duration;
    }

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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Construction Speed Bonus (%)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _speedBonus = double.tryParse(val) ?? 0;
                            _save();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _start.keys.map(_buildTroopSection).toList(),
                      ),
                      const Divider(height: 24),
                      CampsStatsSection(
                        wood: total['wood'],
                        meat: total['meat'],
                        coal: total['coal'],
                        iron: total['iron'],
                        totalTime: _fmtDuration(total['adjusted']),
                        rawTime: _fmtDuration(total['time']),
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
                          for (var t in _start.keys) {
                            _start[t] = 1;
                            _end[t] = 30;
                          }
                          _speedBonus = 0;
                          _controller.text = '0';
                        });
                        await _save();
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


