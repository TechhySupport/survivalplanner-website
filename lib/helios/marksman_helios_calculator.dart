import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/cloud_sync_service.dart';
import 'dart:async';
import '../services/analytics_service.dart';

const Map<int, Map<String, int>> flameSquadData = {
  1: {'crystals': 16, 'steel': 5000},
  2: {'crystals': 25, 'steel': 8000},
  3: {'crystals': 41, 'steel': 13000},
  4: {'crystals': 68, 'steel': 21000},
  5: {'crystals': 102, 'steel': 33000},
};

const Map<int, Map<String, int>> crystalVisionData = {
  1: {'crystals': 40, 'steel': 10000},
  2: {'crystals': 56, 'steel': 14000},
  3: {'crystals': 74, 'steel': 18000},
  4: {'crystals': 102, 'steel': 25000},
  5: {'crystals': 136, 'steel': 34000},
  6: {'crystals': 184, 'steel': 46000},
  7: {'crystals': 248, 'steel': 62000},
  8: {'crystals': 334, 'steel': 83000},
};

const Map<int, Map<String, int>> crystalArmorData = crystalVisionData;
const Map<int, Map<String, int>> flameLegionData = {
  1: {'crystals': 83, 'steel': 23000},
  2: {'crystals': 102, 'steel': 28000},
  3: {'crystals': 125, 'steel': 34000},
  4: {'crystals': 150, 'steel': 41000},
  5: {'crystals': 184, 'steel': 51000},
  6: {'crystals': 225, 'steel': 62000},
  7: {'crystals': 276, 'steel': 76000},
  8: {'crystals': 334, 'steel': 93000},
  9: {'crystals': 418, 'steel': 111000},
  10: {'crystals': 502, 'steel': 130000},
  11: {'crystals': 602, 'steel': 160000},
  12: {'crystals': 744, 'steel': 200000},
};

const Map<int, Map<String, int>> crystalArrowData = {
  1: {'crystals': 54, 'steel': 15000},
  2: {'crystals': 66, 'steel': 18000},
  3: {'crystals': 81, 'steel': 22000},
  4: {'crystals': 97, 'steel': 27000},
  5: {'crystals': 118, 'steel': 33000},
  6: {'crystals': 145, 'steel': 40000},
  7: {'crystals': 178, 'steel': 49000},
  8: {'crystals': 216, 'steel': 60000},
  9: {'crystals': 270, 'steel': 75000},
  10: {'crystals': 324, 'steel': 90000},
  11: {'crystals': 388, 'steel': 100000},
  12: {'crystals': 480, 'steel': 130000},
};

const Map<int, Map<String, int>> crystalProtectionData = crystalArrowData;
const Map<int, Map<String, int>> heliosData = {
  1: {'crystals': 2236, 'steel': 1000000},
};

class MarksmanHeliosCalculatorPage extends StatefulWidget {
  const MarksmanHeliosCalculatorPage({super.key});

  @override
  State<MarksmanHeliosCalculatorPage> createState() =>
      _MarksmanHeliosCalculatorPageState();
}

class _MarksmanHeliosCalculatorPageState
    extends State<MarksmanHeliosCalculatorPage> {
  final NumberFormat formatter = NumberFormat('#,###');

  final Map<String, TextEditingController> startControllers = {};
  final Map<String, TextEditingController> desiredControllers = {};
  final Map<String, Map<String, int>> perTechTotals = {};

  final Map<String, Map<int, Map<String, int>>> techData = {
    'Flame Squad': flameSquadData,
    'Crystal Vision': crystalVisionData,
    'Crystal Armor': crystalArmorData,
    'Flame Legion': flameLegionData,
    'Crystal Arrow': crystalArrowData,
    'Crystal Protection': crystalProtectionData,
    'Helios': heliosData,
  };

  int totalCrystals = 0;
  int totalSteel = 0;

  Timer? _cloudTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('MarksmanHeliosCalculatorPage');
    for (var tech in techData.keys) {
      startControllers[tech] = TextEditingController();
      desiredControllers[tech] = TextEditingController();
      startControllers[tech]!.addListener(_recalculateAll);
      desiredControllers[tech]!.addListener(_recalculateAll);
    }
    _loadFromPrefs();
    _loadCloud();
    _cloudTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _saveCloud());
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    for (var ctrl in [
      ...startControllers.values,
      ...desiredControllers.values
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCloud() async {
    final data = <String, dynamic>{};
    for (var tech in techData.keys) {
      data['start_$tech'] =
          int.tryParse(startControllers[tech]?.text ?? '') ?? 0;
      data['end_$tech'] =
          int.tryParse(desiredControllers[tech]?.text ?? '') ?? 0;
    }
    data['totalCrystals'] = totalCrystals;
    data['totalSteel'] = totalSteel;
    await CloudSyncService.save('marksman_helios_calculator', data);
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('marksman_helios_calculator');
    if (data == null || !mounted) return;
    setState(() {
      for (var tech in techData.keys) {
        final start = data['start_$tech'];
        final end = data['end_$tech'];
        if (start != null) {
          startControllers[tech]?.text = start > 0 ? '$start' : '';
        }
        if (end != null) desiredControllers[tech]?.text = end > 0 ? '$end' : '';
      }
    });
    await _recalculateAll();
  }

  Future<void> _recalculateAll() async {
    int totalC = 0;
    int totalS = 0;
    perTechTotals.clear();

    for (var tech in techData.keys) {
      final start = int.tryParse(startControllers[tech]!.text) ?? 0;
      final end = int.tryParse(desiredControllers[tech]!.text) ?? 0;

      int c = 0;
      int s = 0;
      for (int i = start + 1; i <= end; i++) {
        c += techData[tech]?[i]?['crystals'] ?? 0;
        s += techData[tech]?[i]?['steel'] ?? 0;
      }

      perTechTotals[tech] = {'crystals': c, 'steel': s};
      totalC += c;
      totalS += s;
    }

    setState(() {
      totalCrystals = totalC;
      totalSteel = totalS;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('helios_marksman_crystals', totalCrystals);
    await prefs.setInt('helios_marksman_steel', totalSteel);
    _saveToPrefs();
    _saveCloud();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (var tech in techData.keys) {
      await prefs.setInt(
          'start_$tech', int.tryParse(startControllers[tech]?.text ?? '') ?? 0);
      await prefs.setInt(
          'end_$tech', int.tryParse(desiredControllers[tech]?.text ?? '') ?? 0);
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (var tech in techData.keys) {
      final start = prefs.getInt('start_$tech');
      final end = prefs.getInt('end_$tech');
      startControllers[tech]?.text = (start ?? 0).toString();
      desiredControllers[tech]?.text = (end ?? 0).toString();
    }
    await _recalculateAll();
  }

  void _resetAll() {
    for (var ctrl in [
      ...startControllers.values,
      ...desiredControllers.values
    ]) {
      ctrl.clear();
    }
    setState(() {
      totalCrystals = 0;
      totalSteel = 0;
      perTechTotals.clear();
    });
  }

  Widget _buildTechRow(String tech) {
    // Get min and max from the data map for this tech
    final dataMap = techData[tech]!;
    final minLevel =
        dataMap.keys.isEmpty ? 0 : dataMap.keys.reduce((a, b) => a < b ? a : b);
    final maxLevel =
        dataMap.keys.isEmpty ? 0 : dataMap.keys.reduce((a, b) => a > b ? a : b);
    // Get current values
    int? startValue = int.tryParse(startControllers[tech]?.text ?? '');
    int? desiredValue = int.tryParse(desiredControllers[tech]?.text ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tech,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: (startValue != null &&
                          startValue >= minLevel &&
                          startValue <= maxLevel)
                      ? startValue
                      : null,
                  items: [
                    for (int i = minLevel; i <= maxLevel; i++)
                      DropdownMenuItem(value: i, child: Text(i.toString()))
                  ],
                  onChanged: (val) {
                    startControllers[tech]?.text = val?.toString() ?? '';
                  },
                  decoration: const InputDecoration(
                    labelText: 'Start',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: (desiredValue != null &&
                          desiredValue >= minLevel &&
                          desiredValue <= maxLevel)
                      ? desiredValue
                      : null,
                  items: [
                    for (int i = minLevel; i <= maxLevel; i++)
                      DropdownMenuItem(value: i, child: Text(i.toString()))
                  ],
                  onChanged: (val) {
                    desiredControllers[tech]?.text = val?.toString() ?? '';
                  },
                  decoration: const InputDecoration(
                    labelText: 'Desired',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (perTechTotals.containsKey(tech)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '-> ${formatter.format(perTechTotals[tech]!['crystals'])} Fire Crystal Shards, ${formatter.format(perTechTotals[tech]!['steel'])} Steel',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '-> ${formatter.format((perTechTotals[tech]!['crystals']! / 13).ceil())} Fire Crystals Needed',
                style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text('Marksman Helios'),
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  _headerCard(),
                  const SizedBox(height: 20),
                  ...techData.keys.map((k) => _techSection(k)),
                  const SizedBox(height: 20),
                  _totalsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _resetAll,
        backgroundColor: Colors.red.shade400,
        icon: const Icon(Icons.refresh),
        label: const Text('Reset All'),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade200.withOpacity(.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.remove_red_eye, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Marksman Tech Tree',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed: _recalculateAll,
                icon: const Icon(Icons.refresh, color: Colors.white70),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text('Select levels to see cumulative costs.',
              style: TextStyle(color: Colors.white.withOpacity(.85))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('${formatter.format(totalCrystals)} Shards', Icons.toll,
                  Colors.amber.shade300),
              _pill('${formatter.format((totalCrystals / 13).ceil())} Crystals',
                  Icons.bubble_chart, Colors.cyan.shade300),
              _pill('${formatter.format(totalSteel)} Steel', Icons.construction,
                  Colors.blueGrey.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _techSection(String tech) {
    return _sectionCard(
      title: tech,
      child: _buildTechRow(tech),
    );
  }

  Widget _totalsCard() {
    return _sectionCard(
      title: 'Totals',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statLine('Total Shards', formatter.format(totalCrystals),
              Icons.auto_awesome, Colors.amber.shade600),
          const SizedBox(height: 8),
          _statLine(
              'Fire Crystals',
              formatter.format((totalCrystals / 13).ceil()),
              Icons.bubble_chart,
              Colors.cyan.shade600),
          const SizedBox(height: 8),
          _statLine('Total Steel', formatter.format(totalSteel),
              Icons.construction, Colors.blueGrey.shade600),
        ],
      ),
    );
  }

  Widget _statLine(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(.85), color.withOpacity(.55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: color.darken()))),
          Text(value,
              style: TextStyle(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color.darken())),
        ],
      ),
    );
  }

  Widget _sectionCard(
      {required String title, required Widget child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: Colors.deepPurple.shade100.withOpacity(.35),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
        border: Border.all(color: Colors.deepPurple.shade50, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade300,
                      Colors.indigo.shade400
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _pill(String text, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withOpacity(.25),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

extension _ColorShade on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final h = hsl.hue;
    final s = hsl.saturation;
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(hsl.alpha, h, s, l).toColor();
  }
}
