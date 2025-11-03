import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import '../services/purchase_service.dart';
import '../services/paywall_helper.dart';
import '../services/analytics_service.dart';

class KingOfIcefieldPage extends StatefulWidget {
  const KingOfIcefieldPage({super.key});

  @override
  State<KingOfIcefieldPage> createState() => _KingOfIcefieldPageState();
}

class _KingOfIcefieldPageState extends State<KingOfIcefieldPage> {
  late SharedPreferences _prefs;
  final _formatter = NumberFormat('#,###');

  final Map<String, TextEditingController> _controllers = {
    'king_construction_days': TextEditingController(),
    'king_construction_hours': TextEditingController(),
    'king_construction_minutes': TextEditingController(),
    'king_research_days': TextEditingController(),
    'king_research_hours': TextEditingController(),
    'king_research_minutes': TextEditingController(),
    'king_troop_days': TextEditingController(),
    'king_troop_hours': TextEditingController(),
    'king_troop_minutes': TextEditingController(),
    'king_general_days': TextEditingController(),
    'king_general_hours': TextEditingController(),
    'king_general_minutes': TextEditingController(),
    'king_hero_widgets': TextEditingController(),
    'king_rare_shards': TextEditingController(),
    'king_epic_shards': TextEditingController(),
    'king_mystic_shards': TextEditingController(),
    'king_mithril': TextEditingController(),
    'king_refined_fire_crystal': TextEditingController(),
    'king_fire_crystal': TextEditingController(),
    'king_refined_fire_crystal_shards': TextEditingController(),
    'king_essence_stone': TextEditingController(),
  };
  final Map<String, FocusNode> _focusNodes = {};

  int _speedupPoints = 0;
  int _heroPoints = 0;
  int _fireCrystalPoints = 0;
  String _result = '';

  final BorderRadius _cardRadius = BorderRadius.circular(14);
  final Color _cardBg = const Color(0xFFF7F8FA);
  final Color _accent = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('KingOfIcefieldPage');
    _initPrefsAndListeners();
    for (final key in _controllers.keys) {
      _focusNodes[key] = FocusNode();
    }
  }

  Future<void> _initPrefsAndListeners() async {
    _prefs = await SharedPreferences.getInstance();
    _controllers.forEach((key, ctrl) {
      final saved = _prefs.getString(key);
      if (saved != null) ctrl.text = saved;
      ctrl.addListener(() {
        _prefs.setString(key, ctrl.text);
        _calculate();
      });
    });
    _calculate();
  }

  int _getTotalMinutes(String dKey, String hKey, String mKey) {
    final d = int.tryParse(_controllers[dKey]!.text) ?? 0;
    final h = int.tryParse(_controllers[hKey]!.text) ?? 0;
    final m = int.tryParse(_controllers[mKey]!.text) ?? 0;
    return d * 24 * 60 + h * 60 + m;
  }

  void _calculate() {
    final c = _getTotalMinutes('king_construction_days',
        'king_construction_hours', 'king_construction_minutes');
    final r = _getTotalMinutes(
        'king_research_days', 'king_research_hours', 'king_research_minutes');
    final t = _getTotalMinutes(
        'king_troop_days', 'king_troop_hours', 'king_troop_minutes');
    final g = _getTotalMinutes(
        'king_general_days', 'king_general_hours', 'king_general_minutes');

    final widgets =
        (int.tryParse(_controllers['king_hero_widgets']!.text) ?? 0) * 8000;
    final rare =
        (int.tryParse(_controllers['king_rare_shards']!.text) ?? 0) * 350;
    final epic =
        (int.tryParse(_controllers['king_epic_shards']!.text) ?? 0) * 1220;
    final mystic =
        (int.tryParse(_controllers['king_mystic_shards']!.text) ?? 0) * 3040;
    final mithril =
        (int.tryParse(_controllers['king_mithril']!.text) ?? 0) * 144000;
    final refinedFireCrystal =
        (int.tryParse(_controllers['king_refined_fire_crystal']!.text) ?? 0) *
            30000;
    final fireCrystal =
        (int.tryParse(_controllers['king_fire_crystal']!.text) ?? 0) * 2000;
    final refinedFireCrystalShards =
        (int.tryParse(_controllers['king_refined_fire_crystal_shards']!.text) ??
                0) *
            1000;
    final essenceStone =
        (int.tryParse(_controllers['king_essence_stone']!.text) ?? 0) * 4000;

    _speedupPoints = (c + r + t + g) * 30;
    _heroPoints = widgets + rare + epic + mystic + mithril + essenceStone;
    _fireCrystalPoints =
        refinedFireCrystal + fireCrystal + refinedFireCrystalShards;
    final total = _speedupPoints + _heroPoints + _fireCrystalPoints;
    setState(
        () => _result = 'King of Icefield Points: ${_formatter.format(total)}');
  }

  void _resetAll() {
    _controllers.forEach((key, ctrl) {
      ctrl.clear();
      _prefs.remove(key);
    });
    setState(() => _result = 'King of Icefield Points: 0');
  }

  KeyboardActionsConfig _keyboardConfig() {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      actions: _controllers.keys
          .map(
            (key) => KeyboardActionsItem(
              focusNode: _focusNodes[key]!,
              toolbarButtons: [
                (node) => IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Done',
                      onPressed: () => node.unfocus(),
                    ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildTimeRow(String label, String d, String h, String m) {
    final bool gated = !PurchaseService.isPremium &&
        (label.contains('Construction') || label.contains('Research'));
    InputDecoration dec(String lbl) => InputDecoration(
          labelText: lbl,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        );
    final content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _cardRadius,
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 18, color: _accent.withOpacity(.75)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
              controller: _controllers[d],
              focusNode: _focusNodes[d],
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration: dec('Days'),
              enabled: !gated,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
              controller: _controllers[h],
              focusNode: _focusNodes[h],
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration: dec('Hours'),
              enabled: !gated,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
              controller: _controllers[m],
              focusNode: _focusNodes[m],
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration: dec('Minutes'),
              enabled: !gated,
            )),
          ]),
        ],
      ),
    );
    if (!gated) return content;
    return Stack(children: [
      content,
      Positioned.fill(
        child: Material(
          color: Colors.white.withOpacity(0.65),
          borderRadius: _cardRadius,
          child: InkWell(
            borderRadius: _cardRadius,
            onTap: () => PaywallHelper.show(context),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.lock, size: 18, color: Colors.black54),
                SizedBox(width: 6),
                Text('Premium Required',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildNumericInput(String label, String key) {
    final bool gated = !PurchaseService.isPremium &&
        (label == 'Mystic Hero Shards' ||
            label == 'Mithril' ||
            label == 'Refined Fire Crystal Shards');
    final container = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _cardRadius,
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.adjust_rounded,
                size: 18, color: _accent.withOpacity(.75)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers[key],
            focusNode: _focusNodes[key],
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            enabled: !gated,
          ),
        ],
      ),
    );
    if (!gated) return container;
    return Stack(children: [
      container,
      Positioned.fill(
        child: Material(
          color: Colors.white.withOpacity(0.65),
          borderRadius: _cardRadius,
          child: InkWell(
            borderRadius: _cardRadius,
            onTap: () => PaywallHelper.show(context),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.lock, size: 18, color: Colors.black54),
                SizedBox(width: 6),
                Text('Premium Required',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required int chipValue,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(.35)),
            ),
            child: Text(
              _formatter.format(chipValue),
              style:
                  TextStyle(color: color.darken(), fontWeight: FontWeight.w600),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('King of Icefield Calculator')),
      body: Column(
        children: [
          Expanded(
            child: KeyboardActions(
              config: _keyboardConfig(),
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionCard(
                    context,
                    title: 'Speed Ups',
                    icon: Icons.flash_on_rounded,
                    color: Colors.indigoAccent,
                    chipValue: _speedupPoints,
                    child: Column(children: [
                      _buildTimeRow(
                          'Construction Speed Ups',
                          'king_construction_days',
                          'king_construction_hours',
                          'king_construction_minutes'),
                      _buildTimeRow('Research Speed Ups', 'king_research_days',
                          'king_research_hours', 'king_research_minutes'),
                      _buildTimeRow(
                          'Troop Training Speed Ups',
                          'king_troop_days',
                          'king_troop_hours',
                          'king_troop_minutes'),
                      _buildTimeRow('General Speed Ups', 'king_general_days',
                          'king_general_hours', 'king_general_minutes'),
                    ]),
                  ),
                  _sectionCard(
                    context,
                    title: 'Heroes & Items',
                    icon: Icons.shield_moon_outlined,
                    color: Colors.deepPurple,
                    chipValue: _heroPoints,
                    child: Column(children: [
                      _buildNumericInput('Hero Widgets', 'king_hero_widgets'),
                      _buildNumericInput(
                          'Rare Hero Shards', 'king_rare_shards'),
                      _buildNumericInput(
                          'Epic Hero Shards', 'king_epic_shards'),
                      _buildNumericInput(
                          'Mystic Hero Shards', 'king_mystic_shards'),
                      _buildNumericInput('Mithril', 'king_mithril'),
                      _buildNumericInput('Essence Stone', 'king_essence_stone'),
                    ]),
                  ),
                  _sectionCard(
                    context,
                    title: 'Fire Crystal',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.redAccent,
                    chipValue: _fireCrystalPoints,
                    child: Column(children: [
                      _buildNumericInput('Fire Crystal', 'king_fire_crystal'),
                      _buildNumericInput(
                          'Refined Fire Crystal', 'king_refined_fire_crystal'),
                      _buildNumericInput('Refined Fire Crystal Shards',
                          'king_refined_fire_crystal_shards'),
                    ]),
                  ),
                ],
              ),
              ),
            ),
          ),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                Text(
                  _result,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _resetAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset All'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


extension _ColorShade on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    final adjusted =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return adjusted.toColor();
  }
}
