import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Premium removed — all features are free on web
import 'package:keyboard_actions/keyboard_actions.dart';
import '../services/analytics_service.dart';
import '../services/cloud_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class TroopTrainingCalculatorPage extends StatefulWidget {
  const TroopTrainingCalculatorPage({super.key});

  @override
  State<TroopTrainingCalculatorPage> createState() =>
      _TroopTrainingCalculatorPageState();
}

class _TroopTrainingCalculatorPageState
    extends State<TroopTrainingCalculatorPage> {
  final NumberFormat _formatter = NumberFormat('#,###');

  final TextEditingController trainingCapacityController =
      TextEditingController();
  final TextEditingController infantryController = TextEditingController();
  final TextEditingController marksmenController = TextEditingController();
  final TextEditingController lancerController = TextEditingController();
  final TextEditingController cityBuffController = TextEditingController();

  // Focus nodes for keyboard toolbar
  final FocusNode _capacityFocus = FocusNode();
  final FocusNode _infantryFocus = FocusNode();
  final FocusNode _marksmenFocus = FocusNode();
  final FocusNode _lancerFocus = FocusNode();
  final FocusNode _buffFocus = FocusNode();

  final List<int> levels = List.generate(11, (index) => index + 1);

  final List<int> trainingSecondsPerLevel = [
    12,
    17,
    24,
    32,
    44,
    60,
    83,
    113,
    131,
    152,
    165,
  ];

  bool isCapacitySet = false;
  int infantryLevel = 10;
  int marksmenLevel = 10;
  int lancerLevel = 10;

  String infantryTime = '';
  String marksmenTime = '';
  String lancerTime = '';
  // All features available — no premium gating

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('TroopTrainingCalculatorPage');
    _loadSavedValues();
    _setupFormatters();
    _loadCloud();
  }

  void _setupFormatters() {
    for (var controller in [
      infantryController,
      marksmenController,
      lancerController,
      trainingCapacityController,
    ]) {
      controller.addListener(() {
        final text = controller.text.replaceAll(',', '');
        if (text.isEmpty) return;
        final value = int.tryParse(text);
        if (value == null) return;
        final newText = _formatter.format(value);
        if (controller.text != newText) {
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      });
    }
  }

  KeyboardActionsConfig _keyboardConfig() {
    final items = <KeyboardActionsItem>[
      KeyboardActionsItem(
        focusNode: _capacityFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _infantryFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _marksmenFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _lancerFocus,
        toolbarButtons: [
          (node) => IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => node.unfocus(),
          ),
        ],
      ),
      KeyboardActionsItem(
        focusNode: _buffFocus,
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

  Future<void> _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    trainingCapacityController.text = prefs.getString('capacity') ?? '';
    infantryController.text = prefs.getString('infantry') ?? '';
    marksmenController.text = prefs.getString('marksmen') ?? '';
    lancerController.text = prefs.getString('lancer') ?? '';
    cityBuffController.text = prefs.getString('buff') ?? '';
    infantryLevel = prefs.getInt('infLevel') ?? 10;
    marksmenLevel = prefs.getInt('marksLevel') ?? 10;
    lancerLevel = prefs.getInt('lancerLevel') ?? 10;

    setState(() {
      isCapacitySet =
          int.tryParse(trainingCapacityController.text.replaceAll(',', '')) !=
          null;
    });
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('capacity', trainingCapacityController.text);
    await prefs.setString('infantry', infantryController.text);
    await prefs.setString('marksmen', marksmenController.text);
    await prefs.setString('lancer', lancerController.text);
    await prefs.setString('buff', cityBuffController.text);
    await prefs.setInt('infLevel', infantryLevel);
    await prefs.setInt('marksLevel', marksmenLevel);
    await prefs.setInt('lancerLevel', lancerLevel);
  }

  void _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    trainingCapacityController.clear();
    infantryController.clear();
    marksmenController.clear();
    lancerController.clear();
    cityBuffController.clear();
    infantryLevel = 10;
    marksmenLevel = 10;
    lancerLevel = 10;
    setState(() {
      infantryTime = '';
      marksmenTime = '';
      lancerTime = '';
      isCapacitySet = false;
    });
  }

  Future<void> _saveCloud() async {
    try {
      await CloudSyncService.save('troop_training_calculator', {
        'capacity': trainingCapacityController.text,
        'infantry': infantryController.text,
        'marksmen': marksmenController.text,
        'lancer': lancerController.text,
        'buff': cityBuffController.text,
        'infLevel': infantryLevel,
        'marksLevel': marksmenLevel,
        'lancerLevel': lancerLevel,
      });
    } catch (e) {
      debugPrint('Failed to save troop_training_calculator: $e');
    }
  }

  Future<void> _loadCloud() async {
    try {
      final data = await CloudSyncService.load('troop_training_calculator');
      if (data == null) return;
      setState(() {
        trainingCapacityController.text =
            data['capacity']?.toString() ?? trainingCapacityController.text;
        infantryController.text =
            data['infantry']?.toString() ?? infantryController.text;
        marksmenController.text =
            data['marksmen']?.toString() ?? marksmenController.text;
        lancerController.text =
            data['lancer']?.toString() ?? lancerController.text;
        cityBuffController.text =
            data['buff']?.toString() ?? cityBuffController.text;
        infantryLevel = (data['infLevel'] as int?) ?? infantryLevel;
        marksmenLevel = (data['marksLevel'] as int?) ?? marksmenLevel;
        lancerLevel = (data['lancerLevel'] as int?) ?? lancerLevel;
      });
    } catch (e) {
      debugPrint('Failed to load troop_training_calculator: $e');
    }
  }

  String _formatDuration(int count, int secondsPerUnit, double buff) {
    final total = (count * secondsPerUnit) / (1 + (buff / 100));
    final duration = Duration(seconds: total.round());
    final d = duration.inDays;
    final h = duration.inHours % 24;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;

    return [
      if (d > 0) '$d day${d > 1 ? 's' : ''}',
      if (h > 0) '$h hour${h > 1 ? 's' : ''}',
      if (m > 0) '$m min${m > 1 ? 's' : ''}',
      if (s > 0) '$s sec${s > 1 ? 's' : ''}',
    ].join(' ');
  }

  void _onCalculate() {
    final inf = int.tryParse(infantryController.text.replaceAll(',', '')) ?? 0;
    final mar = int.tryParse(marksmenController.text.replaceAll(',', '')) ?? 0;
    final lan = int.tryParse(lancerController.text.replaceAll(',', '')) ?? 0;
    final buff =
        double.tryParse(
          cityBuffController.text.replaceAll('%', '').replaceAll(',', ''),
        ) ??
        0.0;

    final infTime = _formatDuration(
      inf,
      trainingSecondsPerLevel[infantryLevel - 1],
      buff,
    );
    final marTime = _formatDuration(
      mar,
      trainingSecondsPerLevel[marksmenLevel - 1],
      buff,
    );
    final lanTime = _formatDuration(
      lan,
      trainingSecondsPerLevel[lancerLevel - 1],
      buff,
    );

    setState(() {
      infantryTime = infTime;
      marksmenTime = marTime;
      lancerTime = lanTime;
    });

    _saveAll();
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  _headerCard(),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Training Capacity',
                    icon: Icons.storage_rounded,
                    color: Colors.indigo,
                    child: _buildCapacity(),
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Troops Needed',
                    icon: Icons.groups_rounded,
                    color: Colors.deepPurple,
                    child: Column(
                      children: [
                        _buildTroopInput(
                          'Infantry Needed',
                          infantryController,
                          infantryLevel,
                          (val) => setState(() => infantryLevel = val ?? 10),
                          emoji: '🛡',
                        ),
                        if (infantryTime.isNotEmpty)
                          _timeLine(infantryTime, Colors.lightBlueAccent),
                        const SizedBox(height: 14),
                        _buildTroopInput(
                          'Marksmen Needed',
                          marksmenController,
                          marksmenLevel,
                          (val) => setState(() => marksmenLevel = val ?? 10),
                          emoji: '🏹',
                        ),
                        if (marksmenTime.isNotEmpty)
                          _timeLine(marksmenTime, Colors.deepPurpleAccent),
                        const SizedBox(height: 14),
                        _buildTroopInput(
                          'Lancer Needed',
                          lancerController,
                          lancerLevel,
                          (val) => setState(() => lancerLevel = val ?? 10),
                          emoji: '🗡',
                        ),
                        if (lancerTime.isNotEmpty)
                          _timeLine(lancerTime, Colors.pinkAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'City Buff %',
                    icon: Icons.speed_rounded,
                    color: Colors.teal,
                    child: _buildBuffInput(),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Reset',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded),
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
                await _saveCloud();
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
                _reset();
                await _saveCloud();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            const Text('Troop Training Calculator'),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Training Capacity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: trainingCapacityController,
                focusNode: _capacityFocus,
                decoration: const InputDecoration(
                  hintText: 'Enter your capacity',
                ),
                keyboardType: TextInputType.number,
                onEditingComplete: () => FocusScope.of(context).unfocus(),
                onChanged: (value) {
                  setState(() {
                    isCapacitySet =
                        int.tryParse(value.replaceAll(',', '')) != null;
                  });
                  if (isCapacitySet) _onCalculate();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Training Capacity Info'),
                    content: const Text(
                      'Find this under your total Power → Military tab → next to Training Capacity.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBuffInput() {
    final locked = false;
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: cityBuffController,
                focusNode: _buffFocus,
                readOnly: locked,
                decoration: InputDecoration(
                  labelText: 'City Buff (%)',
                  hintText: 'e.g. 197.5',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onEditingComplete: () => FocusScope.of(context).unfocus(),
                onChanged: (_) {
                  if (!locked) _onCalculate();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('City Buff Info'),
                    content: const Text(
                      'You can find this in-game under your total Power → Military tab → next to Training Speed.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        // no overlay — editable by default
      ],
    );
  }

  Widget _buildTroopInput(
    String label,
    TextEditingController controller,
    int selectedLevel,
    void Function(int?) onLevelChanged, {
    String? emoji,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (emoji != null)
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade200,
                      Colors.blueGrey.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: label.contains('Infantry')
                    ? _infantryFocus
                    : label.contains('Marksmen')
                    ? _marksmenFocus
                    : _lancerFocus,
                decoration: const InputDecoration(hintText: 'Amount'),
                keyboardType: TextInputType.number,
                enabled: isCapacitySet,
                onEditingComplete: () => FocusScope.of(context).unfocus(),
                onChanged: (_) {
                  if (isCapacitySet) _onCalculate();
                },
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: selectedLevel,
              items: levels
                  .map(
                    (lvl) =>
                        DropdownMenuItem(value: lvl, child: Text('Lv $lvl')),
                  )
                  .toList(),
              onChanged: isCapacitySet ? onLevelChanged : null,
              onTap: () {
                // If user changes via keyboard nav, ensure recalc after frame.
                Future.microtask(() => _onCalculate());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _timeLine(String time, Color c) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(.35)),
        ),
        child: Text(
          'Training Time: $time',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: HSLColor.fromColor(c)
                .withLightness(
                  (HSLColor.fromColor(c).lightness - .2).clamp(0.0, 1.0),
                )
                .toColor(),
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Training Planner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Optimize troop queue & speed with buffs',
            style: TextStyle(color: Colors.white70),
          ),
        ],
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 18,
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(.85), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.4),
                      blurRadius: 14,
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
