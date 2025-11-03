import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/cloud_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'services/purchase_service.dart';
import 'services/paywall_helper.dart';
import 'services/analytics_service.dart';
import 'utc_badge.dart';
import 'settings_page.dart';
import 'services/loginscreen.dart';
import 'web/web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'event_page.dart';
import 'troops_page.dart';
import 'bottom_nav_bar.dart';

class ChiefGearCalculatorPage extends StatefulWidget {
  const ChiefGearCalculatorPage({super.key});
  @override
  State<ChiefGearCalculatorPage> createState() =>
      _ChiefGearCalculatorPageState();
}

class _ChiefGearCalculatorPageState extends State<ChiefGearCalculatorPage> {
  // <--- ADDED: missing state fields
  late SharedPreferences _prefs;
  final Map<String, String?> startTiers = {};
  final Map<String, int?> startStars = {};
  final Map<String, String?> endTiers = {};
  final Map<String, int?> endStars = {};
  String? selectedPart;
  String? _lastChangedPart;
  List<Map<String, String>> _recentHistory = [];
  List<int> total = List.filled(5, 0);
  final List<String> _lockedParts = ['Watch', 'Pants', 'Staff'];
  bool get _isPremium => PurchaseService.isPremium;

  Future<void> _saveCloud() async {
    await CloudSyncService.save('chief_gear_calculator', {
      'startTiers': startTiers,
      'startStars': startStars,
      'endTiers': endTiers,
      'endStars': endStars,
      'recentHistory': _recentHistory, // List<Map<String, String>>
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('chief_gear_calculator');
    if (data == null || !mounted) return;
    setState(() {
      if (data['startTiers'] != null) {
        startTiers
          ..clear()
          ..addAll(
            Map<String, String?>.from(
              (data['startTiers'] as Map).map(
                (k, v) => MapEntry(k as String, v as String?),
              ),
            ),
          );
      }
      if (data['startStars'] != null) {
        startStars
          ..clear()
          ..addAll(
            Map<String, int?>.from(
              (data['startStars'] as Map).map(
                (k, v) => MapEntry(k as String, v as int?),
              ),
            ),
          );
      }
      if (data['endTiers'] != null) {
        endTiers
          ..clear()
          ..addAll(
            Map<String, String?>.from(
              (data['endTiers'] as Map).map(
                (k, v) => MapEntry(k as String, v as String?),
              ),
            ),
          );
      }
      if (data['endStars'] != null) {
        endStars
          ..clear()
          ..addAll(
            Map<String, int?>.from(
              (data['endStars'] as Map).map(
                (k, v) => MapEntry(k as String, v as int?),
              ),
            ),
          );
      }
      if (data['recentHistory'] != null && data['recentHistory'] is List) {
        _recentHistory = List<Map<String, String>>.from(
          (data['recentHistory'] as List).map(
            (e) => Map<String, String>.from(e),
          ),
        );
      }
      _calculateTotals();
    });
  }

  Timer? _cloudTimer;
  final List<String> tierOptions = [
    "Green",
    "Blue",
    "Purple",
    "Purple T1",
    "Gold",
    "Gold T1",
    "Gold T2",
    "Pink",
    "Pink T1",
    "Pink T2",
    "Pink T3",
  ];
  final List<String> gearParts = [
    "Helm",
    "Watch",
    "Coat",
    "Pants",
    "Ring",
    "Staff",
  ];
  int powerGain = 0;
  int powerDiff = 0;

  // Canonical data rows in exact order (matches the table you provided)
  final List<List<int>> _canonicalData = [
    [1500, 15, 0, 0, 224400], // Green 0
    [3800, 40, 0, 0, 306000], // Green 1
    [7000, 70, 0, 0, 408000], // Blue 0
    [9700, 95, 0, 0, 510000], // Blue 1
    [0, 0, 45, 0, 612000], // Blue 2
    [0, 0, 50, 0, 714000], // Blue 3
    [0, 0, 60, 0, 816000], // Purple 0
    [0, 0, 70, 0, 885360], // Purple 1
    [6500, 65, 40, 0, 954720], // Purple 2
    [8000, 80, 50, 0, 1024080], // Purple 3
    [10000, 95, 60, 0, 1093440], // Purple T1 0
    [11000, 110, 70, 0, 1162800], // Purple T1 1
    [13000, 130, 85, 0, 1232160], // Purple T1 2
    [15000, 160, 100, 0, 1301520], // Purple T1 3
    [22000, 220, 40, 0, 1362720], // Gold 0
    [23000, 230, 40, 0, 1423920], // Gold 1  <- added
    [25000, 250, 45, 0, 1485120], // Gold 2
    [26000, 260, 45, 0, 1546320], // Gold 3
    [28000, 280, 45, 0, 1607520], // Gold T1 0
    [30000, 300, 55, 0, 1668720], // Gold T1 1
    [32000, 320, 55, 0, 1729920], // Gold T1 2
    [35000, 340, 55, 0, 1791120], // Gold T1 3
    [38000, 390, 55, 0, 1852320], // Gold T2 0
    [43000, 430, 75, 0, 1913520], // Gold T2 1
    [45000, 460, 80, 0, 1974720], // Gold T2 2
    [48000, 500, 85, 0, 2040000], // Gold T2 3
    [50000, 530, 85, 10, 2142000], // Pink 0
    [52000, 560, 90, 10, 2244000], // Pink 1
    [54000, 590, 95, 10, 2346000], // Pink 2
    [56000, 620, 100, 10, 2448000], // Pink 3
    [59000, 670, 110, 15, 2550000], // Pink T1 0
    [61000, 700, 115, 15, 2652000], // Pink T1 1
    [63000, 730, 120, 15, 2754000], // Pink T1 2
    [65000, 760, 125, 15, 2856000], // Pink T1 3
    [68000, 810, 135, 20, 2958000], // Pink T2 0
    [70000, 840, 140, 20, 3060000], // Pink T2 1
    [72000, 870, 145, 20, 3162000], // Pink T2 2
    [74000, 900, 150, 20, 3264000], // Pink T2 3 <- added (was missing)
    [77000, 950, 160, 25, 3366000], // Pink T3 0
    [80000, 990, 165, 25, 3468000], // Pink T3 1
    [83000, 1030, 170, 25, 3570000], // Pink T3 2
    [86000, 1070, 180, 25, 3672000], // Pink T3 3
  ];

  // Canonical labels that exactly correspond to each row in _canonicalData
  final List<String> _canonicalLabels = [
    'Green 0',
    'Green 1',
    'Blue 0',
    'Blue 1',
    'Blue 2',
    'Blue 3',
    'Purple 0',
    'Purple 1',
    'Purple 2',
    'Purple 3',
    'Purple T1 0',
    'Purple T1 1',
    'Purple T1 2',
    'Purple T1 3',
    'Gold 0',
    'Gold 1',
    'Gold 2',
    'Gold 3',
    'Gold T1 0',
    'Gold T1 1',
    'Gold T1 2',
    'Gold T1 3',
    'Gold T2 0',
    'Gold T2 1',
    'Gold T2 2',
    'Gold T2 3',
    'Pink 0',
    'Pink 1',
    'Pink 2',
    'Pink 3',
    'Pink T1 0',
    'Pink T1 1',
    'Pink T1 2',
    'Pink T1 3',
    'Pink T2 0',
    'Pink T2 1',
    'Pink T2 2',
    'Pink T2 3',
    'Pink T3 0',
    'Pink T3 1',
    'Pink T3 2',
    'Pink T3 3',
  ];

  // Use canonical labels for allTiers so label->index mapping is stable
  List<String> get allTiers => List<String>.from(_canonicalLabels);

  // explicit star counts per tier to build labels in correct order
  final Map<String, int> _tierStarCounts = {
    "Green": 2,
    "Blue": 4,
    "Purple": 4,
    "Purple T1": 4,
    "Gold": 4,
    "Gold T1": 4,
    "Gold T2": 4,
    "Pink": 4,
    "Pink T1": 4,
    "Pink T2": 4,
    "Pink T3": 4,
  };

  int _maxStarsForTier(String tier) {
    // "None" has a single option (0)
    if (tier == "None") return 1;
    // Use explicit per-tier counts to avoid mismatches
    return _tierStarCounts[tier] ?? 4;
  }

  // Build a stable map from "Tier star" label -> data index (safe lookup)
  Map<String, int> get _labelToIndex {
    final map = <String, int>{};
    final labels = allTiers;
    final rows = data;
    final len = labels.length < rows.length ? labels.length : rows.length;
    for (var i = 0; i < len; i++) {
      map[labels[i]] = i;
    }
    return map;
  }

  // Debug helper: prints mapping of allTiers -> data index and alloy value
  void _debugPrintTierMapping() {
    final rows = data;
    for (int i = 0; i < allTiers.length && i < rows.length; i++) {
      final tierStar = allTiers[i];
      final alloy = rows[i][0];
      debugPrint('allTiers[$i] = $tierStar  -> data[$i] Alloy: $alloy');
    }

    // quick check for Gold T2 ★1 and ★2
    final goldT2Star1 = 'Gold T2 1';
    final goldT2Star2 = 'Gold T2 2';
    final idx1 = allTiers.indexOf(goldT2Star1);
    final idx2 = allTiers.indexOf(goldT2Star2);
    debugPrint(
      'Gold T2 ★1 index=$idx1 alloy=${idx1 >= 0 && idx1 < rows.length ? rows[idx1][0] : "N/A"}',
    );
    debugPrint(
      'Gold T2 ★2 index=$idx2 alloy=${idx2 >= 0 && idx2 < rows.length ? rows[idx2][0] : "N/A"}',
    );
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('ChiefGearCalculatorPage');
    _loadCloud();
    Future.delayed(const Duration(seconds: 2), _saveCloud);
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    _loadPrefs();

    // Call debug printer once after a short delay so console shows mapping at startup
    Future.delayed(const Duration(milliseconds: 500), () {
      _debugPrintTierMapping();
    });
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    for (var part in gearParts) {
      // default start to "None" (grey) and star 0
      startTiers[part] = _prefs.getString('${part}_startTier') ?? "None";
      startStars[part] = _prefs.getInt('${part}_startStar') ?? 0;
      // default end is also None so no calculation until user sets values
      endTiers[part] = _prefs.getString('${part}_endTier') ?? "None";
      endStars[part] = _prefs.getInt('${part}_endStar') ?? 0;
    }
    _calculateTotals();
    setState(() {});
  }

  void _onChanged(String part, String field, dynamic value) {
    _lastChangedPart = part; // Track which part was changed
    if (field == "startTier") {
      startTiers[part] = value;
      // if user picks None, ensure startStars reset to 0
      if (value == "None") {
        startStars[part] = 0;
      }
      final map = _labelToIndex;
      final startIdx = map["${startTiers[part]} ${startStars[part]}"] ?? -1;
      final endIdx = map["${endTiers[part]} ${endStars[part]}"] ?? -1;
      // Initialize end if null, align with start when start is ahead of end
      if (endTiers[part] == null) {
        endTiers[part] = (value == "None") ? "None" : value;
        endStars[part] = startStars[part];
      } else if (startTiers[part] != "None" && startIdx > endIdx) {
        endTiers[part] = value;
        endStars[part] = startStars[part];
      }
    }
    if (field == "startStar") {
      startStars[part] = value;
      // If start tier is a T1 tier, auto-increment end to start+1 (bounded)
      final tier = startTiers[part] ?? "None";
      final maxStar = _maxStarsForTier(tier) - 1;
      if (tier.contains("T1") && value != null) {
        final autoEnd = (value + 1) <= maxStar ? (value + 1) : maxStar;
        endTiers[part] = tier;
        endStars[part] = autoEnd;
      } else {
        // existing behavior: keep end in sync if same tier and end is behind
        if (endTiers[part] == startTiers[part] &&
            (endStars[part] == null || value > endStars[part]!)) {
          endStars[part] = value;
        }
      }
    }
    if (field == "endTier") endTiers[part] = value;
    if (field == "endStar") endStars[part] = value;

    _prefs.setString('${part}_startTier', startTiers[part]!);
    _prefs.setInt('${part}_startStar', startStars[part]!);
    _prefs.setString('${part}_endTier', endTiers[part]!);
    _prefs.setInt('${part}_endStar', endStars[part]!);

    _calculateTotals();
    setState(() {});
  }

  void _applyToAllEndValues(String part) {
    for (final gear in gearParts) {
      startTiers[gear] ??= startTiers[part];
      startStars[gear] ??= startStars[part];
      endTiers[gear] = endTiers[part];
      endStars[gear] = endStars[part];
      _prefs.setString('${gear}_startTier', startTiers[gear]!);
      _prefs.setInt('${gear}_startStar', startStars[gear]!);
      _prefs.setString('${gear}_endTier', endTiers[gear]!);
      _prefs.setInt('${gear}_endStar', endStars[gear]!);
    }
    _calculateTotals();
    setState(() {});
  }

  void _resetAll() async {
    // Reset in memory: set START to "None" for every part (Start - None)
    for (final part in gearParts) {
      startTiers[part] = "None";
      startStars[part] = 0;
      // set end to None as well so no calculation by default
      endTiers[part] = "None";
      endStars[part] = 0;
    }

    total = List.filled(5, 0);
    powerGain = 0;
    powerDiff = 0;
    _recentHistory.clear();
    selectedPart = null;

    // Persist reset to SharedPreferences
    for (final part in gearParts) {
      await _prefs.setString('${part}_startTier', "None");
      await _prefs.setInt('${part}_startStar', 0);
      await _prefs.setString('${part}_endTier', "None");
      await _prefs.setInt('${part}_endStar', 0);
    }

    // Persist reset to Cloud
    await CloudSyncService.save('chief_gear_calculator', {
      'startTiers': startTiers,
      'startStars': startStars,
      'endTiers': endTiers,
      'endStars': endStars,
      'recentHistory': [],
    });

    setState(() {}); // rebuild UI
  }

  // Use canonicalData directly for calculations
  List<List<int>> get data => _canonicalData;

  // helper to safely read an int from rows (handles num/int and OOB)
  int _rowValue(List<List<int>> rows, int i, int j) {
    if (i < 0 || i >= rows.length) return 0;
    final v = rows[i][j];
    return v;
  }

  void _calculateTotals() {
    final rows = data;
    final map = _labelToIndex;
    total = List.filled(5, 0);
    powerGain = 0;
    powerDiff = 0;

    for (var part in gearParts) {
      final startTier = startTiers[part] ?? "None";
      final endTier = endTiers[part] ?? "None";
      final startStar = startStars[part] ?? 0;
      final endStar = endStars[part] ?? 0;

      // If user selected identical start and end, nothing to sum
      if (startTier == endTier && startStar == endStar) continue;

      final startKey = "$startTier $startStar";
      final endKey = "$endTier $endStar";
      final startIndex = map[startKey] ?? -1;
      final endIndex = map[endKey] ?? -1;

      // require a valid end index
      if (endIndex < 0) continue;

      // Determine loopStart:
      // - If startTier == "None": start from the very first tier (index 0)
      //   so we sum everything up to the chosen end tier with baseline power 0.
      // - Otherwise start from the next row after startIndex
      int loopStart;
      if (startTier == "None") {
        loopStart = 0;
      } else {
        // If startIndex invalid or not before endIndex, nothing to sum
        if (startIndex < 0 || startIndex >= endIndex) continue;
        loopStart = startIndex + 1;
      }

      int prevPower = (startTier == "None")
          ? 0
          : ((startIndex >= 0 && startIndex < rows.length)
                ? _rowValue(rows, startIndex, 4)
                : 0);

      List<int> subtotal = List.filled(5, 0);
      int partPowerGain = 0;
      final changedPart = _lastChangedPart ?? part;
      final List<String> debugRows = [];

      for (int i = loopStart; i <= endIndex; i++) {
        final rowAlloy = (i >= 0 && i < rows.length)
            ? _rowValue(rows, i, 0)
            : -1;
        debugRows.add('idx=$i alloy=$rowAlloy');
        for (int j = 0; j < 5; j++) {
          subtotal[j] += _rowValue(rows, i, j);
        }
        int currPower = _rowValue(rows, i, 4);
        if (currPower > prevPower) {
          partPowerGain += currPower - prevPower;
        }
        prevPower = currPower;
      }

      if (changedPart == part) {
        debugPrint('--- Calc for part: $part ---');
        debugPrint('startKey=$startKey startIndex=$startIndex');
        debugPrint('endKey=$endKey endIndex=$endIndex loopStart=$loopStart');
        for (var r in debugRows) {
          debugPrint(r);
        }
        debugPrint(
          'subtotal alloy=${subtotal[0]}, solution=${subtotal[1]}, plans=${subtotal[2]}, amber=${subtotal[3]}, powerGain=$partPowerGain',
        );
      }

      for (int j = 0; j < 4; j++) {
        total[j] += subtotal[j];
      }
      powerGain += partPowerGain;
      powerDiff += partPowerGain;

      final f = NumberFormat("#,###");
      final startLabel = startTier == "None"
          ? "None"
          : "${_getTierLabel(startTier) ?? startTier} ★$startStar";
      final endLabel = "${_getTierLabel(endTier) ?? endTier} ★$endStar";
      final summary =
          "$part $startLabel → $endLabel: ${f.format(subtotal[0])} Alloy, "
          "${f.format(subtotal[1])} Sol, ${f.format(subtotal[2])} Plans, "
          "${f.format(subtotal[3])} Amber, +${f.format(partPowerGain)} Power";

      final existingIndex = _recentHistory.indexWhere(
        (e) => e['part'] == changedPart,
      );
      if (existingIndex == 0) {
        _recentHistory[0] = {'part': changedPart, 'summary': summary};
      } else {
        if (existingIndex > 0) _recentHistory.removeAt(existingIndex);
        _recentHistory.insert(0, {'part': changedPart, 'summary': summary});
        if (_recentHistory.length > 5) _recentHistory.removeLast();
      }
    }

    setState(() {});
  }

  Widget _gearButton(String part) {
    final tier = startTiers[part];
    final star = startStars[part];
    final label = _getTierLabel(tier);
    final locked = !_isPremium && _lockedParts.contains(part);
    return GestureDetector(
      onTap: locked
          ? () => _showUpgradeDialog()
          : () => setState(
              () => selectedPart = (selectedPart == part) ? null : part,
            ),
      child: Stack(
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getTierColor(tier),
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).toInt()),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              tier == "None" ? "$part\nNone" : "$part\n★${star ?? 0}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: locked
                    ? Colors.white70
                    : (tier == "None" ? Colors.grey[700] : null),
              ),
            ),
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock, color: Colors.white70, size: 30),
              ),
            ),
          if (label != null)
            Positioned(
              top: 4,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    // New behavior: invoke premium paywall bottom sheet instead of dialog.
    if (!PurchaseService.isPremium) {
      PaywallHelper.show(context);
      return; // stop locked action
    }
  }

  // ignore: unused_element
  Widget _gearPopup(String part) {
    final tierDropdownList = ["None", ...tierOptions];
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => selectedPart = null),
            child: const Text("Hide", style: TextStyle(fontSize: 14)),
          ),
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: startTiers[part],
          items: tierDropdownList
              .map((e) => DropdownMenuItem(value: e, child: Text("Start: $e")))
              .toList(),
          onChanged: (val) => _onChanged(part, 'startTier', val),
        ),
        DropdownButton<int>(
          isExpanded: true,
          value: startStars[part],
          items: List.generate(
            _maxStarsForTier(startTiers[part] ?? "None"),
            (i) => DropdownMenuItem(value: i, child: Text("★ $i")),
          ).toList(),
          onChanged: startTiers[part] == "None"
              ? null
              : (val) => _onChanged(part, 'startStar', val),
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: endTiers[part],
          items: ["None", ...tierOptions]
              .map((e) => DropdownMenuItem(value: e, child: Text("End: $e")))
              .toList(),
          onChanged: (val) => _onChanged(part, 'endTier', val),
        ),
        DropdownButton<int>(
          isExpanded: true,
          value: endStars[part],
          items: List.generate(
            _maxStarsForTier(endTiers[part] ?? "None"),
            (i) => DropdownMenuItem(value: i, child: Text("★ $i")),
          ).toList(),
          onChanged: (endTiers[part] == "None")
              ? null
              : (val) => _onChanged(part, 'endStar', val),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _applyToAllEndValues(part),
          child: const Text("Apply to All"),
        ),
      ],
    );
  }

  Color _getTierColor(String? tier) {
    if (tier == null || tier == "None") return Colors.grey[300]!;
    if (tier.startsWith("Green")) return Colors.green[300]!;
    if (tier.startsWith("Blue")) return Colors.blue[300]!;
    if (tier.startsWith("Purple T1")) return Colors.deepPurple[300]!;
    if (tier.startsWith("Purple")) return Colors.purple[300]!;
    if (tier.startsWith("Gold T")) return Colors.orange[400]!;
    if (tier.startsWith("Gold")) return Colors.amber[400]!;
    if (tier.startsWith("Pink T")) return Colors.pink[200]!;
    if (tier.startsWith("Pink")) return Colors.pink[300]!;
    return Colors.grey[300]!;
  }

  String? _getTierLabel(String? tier) {
    if (tier == null) return null;
    if (tier.contains("T1")) return "T1";
    if (tier.contains("T2")) return "T2";
    if (tier.contains("T3")) return "T3";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat("#,###");
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _gearButton("Helm"),
                      Column(
                        children: [
                          Text(
                            "Power: ${f.format(powerGain)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (powerDiff > 0)
                            Text(
                              "+${f.format(powerDiff)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                      _gearButton("Watch"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _gearButton("Coat"),
                      const Text(
                        "Enhancement Cost",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _gearButton("Pants"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // <-- Add this line
                    children: [
                      _gearButton("Ring"),
                      // Wrap the Column in a Flexible to avoid layout issues
                      Flexible(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("Total Alloy: ${f.format(total[0])}"),
                              Text("Total Solution: ${f.format(total[1])}"),
                              Text("Total Plans: ${f.format(total[2])}"),
                              Text("Total Amber: ${f.format(total[3])}"),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.cloud_upload),
                                    label: const Text('Save to Cloud'),
                                    onPressed: () async {
                                      final session = Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentSession;
                                      if (session == null) {
                                        // Not signed in -> go to Login
                                        if (!mounted) return;
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Saved to cloud'),
                                        ),
                                      );
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: _resetAll,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    child: const Text('Reset All'),
                                  ),
                                ],
                              ),
                              if (_recentHistory.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 50,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recentHistory.length,
                                    itemBuilder: (context, index) {
                                      final entry = _recentHistory[index];
                                      final part =
                                          entry['part'] ?? 'Calc ${index + 1}';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: ActionChip(
                                          label: Text(
                                            part.isNotEmpty
                                                ? part
                                                : 'Calc ${index + 1}',
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                      24,
                                                      20,
                                                      24,
                                                      8,
                                                    ),
                                                content:
                                                    buildSummaryDialogContent(
                                                      part,
                                                      entry['summary'] ?? '',
                                                    ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text("Close"),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _gearButton("Staff"),
                    ],
                  ),
                  if (selectedPart != null) _gearPopup(selectedPart!),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
    );
  }

  Widget buildSummaryDialogContent(String part, String summary) {
    final rows = data;
    final startKey = "${startTiers[part]} ${startStars[part]}";
    final endKey = "${endTiers[part]} ${endStars[part]}";
    final startIndex = allTiers.indexOf(startKey);
    final endIndex = allTiers.indexOf(endKey);

    if (startIndex < 0 || endIndex < 0 || endIndex <= startIndex) {
      return const SizedBox.shrink();
    }

    List<int> subtotal = List.filled(5, 0);
    int partPowerGain = 0;
    int prevPower = (startIndex >= 0 && startIndex < rows.length)
        ? _rowValue(rows, startIndex, 4)
        : 0;
    for (int i = startIndex + 1; i <= endIndex; i++) {
      for (int j = 0; j < 5; j++) {
        subtotal[j] += _rowValue(rows, i, j);
      }
      int currPower = _rowValue(rows, i, 4);
      if (currPower > prevPower) {
        partPowerGain += currPower - prevPower;
      }
      prevPower = currPower;
    }

    final f = NumberFormat("#,###");
    final startLabel =
        "${_getTierLabel(startTiers[part]) ?? startTiers[part]} ★${startStars[part]}";
    final endLabel =
        "${_getTierLabel(endTiers[part]) ?? endTiers[part]} ★${endStars[part]}";

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            part,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text("$startLabel → $endLabel", style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          Text("Alloy: ${f.format(subtotal[0])}"),
          Text("Solution: ${f.format(subtotal[1])}"),
          Text("Plans: ${f.format(subtotal[2])}"),
          Text("Amber: ${f.format(subtotal[3])}"),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "+${f.format(partPowerGain)} Power",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    super.dispose();
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
