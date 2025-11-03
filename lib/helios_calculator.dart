import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/cloud_sync_service.dart';
import 'helios/marksman_helios_calculator.dart';
import 'helios/infantry_helios_calculator.dart';
import 'helios/lancers_helios_calculator.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'services/analytics_service.dart';

class HeliosCalculatorPage extends StatefulWidget {
  const HeliosCalculatorPage({super.key});

  @override
  State<HeliosCalculatorPage> createState() => _HeliosCalculatorPageState();
}

class _HeliosCalculatorPageState extends State<HeliosCalculatorPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController conversionController = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###');

  int totalCrystals = 0;
  int totalSteel = 0;
  int infantryCrystals = 0;
  int lancersCrystals = 0;
  int marksmanCrystals = 0;
  int converted = 0;

  bool showDetails = false;
  bool _loading = true;

  Timer? _cloudTimer;
  late AnimationController _anim;
  final FocusNode _conversionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('HeliosCalculatorPage');
    _anim =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    conversionController.text = '13';
    converted = 1;
    _initLoad();
    _cloudTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _saveCloud());
    Future.delayed(const Duration(seconds: 2), _saveCloud);
  }

  Future<void> _initLoad() async {
    await _loadTotals();
    await _loadCloud();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadTotals() async {
    final prefs = await SharedPreferences.getInstance();
    final iCrystals = prefs.getInt('helios_infantry_crystals') ?? 0;
    final iSteel = prefs.getInt('helios_infantry_steel') ?? 0;
    final lCrystals = prefs.getInt('helios_lancer_crystals') ?? 0;
    final lSteel = prefs.getInt('helios_lancer_steel') ?? 0;
    final mCrystals = prefs.getInt('helios_marksman_crystals') ?? 0;
    final mSteel = prefs.getInt('helios_marksman_steel') ?? 0;
    setState(() {
      totalCrystals = iCrystals + lCrystals + mCrystals;
      totalSteel = iSteel + lSteel + mSteel;
      infantryCrystals = iCrystals;
      lancersCrystals = lCrystals;
      marksmanCrystals = mCrystals;
    });
    _saveCloud();
  }

  Future<void> _saveCloud() async {
    await CloudSyncService.save('helios_calculator', {
      'totalCrystals': totalCrystals,
      'totalSteel': totalSteel,
      'infantryCrystals': infantryCrystals,
      'lancersCrystals': lancersCrystals,
      'marksmanCrystals': marksmanCrystals,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load('helios_calculator');
    if (data == null || !mounted) return;
    setState(() {
      totalCrystals = data['totalCrystals'] ?? totalCrystals;
      totalSteel = data['totalSteel'] ?? totalSteel;
      infantryCrystals = data['infantryCrystals'] ?? infantryCrystals;
      lancersCrystals = data['lancersCrystals'] ?? lancersCrystals;
      marksmanCrystals = data['marksmanCrystals'] ?? marksmanCrystals;
    });
  }

  Future<void> _resetAllTotals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('helios_infantry_crystals');
    await prefs.remove('helios_infantry_steel');
    await prefs.remove('helios_lancer_crystals');
    await prefs.remove('helios_lancer_steel');
    await prefs.remove('helios_marksman_crystals');
    await prefs.remove('helios_marksman_steel');
    setState(() {
      totalCrystals = 0;
      totalSteel = 0;
      infantryCrystals = 0;
      lancersCrystals = 0;
      marksmanCrystals = 0;
      showDetails = false;
      conversionController.text = '13';
      converted = 1;
    });
    _saveCloud();
  }

  String _format(int number) => _formatter.format(number);

  @override
  void dispose() {
    _cloudTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text('Helios Calculator'),
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadTotals();
                  await _loadCloud();
                },
                child: KeyboardActions(
                  config: KeyboardActionsConfig(
                    actions: [
                      KeyboardActionsItem(
                        focusNode: _conversionFocus,
                        toolbarButtons: [
                          (node) => IconButton(
                                icon:
                                    const Icon(Icons.check, color: Colors.green),
                                onPressed: () => node.unfocus(),
                              )
                        ],
                      ),
                    ],
                    nextFocus: true,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          16 + MediaQuery.of(context).padding.bottom + 70,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 40,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _headerCard(),
                              const SizedBox(height: 20),
                              _heliosNavRow(),
                              const SizedBox(height: 20),
                              _conversionCard(),
                              const SizedBox(height: 20),
                              _totalsCard(),
                              const SizedBox(height: 16),
                              _detailsExpansion(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _resetAllTotals,
        backgroundColor: Colors.red.shade400,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Reset'),
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
              const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Helios Resources',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _loadTotals();
                },
                icon: const Icon(Icons.refresh, color: Colors.white70),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text('Track shards, convert and jump into class specifics.',
              style: TextStyle(color: Colors.white.withOpacity(.85))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('${_format(totalCrystals)} Shards', Icons.auto_awesome,
                  Colors.amber.shade300),
              _pill('${_format((totalCrystals / 13).ceil())} Crystals',
                  Icons.bubble_chart, Colors.cyan.shade300),
              _pill('${_format(totalSteel)} Steel', Icons.construction,
                  Colors.blueGrey.shade200),
            ],
          )
        ],
      ),
    );
  }

  Widget _heliosNavRow() {
    return Row(
      children: [
        Expanded(
          child: _navTile(
            label: 'Infantry',
            icon: Icons.shield,
            color1: Colors.deepPurple.shade300,
            color2: Colors.purple.shade600,
            onTap: () => _open(const FullHeliosCalculatorPage()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _navTile(
            label: 'Lancers',
            icon: Icons.speed,
            color1: Colors.indigo.shade300,
            color2: Colors.indigo.shade600,
            onTap: () => _open(const LancerHeliosCalculatorPage()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _navTile(
            label: 'Marksman',
            icon: Icons.gps_fixed,
            color1: Colors.teal.shade300,
            color2: Colors.teal.shade600,
            onTap: () => _open(const MarksmanHeliosCalculatorPage()),
          ),
        ),
      ],
    );
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _loadTotals();
  }

  Widget _navTile({
    required String label,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final t = (0.5 + 0.5 * (_anim.value)).clamp(0.0, 1.0);
          return AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(color1, color2, 0.15)!,
                    Color.lerp(color2, color1, 0.25 + 0.25 * t)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: color2.withOpacity(.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Icon(icon,
                        size: 34, color: Colors.white.withOpacity(.85)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _conversionCard() {
    return _sectionCard(
      title: 'Shard Conversion',
      icon: Icons.swap_horiz,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: conversionController,
            focusNode: _conversionFocus,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Shard Input',
              filled: true,
              fillColor: Colors.deepPurple.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.toll),
            ),
            onChanged: (value) {
              final input = int.tryParse(value) ?? 0;
              setState(() => converted = (input / 13).ceil());
            },
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniPill('${_format(converted)} Fire Crystals', Icons.whatshot,
                  Colors.deepPurple.shade100, Colors.deepPurple.shade500),
              _miniPill('${_format((converted * 13))} Shards Used',
                  Icons.data_usage, Colors.indigo.shade100, Colors.indigo),
            ],
          )
        ],
      ),
    );
  }

  Widget _totalsCard() {
    return _sectionCard(
      title: 'Totals',
      icon: Icons.summarize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Shards',
                  value: _format(totalCrystals),
                  color: Colors.amber.shade600,
                  icon: Icons.auto_awesome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  label: 'Crystals',
                  value: _format((totalCrystals / 13).ceil()),
                  color: Colors.cyan.shade600,
                  icon: Icons.bubble_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statTile(
            label: 'Steel',
            value: _format(totalSteel),
            color: Colors.blueGrey.shade600,
            icon: Icons.construction,
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _detailsExpansion() {
    return _sectionCard(
      title: 'Breakdown',
      icon: Icons.insights,
      trailing: IconButton(
        icon: Icon(showDetails ? Icons.expand_less : Icons.expand_more),
        onPressed: () => setState(() => showDetails = !showDetails),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 250),
        crossFadeState:
            showDetails ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breakRow('Infantry', infantryCrystals, Colors.purple.shade400),
            _breakRow('Lancers', lancersCrystals, Colors.indigo.shade400),
            _breakRow('Marksman', marksmanCrystals, Colors.teal.shade500),
            const SizedBox(height: 4),
            Text('Tap class tiles above to update values.',
                style: TextStyle(
                    fontSize: 12, color: Colors.black.withOpacity(.55))),
          ],
        ),
        secondChild: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('Tap to view per-class shard totals',
              style: TextStyle(color: Colors.black.withOpacity(.55))),
        ),
      ),
    );
  }

  Widget _breakRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(_format(value),
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool expanded = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(.8), color.withOpacity(.55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(.9))),
                const SizedBox(height: 2),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color.darken())),
                ),
              ],
            ),
          ),
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

  Widget _miniPill(String text, IconData icon, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(fontWeight: FontWeight.w600, color: accent)),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade100.withOpacity(.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
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
                      Colors.indigo.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
