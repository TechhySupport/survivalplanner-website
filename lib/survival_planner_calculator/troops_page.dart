import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/cloud_sync_service.dart'; // <-- added import
import 'bottom_nav_bar.dart';
import 'bear_trap_troops.dart';
import 'crazy_joe_troops.dart';
import 'troop_training_calculator.dart';
import 'helios_calculator.dart';
import '../generated/app_localizations.dart';
import 'utc_badge.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import '../services/analytics_service.dart';
import 'settings_page.dart';
import '../services/loginscreen.dart';
import 'web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'event_page.dart';

class TroopsPage extends StatefulWidget {
  const TroopsPage({super.key});

  @override
  State<TroopsPage> createState() => _TroopsPageState();
}

class _TroopsPageState extends State<TroopsPage> {
  final _seenKeys = [
    'bear_trap_troops',
    'crazy_joe_troops',
    'troop_training_calculator',
    'helios_calculator',
  ];
  Map<String, bool> _seen = {};
  int _totalTroops = 0;

  final Map<String, List<Map<String, dynamic>>> _troopsData = {
    'Infantry': [],
    'Marksmen': [],
    'Lancers': [],
  };

  // Focus nodes per entry per category to show a tick toolbar
  final Map<String, List<FocusNode>> _focusMap = {
    'Infantry': [],
    'Marksmen': [],
    'Lancers': [],
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('TroopsPage');
    _loadSeenFlags();
    _loadSavedData();
    _loadCloudData(); // <-- load cloud on startup
  }

  Future<void> _loadSeenFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, bool>{};
    for (var key in _seenKeys) {
      loaded[key] = prefs.getBool('seen_$key') ?? false;
    }
    setState(() => _seen = loaded);
  }

  Future<void> _markSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_$key', true);
    setState(() => _seen[key] = true);
    await _saveCloud(); // <-- persist seen flag to cloud
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in _troopsData.keys) {
      final length = prefs.getInt('${type}_count') ?? 0;
      final entries = <Map<String, dynamic>>[];
      for (int i = 0; i < length; i++) {
        final count = prefs.getInt('${type}_entry_${i}_count') ?? 0;
        final level = prefs.getInt('${type}_entry_${i}_level') ?? 1;
        entries.add({
          'count': TextEditingController(
            text: NumberFormat('#,###').format(count),
          ),
          'level': level,
        });
      }
      if (entries.isEmpty) {
        entries.add({'count': TextEditingController(), 'level': 1});
      }
      _troopsData[type] = entries;
      _ensureFocusExact(type, entries.length);
    }
    _recalculateTotal();
    setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in _troopsData.keys) {
      final entries = _troopsData[type]!;
      await prefs.setInt('${type}_count', entries.length);
      for (int i = 0; i < entries.length; i++) {
        final count =
            int.tryParse(entries[i]['count'].text.replaceAll(',', '')) ?? 0;
        final level = entries[i]['level'];
        await prefs.setInt('${type}_entry_${i}_count', count);
        await prefs.setInt('${type}_entry_${i}_level', level);
      }
    }
    await _saveCloud(); // <-- persist to cloud as well
  }

  void _addEntry(String type) {
    setState(() {
      _troopsData[type]!.add({'count': TextEditingController(), 'level': 1});
      _ensureFocusExact(type, _troopsData[type]!.length);
    });
  }

  void _recalculateTotal() {
    int total = 0;
    for (var entries in _troopsData.values) {
      for (var entry in entries) {
        total += int.tryParse(entry['count'].text.replaceAll(',', '')) ?? 0;
      }
    }
    setState(() {
      _totalTroops = total;
    });
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  void _ensureFocusExact(String type, int length) {
    _focusMap[type] = List.generate(length, (_) => FocusNode());
  }

  KeyboardActionsConfig _keyboardConfig() {
    final actions = <KeyboardActionsItem>[];
    _focusMap.forEach((_, nodes) {
      for (final node in nodes) {
        actions.add(
          KeyboardActionsItem(
            focusNode: node,
            toolbarButtons: [
              (n) => IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => n.unfocus(),
              ),
            ],
          ),
        );
      }
    });
    return KeyboardActionsConfig(actions: actions, nextFocus: true);
  }

  Widget _buildTroopInputs(String label, List<Map<String, dynamic>> entries) {
    final loc = AppLocalizations.of(context);
    String localizedLabel = label;
    if (label == 'Infantry') localizedLabel = loc?.infantry ?? 'Infantry';
    if (label == 'Marksmen') localizedLabel = loc?.marksmen ?? 'Marksmen';
    if (label == 'Lancers') localizedLabel = loc?.lancers ?? 'Lancers';

    // Emoji / icon mapping
    final emoji = label == 'Infantry'
        ? '🛡️'
        : label == 'Marksmen'
        ? '🏹'
        : '🗡️';
    final color = label == 'Infantry'
        ? Colors.blueAccent
        : label == 'Marksmen'
        ? Colors.indigo
        : Colors.redAccent;

    int categoryTotal = 0;
    for (var e in entries) {
      categoryTotal += int.tryParse(e['count'].text.replaceAll(',', '')) ?? 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: color,
          collapsedIconColor: color,
          leading: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(
            localizedLabel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(.35)),
            ),
            child: Text(
              NumberFormat('#,###').format(categoryTotal),
              style: TextStyle(
                color: HSLColor.fromColor(color)
                    .withLightness(
                      (HSLColor.fromColor(color).lightness - .15).clamp(
                        0.0,
                        1.0,
                      ),
                    )
                    .toColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                children: [
                  ...entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final focus = _focusMap[label]![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: data['count'],
                              focusNode: focus,
                              inputFormatters: [CommaTextInputFormatter()],
                              onChanged: (_) {
                                _recalculateTotal();
                                _saveData();
                              },
                              onEditingComplete: () =>
                                  FocusScope.of(context).unfocus(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: loc?.amount ?? 'Amount',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.black12,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: DropdownButton<int>(
                              value: data['level'],
                              isDense: true,
                              borderRadius: BorderRadius.circular(12),
                              underline: const SizedBox(),
                              iconSize: 20,
                              onChanged: (value) {
                                setState(() {
                                  data['level'] = value!;
                                });
                                _saveData();
                              },
                              items: List.generate(10, (i) {
                                final val = i + 1;
                                return DropdownMenuItem(
                                  value: val,
                                  child: Text(
                                    'Lv $val',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }),
                            ),
                          ),
                          if (entries.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              splashRadius: 18,
                              onPressed: () {
                                setState(() {
                                  entries.removeAt(index);
                                  _ensureFocusExact(label, entries.length);
                                });
                                _saveData();
                                _recalculateTotal();
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addEntry(label),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(loc?.addMoreTroops ?? 'Add more troops'),
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      for (var type in _troopsData.keys) {
        _troopsData[type] = [
          {'count': TextEditingController(), 'level': 1},
        ];
        _ensureFocusExact(type, 1);
      }
      _totalTroops = 0;
      _seen = {};
    });
    await _saveCloud(); // <-- clear cloud copy as well
  }

  // --- Cloud sync helpers ---
  Future<void> _saveCloud() async {
    try {
      final Map<String, dynamic> serialized = {};
      _troopsData.forEach((type, list) {
        serialized[type] = list.map((e) {
          return {
            'count': int.tryParse(e['count'].text.replaceAll(',', '')) ?? 0,
            'level': e['level'] ?? 1,
          };
        }).toList();
      });
      await CloudSyncService.save('troops_data', {
        'troops': serialized,
        'seen': _seen,
      });
    } catch (e) {
      debugPrint('Failed to save troops to cloud: $e');
    }
  }

  Future<void> _loadCloudData() async {
    try {
      final data = await CloudSyncService.load('troops_data');
      if (data == null) return;
      final troops = data['troops'] as Map<dynamic, dynamic>?;
      if (troops != null) {
        troops.forEach((typeRaw, listRaw) {
          final type = typeRaw.toString();
          if (!_troopsData.containsKey(type)) return;
          final List<Map<String, dynamic>> entries = [];
          for (var item in (listRaw as List<dynamic>)) {
            final count = (item['count'] ?? 0) as int;
            final level = (item['level'] ?? 1) as int;
            entries.add({
              'count': TextEditingController(
                text: NumberFormat('#,###').format(count),
              ),
              'level': level,
            });
          }
          if (entries.isEmpty) {
            entries.add({'count': TextEditingController(), 'level': 1});
          }
          _troopsData[type] = entries;
          _ensureFocusExact(type, entries.length);
        });
      }
      final seenMap = data['seen'] as Map<dynamic, dynamic>?;
      if (seenMap != null) {
        final loaded = <String, bool>{};
        seenMap.forEach((k, v) {
          loaded[k.toString()] = v == true;
        });
        setState(() => _seen = loaded);
      }
      _recalculateTotal();
      setState(() {});
    } catch (e) {
      debugPrint('Failed to load troops from cloud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
                        // Already here; optionally no-op or pop.
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
      body: KeyboardActions(
        config: _keyboardConfig(),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _TroopsHeroSection()),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        for (var entry in _troopsData.entries)
                          _buildTroopInputs(entry.key, entry.value),
                        Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.blueGrey.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calculate,
                                size: 20,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${loc?.totalTroops ?? 'Total Troops'}: ${_formatNumber(_totalTroops)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _resetAll,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: Text(
                                  '🔁 ${loc?.resetAll ?? 'Reset All'}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: GradientTileButton(
                                label:
                                    loc?.bearTrapTroopsTitle ??
                                    'Bear Trap Troops',
                                showBadge: _seen['bear_trap_troops'] == false,
                                onTap: () {
                                  _markSeen('bear_trap_troops');
                                  _saveData();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const BearTrapTroopsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            AspectRatio(
                              aspectRatio: 1,
                              child: GradientTileButton(
                                label:
                                    loc?.crazyJoeTroopsTitle ??
                                    'Crazy Joe Troops',
                                showBadge: _seen['crazy_joe_troops'] == false,
                                onTap: () {
                                  _markSeen('crazy_joe_troops');
                                  _saveData();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CrazyJoeTroopsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            AspectRatio(
                              aspectRatio: 1,
                              child: GradientTileButton(
                                label:
                                    loc?.troopTrainingCalculatorTitle ??
                                    'Troop Training Calculator',
                                showBadge:
                                    _seen['troop_training_calculator'] == false,
                                onTap: () {
                                  _markSeen('troop_training_calculator');
                                  _saveData();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TroopTrainingCalculatorPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            AspectRatio(
                              aspectRatio: 1,
                              child: GradientTileButton(
                                label:
                                    loc?.heliosCalculatorTitle ??
                                    'Helios Calculator',
                                showBadge: _seen['helios_calculator'] == false,
                                onTap: () {
                                  _markSeen('helios_calculator');
                                  _saveData();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HeliosCalculatorPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: _TroopsFooter()),
          ],
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
    );
  }
}

class CommaTextInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    final number = int.tryParse(text);
    if (number == null) return oldValue;

    final newText = _formatter.format(number);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class GradientTileButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool showBadge;
  final List<Color> gradientColors;
  final double borderRadius;
  final double fontSize;
  final double elevation;

  const GradientTileButton({
    super.key,
    required this.label,
    required this.onTap,
    this.showBadge = false,
    this.gradientColors = const [
      Color(0xFF1976D2),
      Color(0xFF42A5F5),
    ], // blue gradient
    this.borderRadius = 22,
    this.fontSize = 18,
    this.elevation = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1, // Ensures a perfect square
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              if (showBadge)
                const Positioned(
                  top: 12,
                  right: 18,
                  child: CircleAvatar(radius: 7, backgroundColor: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TroopsHeroSection extends StatelessWidget {
  const _TroopsHeroSection();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C2A78), Color(0xFF4A1D88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Troops Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TroopsFooter extends StatelessWidget {
  const _TroopsFooter();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Column(
          children: const [
            Text('© 2025 Survival Planner'),
            SizedBox(height: 6),
            Text(
              'Built with Flutter — Web Edition',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
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
