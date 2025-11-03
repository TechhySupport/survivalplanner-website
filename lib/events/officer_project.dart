import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

class OfficerProjectPage extends StatefulWidget {
  const OfficerProjectPage({super.key});

  @override
  State<OfficerProjectPage> createState() => _OfficerProjectPageState();
}

class _OfficerProjectPageState extends State<OfficerProjectPage> {
  final _essenceController = TextEditingController();
  final _mithrilController = TextEditingController();

  final _marksmenLevel = ValueNotifier<int>(1);
  final _marksmenTotalController = TextEditingController();

  final _infantryLevel = ValueNotifier<int>(1);
  final _infantryTotalController = TextEditingController();

  final _lancersLevel = ValueNotifier<int>(1);
  final _lancersTotalController = TextEditingController();

  int _resourcesPoints = 0;
  int _marksmenPoints = 0;
  int _infantryPoints = 0;
  int _lancersPoints = 0;
  String _result = '';
  final _formatter = NumberFormat('#,###');

  final BorderRadius _cardRadius = BorderRadius.circular(14);
  final Color _cardBg = const Color(0xFFF7F8FA);
  final Color _accent = const Color(0xFF2E7D32);
  final Map<String, FocusNode> _focusNodes = {
    'essence': FocusNode(),
    'mithril': FocusNode(),
    'marksmen_total': FocusNode(),
    'infantry_total': FocusNode(),
    'lancers_total': FocusNode(),
  };

  static const Map<int, int> levelPoints = {
    1: 1,
    2: 2,
    3: 3,
    4: 4,
    5: 6,
    6: 9,
    7: 12,
    8: 17,
    9: 22,
    10: 30,
    11: 37,
  };

  void _calculate() {
    final essence = (int.tryParse(_essenceController.text) ?? 0) * 6000;
    final mithril = (int.tryParse(_mithrilController.text) ?? 0) * 216000;
    _resourcesPoints = essence + mithril;

    final marksmenLevel = _marksmenLevel.value;
    final marksmenTotal = int.tryParse(_marksmenTotalController.text) ?? 0;
    _marksmenPoints = levelPoints[marksmenLevel]! * marksmenTotal;

    final infantryLevel = _infantryLevel.value;
    final infantryTotal = int.tryParse(_infantryTotalController.text) ?? 0;
    _infantryPoints = levelPoints[infantryLevel]! * infantryTotal;

    final lancersLevel = _lancersLevel.value;
    final lancersTotal = int.tryParse(_lancersTotalController.text) ?? 0;
    _lancersPoints = levelPoints[lancersLevel]! * lancersTotal;

    final total =
        _resourcesPoints + _marksmenPoints + _infantryPoints + _lancersPoints;
    setState(
        () => _result = 'Officer Project Points: ${_formatter.format(total)}');
  }

  void _resetAll() {
    _essenceController.clear();
    _mithrilController.clear();
    _marksmenLevel.value = 1;
    _marksmenTotalController.clear();
    _infantryLevel.value = 1;
    _infantryTotalController.clear();
    _lancersLevel.value = 1;
    _lancersTotalController.clear();
    setState(() => _result = 'Officer Project Points: 0');
  }

  Future<void> _saveToPrefs(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('OfficerProjectPage');
    _essenceController.addListener(() {
      _calculate();
      _saveToPrefs('essence_stone', _essenceController.text);
    });
    _mithrilController.addListener(() {
      _calculate();
      _saveToPrefs('mithril', _mithrilController.text);
    });
    _marksmenTotalController.addListener(() {
      _calculate();
      _saveToPrefs('marksmen_total', _marksmenTotalController.text);
    });
    _infantryTotalController.addListener(() {
      _calculate();
      _saveToPrefs('infantry_total', _infantryTotalController.text);
    });
    _lancersTotalController.addListener(() {
      _calculate();
      _saveToPrefs('lancers_total', _lancersTotalController.text);
    });
    _marksmenLevel.addListener(() {
      _calculate();
      _saveToPrefs('marksmen_level', _marksmenLevel.value.toString());
    });
    _infantryLevel.addListener(() {
      _calculate();
      _saveToPrefs('infantry_level', _infantryLevel.value.toString());
    });
    _lancersLevel.addListener(() {
      _calculate();
      _saveToPrefs('lancers_level', _lancersLevel.value.toString());
    });
    _calculate();
  }

  @override
  void dispose() {
    _essenceController.dispose();
    _mithrilController.dispose();
    _marksmenLevel.dispose();
    _marksmenTotalController.dispose();
    _infantryLevel.dispose();
    _infantryTotalController.dispose();
    _lancersLevel.dispose();
    _lancersTotalController.dispose();
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  KeyboardActionsConfig _keyboardConfig() {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      actions: [
        for (final key in _focusNodes.keys)
          KeyboardActionsItem(
            focusNode: _focusNodes[key]!,
            toolbarButtons: [
              (node) => IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Done',
                    onPressed: () => node.unfocus(),
                  ),
            ],
          ),
      ],
    );
  }

  Widget _buildNumericInput(
      String label, TextEditingController controller, String hint) {
    return Container(
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
            controller: controller,
            focusNode: label == 'Essence Stone'
                ? _focusNodes['essence']
                : label == 'Mithril'
                    ? _focusNodes['mithril']
                    : null,
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
          ),
        ],
      ),
    );
  }

  Widget _buildTroopRow(String label, ValueNotifier<int> level,
      TextEditingController totalController) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _cardRadius,
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(Icons.military_tech_outlined,
              size: 20, color: _accent.withOpacity(.75)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(children: [
                  ValueListenableBuilder<int>(
                    valueListenable: level,
                    builder: (context, value, _) {
                      return DropdownButton<int>(
                        value: value,
                        isDense: true,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                        items: List.generate(11, (i) => i + 1)
                            .map((lvl) => DropdownMenuItem(
                                value: lvl, child: Text('Lvl $lvl')))
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            level.value = newValue;
                            _calculate();
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 12),
          SizedBox(
                    width: 90,
                    child: TextField(
                      controller: totalController,
            focusNode: label == 'Marksmen'
              ? _focusNodes['marksmen_total']
              : label == 'Infantry'
                ? _focusNodes['infantry_total']
                : _focusNodes['lancers_total'],
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        hintText: 'Total',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? emoji, // optional override for icon using emoji
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: emoji != null
                ? Text(emoji, style: const TextStyle(fontSize: 20))
                : Icon(icon, color: Colors.white, size: 22),
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
      appBar: AppBar(title: const Text('Officer Project')),
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
                    title: 'Resources',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.teal,
                    chipValue: _resourcesPoints,
                    child: Column(children: [
                      _buildNumericInput('Essence Stone', _essenceController,
                          '6,000 points per 1'),
                      _buildNumericInput('Mithril', _mithrilController,
                          '216,000 points per 1'),
                    ]),
                  ),
                  _sectionCard(
                    context,
                    title: 'Marksmen',
                    icon: Icons.person_pin_outlined,
                    emoji: '🏹',
                    color: Colors.indigoAccent,
                    chipValue: _marksmenPoints,
                    child: _buildTroopRow(
                        'Marksmen', _marksmenLevel, _marksmenTotalController),
                  ),
                  _sectionCard(
                    context,
                    title: 'Infantry',
                    icon: Icons.shield_outlined,
                    color: Colors.deepPurple,
                    chipValue: _infantryPoints,
                    child: _buildTroopRow(
                        'Infantry', _infantryLevel, _infantryTotalController),
                  ),
                  _sectionCard(
                    context,
                    title: 'Lancers',
                    icon: Icons.directions_run_outlined,
                    emoji: '🗡️',
                    color: Colors.redAccent,
                    chipValue: _lancersPoints,
                    child: _buildTroopRow(
                        'Lancers', _lancersLevel, _lancersTotalController),
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
