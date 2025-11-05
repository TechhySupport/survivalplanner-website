import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloud_sync_service.dart'; // <-- cloud
import 'package:keyboard_actions/keyboard_actions.dart';
import '../services/analytics_service.dart';
import 'utc_badge.dart';
import 'settings_page.dart';
import '../services/loginscreen.dart';
import 'bottom_nav_bar.dart';
import 'web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'event_page.dart';
import 'troops_page.dart';

class BearTrapTroopsPage extends StatefulWidget {
  const BearTrapTroopsPage({super.key});

  @override
  State<BearTrapTroopsPage> createState() => _BearTrapTroopsPageState();
}

class _BearTrapTroopsPageState extends State<BearTrapTroopsPage> {
  int rallyMarch = 1;

  final leadCapacityController = TextEditingController();
  final joinerCapacityController = TextEditingController();
  final infantryRatioController = TextEditingController();
  final riderRatioController = TextEditingController();
  final hunterRatioController = TextEditingController();
  final joinerInfantryRatio = TextEditingController();
  final joinerMarksmenRatio = TextEditingController();
  final joinerLancerRatio = TextEditingController();

  final _formatter = NumberFormat('#,###');
  int totalTroops = 0;
  int infantryTotal = 0;
  int marksmenTotal = 0;
  int lancersTotal = 0;
  bool sameJoinerRatio = true;
  String ratioError = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('BearTrapTroopsPage');
    _loadTroopTotals();
    _loadSavedInputs();
    _setupFormatters();
    _loadCloudData(); // <-- load cloud on startup
  }

  // Focus nodes for toolbar across numeric fields
  final FocusNode _leadCapFocus = FocusNode();
  final FocusNode _joinerCapFocus = FocusNode();
  final FocusNode _infRatioFocus = FocusNode();
  final FocusNode _ridRatioFocus = FocusNode();
  final FocusNode _hunRatioFocus = FocusNode();
  final FocusNode _jInfRatioFocus = FocusNode();
  final FocusNode _jMarRatioFocus = FocusNode();
  final FocusNode _jLanRatioFocus = FocusNode();

  KeyboardActionsConfig _keyboardConfig() {
    final items = <KeyboardActionsItem>[
      KeyboardActionsItem(
        focusNode: _leadCapFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _infRatioFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _hunRatioFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _ridRatioFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _joinerCapFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _jInfRatioFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _jMarRatioFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _jLanRatioFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
    ];
    return KeyboardActionsConfig(actions: items, nextFocus: true);
  }

  void _setupFormatters() {
    for (final controller in [
      joinerCapacityController,
      leadCapacityController,
    ]) {
      controller.addListener(() {
        final raw = controller.text.replaceAll(',', '');
        final val = int.tryParse(raw);
        if (val == null) return;
        final newText = _formatter.format(val);
        if (controller.text != newText) {
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
        setState(() {});
      });
    }
  }

  Future<void> _loadTroopTotals() async {
    final prefs = await SharedPreferences.getInstance();
    int sum(String type) {
      final count = prefs.getInt('${type}_count') ?? 0;
      int total = 0;
      for (int i = 0; i < count; i++) {
        total += prefs.getInt('${type}_entry_${i}_count') ?? 0;
      }
      return total;
    }

    setState(() {
      infantryTotal = sum('Infantry');
      marksmenTotal = sum('Marksmen');
      lancersTotal = sum('Lancers');
      totalTroops = infantryTotal + marksmenTotal + lancersTotal;
    });
  }

  Future<void> _loadSavedInputs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rallyMarch = prefs.getInt('rallyMarch') ?? 1;
      sameJoinerRatio = prefs.getBool('sameJoinerRatio') ?? true;
      leadCapacityController.text = prefs.getString('leadCapacity') ?? '';
      joinerCapacityController.text = prefs.getString('joinerCapacity') ?? '';
      infantryRatioController.text = prefs.getString('infantryRatio') ?? '34';
      riderRatioController.text = prefs.getString('riderRatio') ?? '33';
      hunterRatioController.text = prefs.getString('hunterRatio') ?? '33';
      joinerInfantryRatio.text = prefs.getString('joinerInfantryRatio') ?? '34';
      joinerMarksmenRatio.text = prefs.getString('joinerMarksmenRatio') ?? '33';
      joinerLancerRatio.text = prefs.getString('joinerLancerRatio') ?? '33';
    });
  }

  Future<void> _saveInputs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rallyMarch', rallyMarch);
    await prefs.setBool('sameJoinerRatio', sameJoinerRatio);
    await prefs.setString('leadCapacity', leadCapacityController.text);
    await prefs.setString('joinerCapacity', joinerCapacityController.text);
    await prefs.setString('infantryRatio', infantryRatioController.text);
    await prefs.setString('riderRatio', riderRatioController.text);
    await prefs.setString('hunterRatio', hunterRatioController.text);
    await prefs.setString('joinerInfantryRatio', joinerInfantryRatio.text);
    await prefs.setString('joinerMarksmenRatio', joinerMarksmenRatio.text);
    await prefs.setString('joinerLancerRatio', joinerLancerRatio.text);

    await _saveCloudData(); // <-- persist to cloud as well
  }

  bool validateRatios() {
    final inf = int.tryParse(infantryRatioController.text) ?? 0;
    final rid = int.tryParse(riderRatioController.text) ?? 0;
    final hun = int.tryParse(hunterRatioController.text) ?? 0;
    final total = inf + rid + hun;

    if (total != 100) {
      setState(() => ratioError = 'Ratios must add to 100% (now $total%)');
      return false;
    }

    if (!sameJoinerRatio) {
      final jInf = int.tryParse(joinerInfantryRatio.text) ?? 0;
      final jMar = int.tryParse(joinerMarksmenRatio.text) ?? 0;
      final jLan = int.tryParse(joinerLancerRatio.text) ?? 0;
      final jTotal = jInf + jMar + jLan;

      if (jTotal != 100) {
        setState(
          () => ratioError = 'Joiner ratios must add to 100% (now $jTotal%)',
        );
        return false;
      }
    }

    setState(() => ratioError = '');
    return true;
  }

  Map<String, int> calculateTroopSplit(int cap) {
    final inf = int.tryParse(infantryRatioController.text) ?? 0;
    final rid = int.tryParse(riderRatioController.text) ?? 0;
    final hun = int.tryParse(hunterRatioController.text) ?? 0;

    return {
      'Infantry': (cap * inf / 100).round(),
      'Marksmen': (cap * hun / 100).round(),
      'Lancers': (cap * rid / 100).round(),
    };
  }

  Map<String, int> calculateJoinerSplit(int cap) {
    final inf =
        int.tryParse(
          (sameJoinerRatio ? infantryRatioController : joinerInfantryRatio)
              .text,
        ) ??
        0;
    final rid =
        int.tryParse(
          (sameJoinerRatio ? riderRatioController : joinerLancerRatio).text,
        ) ??
        0;
    final hun =
        int.tryParse(
          (sameJoinerRatio ? hunterRatioController : joinerMarksmenRatio).text,
        ) ??
        0;

    return {
      'Infantry': (cap * inf / 100).round(),
      'Marksmen': (cap * hun / 100).round(),
      'Lancers': (cap * rid / 100).round(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final leadCap =
        int.tryParse(leadCapacityController.text.replaceAll(',', '')) ?? 0;
    final joinerCap =
        int.tryParse(joinerCapacityController.text.replaceAll(',', '')) ?? 0;

    final valid = validateRatios();
    final leadSplit = valid ? calculateTroopSplit(leadCap) : {};
    final joinerSplit = valid ? calculateJoinerSplit(joinerCap) : {};

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
      body: KeyboardActions(
        config: _keyboardConfig(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Rally Setup',
                    icon: Icons.flag_rounded,
                    color: Colors.indigo,
                    child: Column(
                      children: [
                        _labeled('Rally March', _marchSelector()),
                        const SizedBox(height: 14),
                        _labeled(
                          'Lead Rally Capacity',
                          _numberField(leadCapacityController, _leadCapFocus),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ratioField(
                                'Infantry %',
                                infantryRatioController,
                                _infRatioFocus,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ratioField(
                                'Marksmen %',
                                hunterRatioController,
                                _hunRatioFocus,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ratioField(
                                'Lancers %',
                                riderRatioController,
                                _ridRatioFocus,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _labeled(
                          'Joiner Rally Capacity',
                          _numberField(
                            joinerCapacityController,
                            _joinerCapFocus,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: sameJoinerRatio,
                              onChanged: (val) {
                                setState(() => sameJoinerRatio = val ?? true);
                                _saveInputs();
                              },
                            ),
                            const Text('Joiner ratios same as lead'),
                          ],
                        ),
                        if (!sameJoinerRatio)
                          Row(
                            children: [
                              Expanded(
                                child: _ratioField(
                                  'Infantry %',
                                  joinerInfantryRatio,
                                  _jInfRatioFocus,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ratioField(
                                  'Marksmen %',
                                  joinerMarksmenRatio,
                                  _jMarRatioFocus,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ratioField(
                                  'Lancers %',
                                  joinerLancerRatio,
                                  _jLanRatioFocus,
                                ),
                              ),
                            ],
                          ),
                        if (ratioError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              ratioError,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (valid)
                    _resultsCard(
                      leadSplit.map((k, v) => MapEntry(k as String, v as int)),
                      joinerSplit.map(
                        (k, v) => MapEntry(k as String, v as int),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
      bottomSheet: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Save to Cloud'),
              onPressed: () async {
                final session = Supabase.instance.client.auth.currentSession;
                if (session == null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  setState(() {});
                  return;
                }
                await _saveCloudData();
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saved to cloud')));
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              onPressed: () async {
                setState(() {
                  rallyMarch = 1;
                  sameJoinerRatio = true;
                  leadCapacityController.clear();
                  joinerCapacityController.clear();
                  infantryRatioController.text = '34';
                  riderRatioController.text = '33';
                  hunterRatioController.text = '33';
                  joinerInfantryRatio.text = '34';
                  joinerMarksmenRatio.text = '33';
                  joinerLancerRatio.text = '33';
                });
                await _saveInputs();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            const Text('Bear Trap Troops Planner'),
          ],
        ),
      ),
    );
  }

  Widget _marchSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<int>(
        value: rallyMarch,
        isExpanded: true,
        underline: const SizedBox(),
        items: List.generate(
          6,
          (i) => DropdownMenuItem(value: i + 1, child: Text('March ${i + 1}')),
        ),
        onChanged: (val) {
          if (val == null) return;
          setState(() => rallyMarch = val);
          _saveInputs();
        },
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF283593), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Troop Inventory',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total: ${_formatter.format(totalTroops)}',
            style: TextStyle(color: Colors.white.withOpacity(.85)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _pill('🛡 Infantry', infantryTotal, Colors.lightBlueAccent),
              _pill('🏹 Marksmen', marksmenTotal, Colors.deepPurpleAccent),
              _pill('🗡 Lancers', lancersTotal, Colors.pinkAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, int value, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withOpacity(.45)),
      ),
      child: Text(
        '$label: ${_formatter.format(value)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          color: HSLColor.fromColor(c)
              .withLightness(
                (HSLColor.fromColor(c).lightness - .15).clamp(0.0, 1.0),
              )
              .toColor(),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(.85), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _resultsCard(
    Map<String, int> leadSplit,
    Map<String, int> joinerSplit,
  ) {
    return _sectionCard(
      title: 'Results',
      icon: Icons.bar_chart_rounded,
      color: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛡 Lead Rally Troops:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...leadSplit.entries.map(
            (e) => _resultRow(
              e.key,
              e.value,
              infantryTotal,
              marksmenTotal,
              lancersTotal,
            ),
          ),
          const Divider(height: 32),
          Text(
            '🤝 Joiner Troops per March (x$rallyMarch):',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...joinerSplit.entries.map((e) {
            final totalJoin = e.value * rallyMarch;
            final totalNeeded = (leadSplit[e.key] ?? 0) + totalJoin;
            final available = {
              'Infantry': infantryTotal,
              'Marksmen': marksmenTotal,
              'Lancers': lancersTotal,
            }[e.key]!;
            final isShort = totalNeeded > available;
            final shortfall = totalNeeded - available;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isShort ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatter.format(e.value)} each',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '= ${_formatter.format(totalJoin)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (isShort)
                    Text(
                      ' (+${_formatter.format(shortfall)})',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
              color: Colors.black87,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _numberField(TextEditingController c, FocusNode focus) {
    return TextField(
      controller: c,
      focusNode: focus,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 14),
      onEditingComplete: () => FocusScope.of(context).unfocus(),
      onChanged: (_) => _saveInputs(),
    );
  }

  Widget _ratioField(String label, TextEditingController c, FocusNode focus) {
    return TextField(
      controller: c,
      focusNode: focus,
      keyboardType: TextInputType.number,
      onChanged: (_) {
        setState(() {});
        _saveInputs();
      },
      onEditingComplete: () => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 13.5),
    );
  }

  Widget _resultRow(String type, int needed, int inf, int mar, int lan) {
    final available = {'Infantry': inf, 'Marksmen': mar, 'Lancers': lan}[type]!;
    final short = needed > available ? needed - available : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$type:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: short > 0 ? Colors.red : Colors.black87,
              ),
            ),
          ),
          Text(
            _formatter.format(needed),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: short > 0 ? Colors.red : Colors.black87,
            ),
          ),
          if (short > 0)
            Text(
              ' (+${_formatter.format(short)})',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // --- Cloud sync helpers ---
  Future<void> _saveCloudData() async {
    try {
      await CloudSyncService.save('bear_trap_troops', {
        'rallyMarch': rallyMarch,
        'sameJoinerRatio': sameJoinerRatio,
        'leadCapacity': leadCapacityController.text,
        'joinerCapacity': joinerCapacityController.text,
        'infantryRatio': infantryRatioController.text,
        'riderRatio': riderRatioController.text,
        'hunterRatio': hunterRatioController.text,
        'joinerInfantryRatio': joinerInfantryRatio.text,
        'joinerMarksmenRatio': joinerMarksmenRatio.text,
        'joinerLancerRatio': joinerLancerRatio.text,
      });
    } catch (e) {
      debugPrint('Failed to save bear_trap_troops to cloud: $e');
    }
  }

  Future<void> _loadCloudData() async {
    try {
      final data = await CloudSyncService.load('bear_trap_troops');
      if (data == null) return;
      setState(() {
        if (data.containsKey('rallyMarch')) {
          rallyMarch = (data['rallyMarch'] as int?) ?? rallyMarch;
        }
        if (data.containsKey('sameJoinerRatio')) {
          sameJoinerRatio =
              (data['sameJoinerRatio'] as bool?) ?? sameJoinerRatio;
        }
        if (data.containsKey('leadCapacity')) {
          leadCapacityController.text =
              data['leadCapacity']?.toString() ?? leadCapacityController.text;
        }
        if (data.containsKey('joinerCapacity')) {
          joinerCapacityController.text =
              data['joinerCapacity']?.toString() ??
              joinerCapacityController.text;
        }
        if (data.containsKey('infantryRatio')) {
          infantryRatioController.text =
              data['infantryRatio']?.toString() ?? infantryRatioController.text;
        }
        if (data.containsKey('riderRatio')) {
          riderRatioController.text =
              data['riderRatio']?.toString() ?? riderRatioController.text;
        }
        if (data.containsKey('hunterRatio')) {
          hunterRatioController.text =
              data['hunterRatio']?.toString() ?? hunterRatioController.text;
        }
        if (data.containsKey('joinerInfantryRatio')) {
          joinerInfantryRatio.text =
              data['joinerInfantryRatio']?.toString() ??
              joinerInfantryRatio.text;
        }
        if (data.containsKey('joinerMarksmenRatio')) {
          joinerMarksmenRatio.text =
              data['joinerMarksmenRatio']?.toString() ??
              joinerMarksmenRatio.text;
        }
        if (data.containsKey('joinerLancerRatio')) {
          joinerLancerRatio.text =
              data['joinerLancerRatio']?.toString() ?? joinerLancerRatio.text;
        }
      });
      // Optionally persist cloud-loaded values back to local prefs to keep them in sync
      await _saveInputs();
      // Ensure troop totals strictly reflect local data saved by troops_page.dart
      await _loadTroopTotals();
    } catch (e) {
      debugPrint('Failed to load bear_trap_troops from cloud: $e');
    }
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
