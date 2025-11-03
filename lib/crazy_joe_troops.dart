import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'services/analytics_service.dart';
import 'services/cloud_sync_service.dart';
import 'utc_badge.dart';
import 'settings_page.dart';
import 'services/loginscreen.dart';
import 'bottom_nav_bar.dart';
import 'web/web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'event_page.dart';
import 'troops_page.dart';

class CrazyJoeTroopsPage extends StatefulWidget {
  const CrazyJoeTroopsPage({super.key});

  @override
  State<CrazyJoeTroopsPage> createState() => _CrazyJoeTroopsPageState();
}

class _CrazyJoeTroopsPageState extends State<CrazyJoeTroopsPage> {
  final NumberFormat _formatter = NumberFormat('#,###');

  int infantryTotal = 0;
  int marksmenTotal = 0;
  int lancersTotal = 0;
  int totalTroops = 0;

  final TextEditingController infantryRatioController = TextEditingController();
  final TextEditingController marksmenRatioController = TextEditingController();
  final TextEditingController lancersRatioController = TextEditingController();

  final TextEditingController capacityController = TextEditingController();

  // Focus nodes for toolbar
  final FocusNode _capacityFocus = FocusNode();
  final FocusNode _infRatioFocus = FocusNode();
  final FocusNode _marRatioFocus = FocusNode();
  final FocusNode _lanRatioFocus = FocusNode();

  int marchCount = 6;
  String ratioError = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('CrazyJoeTroopsPage');
    _loadTroopTotals();
    _loadSavedInputs();
    _loadCloud();
  }

  Future<void> _loadTroopTotals() async {
    final prefs = await SharedPreferences.getInstance();

    int sumType(String type) {
      final count = prefs.getInt('${type}_count') ?? 0;
      int total = 0;
      for (int i = 0; i < count; i++) {
        total += prefs.getInt('${type}_entry_${i}_count') ?? 0;
      }
      return total;
    }

    setState(() {
      infantryTotal = sumType('Infantry');
      marksmenTotal = sumType('Marksmen');
      lancersTotal = sumType('Lancers');
      totalTroops = infantryTotal + marksmenTotal + lancersTotal;
    });
  }

  Future<void> _loadSavedInputs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      marchCount = prefs.getInt('cj_marchCount') ?? 6;
      capacityController.text = _formatter.format(
        prefs.getInt('cj_capacity') ?? 100000,
      );
      infantryRatioController.text =
          prefs.getString('cj_infantryRatio') ?? '34';
      marksmenRatioController.text =
          prefs.getString('cj_marksmenRatio') ?? '33';
      lancersRatioController.text = prefs.getString('cj_lancersRatio') ?? '33';
    });
  }

  Future<void> _saveInputs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCap =
        int.tryParse(capacityController.text.replaceAll(',', '')) ?? 0;

    await prefs.setInt('cj_marchCount', marchCount);
    await prefs.setInt('cj_capacity', rawCap);
    await prefs.setString('cj_infantryRatio', infantryRatioController.text);
    await prefs.setString('cj_marksmenRatio', marksmenRatioController.text);
    await prefs.setString('cj_lancersRatio', lancersRatioController.text);
  }

  bool validateRatios() {
    final inf = int.tryParse(infantryRatioController.text) ?? 0;
    final mar = int.tryParse(marksmenRatioController.text) ?? 0;
    final lan = int.tryParse(lancersRatioController.text) ?? 0;

    final sum = inf + mar + lan;
    if (sum != 100) {
      setState(() {
        ratioError = 'Ratios must add up to 100% (now: $sum%)';
      });
      return false;
    }

    setState(() {
      ratioError = '';
    });
    return true;
  }

  List<Map<String, int>> generateMarches(int capacity, int count) {
    final infRatio = int.tryParse(infantryRatioController.text) ?? 0;
    final marRatio = int.tryParse(marksmenRatioController.text) ?? 0;
    final lanRatio = int.tryParse(lancersRatioController.text) ?? 0;

    return List.generate(count, (_) {
      return {
        'Infantry': (capacity * infRatio / 100).round(),
        'Marksmen': (capacity * marRatio / 100).round(),
        'Lancers': (capacity * lanRatio / 100).round(),
      };
    });
  }

  Future<void> _saveCloud() async {
    try {
      await CloudSyncService.save('crazy_joe_troops_v2', {
        'marchCount': marchCount,
        'capacity': capacityController.text,
        'infantryRatio': infantryRatioController.text,
        'marksmenRatio': marksmenRatioController.text,
        'lancersRatio': lancersRatioController.text,
      });
    } catch (e) {
      debugPrint('Failed to save crazy_joe_troops_v2: $e');
    }
  }

  Future<void> _loadCloud() async {
    try {
      final data = await CloudSyncService.load('crazy_joe_troops_v2');
      if (data == null) return;
      setState(() {
        marchCount = (data['marchCount'] as int?) ?? marchCount;
        if (data['capacity'] != null) {
          capacityController.text = data['capacity'].toString();
        }
        if (data['infantryRatio'] != null) {
          infantryRatioController.text = data['infantryRatio'].toString();
        }
        if (data['marksmenRatio'] != null) {
          marksmenRatioController.text = data['marksmenRatio'].toString();
        }
        if (data['lancersRatio'] != null) {
          lancersRatioController.text = data['lancersRatio'].toString();
        }
      });
    } catch (e) {
      debugPrint('Failed to load crazy_joe_troops_v2: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawCap =
        int.tryParse(capacityController.text.replaceAll(',', '')) ?? 0;
    final valid = validateRatios();
    final marches = valid ? generateMarches(rawCap, marchCount) : [];
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
        config: KeyboardActionsConfig(
          actions: [
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
              focusNode: _infRatioFocus,
              toolbarButtons: [
                (node) => IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => node.unfocus(),
                ),
              ],
            ),
            KeyboardActionsItem(
              focusNode: _marRatioFocus,
              toolbarButtons: [
                (node) => IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => node.unfocus(),
                ),
              ],
            ),
            KeyboardActionsItem(
              focusNode: _lanRatioFocus,
              toolbarButtons: [
                (node) => IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => node.unfocus(),
                ),
              ],
            ),
          ],
          nextFocus: true,
        ),
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
                    title: 'March Setup',
                    color: Colors.deepPurple,
                    icon: Icons.settings_input_component_rounded,
                    child: Column(
                      children: [
                        _labeled('March Capacity', _capacityField()),
                        const SizedBox(height: 18),
                        _labeled('March Count (max 6)', _marchSelector()),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ratio (must total 100%)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(.75),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ratioField(
                                'Infantry %',
                                infantryRatioController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ratioField(
                                'Marksmen %',
                                marksmenRatioController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ratioField(
                                'Lancers %',
                                lancersRatioController,
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
                  if (valid && marches.isNotEmpty)
                    _resultsCard(
                      marches
                          .map<Map<String, int>>(
                            (e) => {
                              'Infantry': e['Infantry'] ?? 0,
                              'Marksmen': e['Marksmen'] ?? 0,
                              'Lancers': e['Lancers'] ?? 0,
                            },
                          )
                          .toList(),
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
                setState(() {
                  marchCount = 6;
                  capacityController.clear();
                  infantryRatioController.text = '34';
                  marksmenRatioController.text = '33';
                  lancersRatioController.text = '33';
                  ratioError = '';
                });
                await _saveInputs();
                await _saveCloud();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            const Text('Crazy Joe Troops Planner'),
          ],
        ),
      ),
    );
  }

  Widget _capacityField() {
    return TextField(
      controller: capacityController,
      focusNode: _capacityFocus,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CommaTextInputFormatter(),
      ],
      onEditingComplete: () => FocusScope.of(context).unfocus(),
      onChanged: (_) {
        setState(() {});
        _saveInputs();
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 14),
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
        value: marchCount,
        isExpanded: true,
        underline: const SizedBox(),
        items: List.generate(
          6,
          (i) =>
              DropdownMenuItem(value: i + 1, child: Text('${i + 1} marches')),
        ),
        onChanged: (val) async {
          if (val == null) return;
          setState(() => marchCount = val);
          await _saveInputs();
          await _saveCloud();
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
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
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

  Widget _resultsCard(List<Map<String, int>> marches) {
    int usedInf = 0, usedMar = 0, usedLan = 0;
    int totalMissingInf = 0, totalMissingMar = 0, totalMissingLan = 0;

    return _sectionCard(
      title: 'Garrison Marches',
      icon: Icons.bar_chart_rounded,
      color: Colors.teal,
      child: Column(
        children: [
          ...List.generate(marches.length, (i) {
            final march = marches[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'March ${i + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                      2: IntrinsicColumnWidth(),
                    },
                    children: [
                      ...['Infantry', 'Marksmen', 'Lancers'].map((type) {
                        final amount = march[type]!;
                        switch (type) {
                          case 'Infantry':
                            usedInf += amount;
                            break;
                          case 'Marksmen':
                            usedMar += amount;
                            break;
                          case 'Lancers':
                            usedLan += amount;
                            break;
                        }
                        final available = {
                          'Infantry': infantryTotal,
                          'Marksmen': marksmenTotal,
                          'Lancers': lancersTotal,
                        }[type]!;
                        final used = {
                          'Infantry': usedInf,
                          'Marksmen': usedMar,
                          'Lancers': usedLan,
                        }[type]!;
                        final isShort = used > available;
                        final shortfall = isShort ? used - available : 0;
                        if (isShort) {
                          switch (type) {
                            case 'Infantry':
                              totalMissingInf += shortfall;
                              break;
                            case 'Marksmen':
                              totalMissingMar += shortfall;
                              break;
                            case 'Lancers':
                              totalMissingLan += shortfall;
                              break;
                          }
                        }
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isShort ? Colors.red : Colors.black87,
                                ),
                              ),
                            ),
                            Text(_formatter.format(amount)),
                            Text(
                              isShort ? '❌' : '✅',
                              style: TextStyle(
                                color: isShort ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (totalMissingInf > 0 || totalMissingMar > 0 || totalMissingLan > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛑 Missing Troops',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  if (totalMissingInf > 0)
                    Text('Infantry: ${_formatter.format(totalMissingInf)}'),
                  if (totalMissingMar > 0)
                    Text('Marksmen: ${_formatter.format(totalMissingMar)}'),
                  if (totalMissingLan > 0)
                    Text('Lancers: ${_formatter.format(totalMissingLan)}'),
                ],
              ),
            ),
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

  Widget _ratioField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      focusNode: label.contains('Infantry')
          ? _infRatioFocus
          : label.contains('Marksmen')
          ? _marRatioFocus
          : _lanRatioFocus,
      keyboardType: TextInputType.number,
      onEditingComplete: () => FocusScope.of(context).unfocus(),
      onChanged: (_) {
        setState(() {});
        _saveInputs();
      },
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
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 13.5),
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

class CommaTextInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(raw);
    if (number == null) return oldValue;
    final newText = _formatter.format(number);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
