import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import '../services/purchase_service.dart';
import '../services/paywall_helper.dart';
import '../services/analytics_service.dart';

class ArmamentCompetitionPage extends StatefulWidget {
  const ArmamentCompetitionPage({super.key});

  @override
  State<ArmamentCompetitionPage> createState() =>
      _ArmamentCompetitionPageState();
}

class _ArmamentCompetitionPageState extends State<ArmamentCompetitionPage> {
  late SharedPreferences _prefs;
  final _formatter = NumberFormat('#,###');

  final Map<String, TextEditingController> _controllers = {
    'construction_days': TextEditingController(),
    'construction_hours': TextEditingController(),
    'construction_minutes': TextEditingController(),
    'research_days': TextEditingController(),
    'research_hours': TextEditingController(),
    'research_minutes': TextEditingController(),
    'troop_days': TextEditingController(),
    'troop_hours': TextEditingController(),
    'troop_minutes': TextEditingController(),
    'fire_crystal': TextEditingController(),
    'refined_fire_crystal': TextEditingController(),
    'mithril': TextEditingController(),
    'essence_stone': TextEditingController(),
    'hero_widget': TextEditingController(),
  };
  final Map<String, FocusNode> _focusNodes = {};

  int _speedupPoints = 0;
  int _heroPoints = 0;
  int _fireCrystalPoints = 0;
  String _result = '';

  final BorderRadius _cardRadius = BorderRadius.circular(14);
  final Color _cardBg = const Color(0xFFF7F8FA);
  final Color _accent = const Color(0xFF00695C);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('ArmamentCompetitionPage');
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
    final construction = _getTotalMinutes(
        'construction_days', 'construction_hours', 'construction_minutes');
    final research =
        _getTotalMinutes('research_days', 'research_hours', 'research_minutes');
    final troop =
        _getTotalMinutes('troop_days', 'troop_hours', 'troop_minutes');

    final fireCrystal =
        (int.tryParse(_controllers['fire_crystal']!.text) ?? 0) *
            100; // event-specific scaling
    final refinedFireCrystal =
        (int.tryParse(_controllers['refined_fire_crystal']!.text) ?? 0) * 1500;
    final mithril = (int.tryParse(_controllers['mithril']!.text) ?? 0) * 28800;
    final essenceStone =
        (int.tryParse(_controllers['essence_stone']!.text) ?? 0) * 800;
    final heroWidget =
        (int.tryParse(_controllers['hero_widget']!.text) ?? 0) * 1600;

    _speedupPoints =
        construction + research + troop; // already minutes -> 1 point/min
    _heroPoints =
        essenceStone + heroWidget + mithril; // treat mithril as hero group here
    _fireCrystalPoints = fireCrystal + refinedFireCrystal;

    final total = _speedupPoints + _heroPoints + _fireCrystalPoints;
    setState(() =>
        _result = 'Armament Competition Points: ${_formatter.format(total)}');
  }

  void _resetAll() {
    _controllers.forEach((key, ctrl) {
      ctrl.clear();
      _prefs.remove(key);
    });
    setState(() => _result = 'Armament Competition Points: 0');
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
          Row(children: [
            Icon(Icons.timer_outlined,
                size: 18, color: _accent.withOpacity(.75)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
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

  Widget _buildNumericInput(String label, String key, String hint) {
    final bool gated = !PurchaseService.isPremium && (label == 'Mithril');
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
              hintText: hint,
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
      appBar: AppBar(title: const Text('Armament Competition')),
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
                    color: Colors.teal,
                    chipValue: _speedupPoints,
                    child: Column(children: [
                      _buildTimeRow(
                          'Construction Speed Ups (1 point/min)',
                          'construction_days',
                          'construction_hours',
                          'construction_minutes'),
                      _buildTimeRow(
                          'Research Speed Ups (1 point/min)',
                          'research_days',
                          'research_hours',
                          'research_minutes'),
                      _buildTimeRow('Troop Speed Ups (1 point/min)',
                          'troop_days', 'troop_hours', 'troop_minutes'),
                    ]),
                  ),
                  _sectionCard(
                    context,
                    title: 'Resources & Items',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.deepPurple,
                    chipValue: _heroPoints,
                    child: Column(children: [
                      _buildNumericInput(
                          'Mithril', 'mithril', '28,800 points per 1'),
                      _buildNumericInput(
                          'Essence Stone', 'essence_stone', '800 points per 1'),
                      _buildNumericInput(
                          'Hero Widget', 'hero_widget', '1600 points per 1'),
                    ]),
                  ),
                  _sectionCard(
                    context,
                    title: 'Fire Crystal',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.redAccent,
                    chipValue: _fireCrystalPoints,
                    child: Column(children: [
                      _buildNumericInput(
                          'Fire Crystal', 'fire_crystal', '100 points per 1'),
                      _buildNumericInput('Refined Fire Crystal',
                          'refined_fire_crystal', '1500 points per 1'),
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
