import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'utc_badge.dart';

import '../normal_building/furnace_building_calculator.dart' as normal_furnace;
import '../normal_building/camps_calculator.dart';
import '../normal_building/research_centre_calculator.dart';
import '../normal_building/embassy_calculator.dart';
import '../normal_building/command_centre_calculator.dart';
import '../normal_building/barricade_calculator.dart';
import '../normal_building/storehouse_calculator.dart';
import '../services/purchase_service.dart';
import '../services/paywall_helper.dart';

import '../Firecrystal_bulding/furnace_building_calculator.dart' as fire_furnace;
import '../Firecrystal_bulding/fire_crystal_camps_calculator.dart';
import '../Firecrystal_bulding/fire_crystal_embassy_calculator.dart';
import '../Firecrystal_bulding/fire_crystal_command_calculator.dart';
import '../Firecrystal_bulding/fire_crystal_war_academy_calculator.dart';
import '../Firecrystal_bulding/fire_crystal_research_calculator.dart';
import 'bottom_nav_bar.dart';
import '../services/analytics_service.dart';
import 'settings_page.dart';
import '../services/loginscreen.dart';
import 'web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'event_page.dart';
import 'troops_page.dart';

/// Small gradient tile button used in the grids.
class GradientTileButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Gradient? gradient;

  const GradientTileButton({
    super.key,
    required this.title,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final Gradient usedGradient =
        gradient ??
        const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    return Material(
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: usedGradient),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Building hub page
class BuildingPage extends StatefulWidget {
  const BuildingPage({super.key});

  @override
  State<BuildingPage> createState() => _BuildingPageState();
}

class _BuildingPageState extends State<BuildingPage> {
  final NumberFormat _formatter = NumberFormat('#,###');
  final TextEditingController _fireCrystalBonusController =
      TextEditingController();
  final FireCrystalTotals _totals = FireCrystalTotals();

  SharedPreferences? _prefs;
  static const String _bonusKey = 'fire_crystal_construction_bonus';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('BuildingPage');
    _initPrefsAndLoad();
  }

  // Upgrade dialog removed; purchase triggered directly where needed.

  @override
  void dispose() {
    _fireCrystalBonusController.dispose();
    super.dispose();
  }

  Future<void> _initPrefsAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getDouble(_bonusKey) ?? 0.0;
    final text = (saved == saved.roundToDouble())
        ? saved.toInt().toString()
        : saved.toString();
    _fireCrystalBonusController.text = text;
  }

  Future<void> _saveFireCrystalBonus() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _fireCrystalBonusController.text.trim();
    final value = double.tryParse(raw) ?? 0.0;
    await _prefs!.setDouble(_bonusKey, value);
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
            ),
          ),
          if (Supabase.instance.client.auth.currentSession != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                (context as Element).markNeedsBuild();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const TabBar(
              labelColor: Colors.black,
              tabs: [
                Tab(text: 'Normal Buildings'),
                Tab(text: 'Fire Crystal'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // ---------------- Normal Buildings ----------------
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        GradientTileButton(
                          title: 'Furnace',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    normal_furnace.FurnaceBuildingCalculatorPage(),
                              ),
                            );
                          },
                        ),
                        GradientTileButton(
                          title: 'Camps',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CampsCalculatorPage(),
                              ),
                            );
                          },
                        ),
                        GradientTileButton(
                          title: 'Research Centre',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResearchCentreCalculatorPage(),
                              ),
                            );
                          },
                        ),
                        GradientTileButton(
                          title: 'Embassy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmbassyCalculatorPage(),
                              ),
                            );
                          },
                        ),
                        GradientTileButton(
                          title: 'Command Centre',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommandCentreCalculatorPage(),
                              ),
                            );
                          },
                        ),
                        GradientTileButton(
                          title: 'Barricade',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BarricadeCalculatorPage(),
                              ),
                            );
                          },
                        ),
                        GradientTileButton(
                          title: 'Storehouse',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StorehouseCalculatorPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ---------------- Fire Crystal ----------------
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Construction Speed Bonus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Simplified: removed overlay that covered the Upgrade button.
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _fireCrystalBonusController,
                                enabled: PurchaseService.isPremium,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 50',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '%',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            if (PurchaseService.isPremium)
                              ElevatedButton(
                                onPressed: _saveFireCrystalBonus,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Save'),
                              ),
                          ],
                        ),
                        if (!PurchaseService.isPremium)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1C2A78), Color(0xFF4A1D88)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white24,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lock,
                                  color: Colors.amberAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Fire Crystal construction speed bonus is locked in the free version. Unlock Premium to edit this bonus and remove ads.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => PaywallHelper.show(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.amberAccent,
                                  ),
                                  child: const Text('UPGRADE'),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // --- Fire Crystal Buildings Grid (fixed parentheses) ---
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              GradientTileButton(
                                title: 'Furnace',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          fire_furnace.FurnaceBuildingCalculatorPage(
                                            onCalculate: (crystals, days) {
                                              setState(() {
                                                _totals.update(
                                                  'fire_furnace',
                                                  crystals,
                                                  Duration(days: days),
                                                );
                                              });
                                            },
                                          ),
                                    ),
                                  );
                                },
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFFFF5252),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              GradientTileButton(
                                title: 'Camps',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FireCrystalCampsCalculatorPage(
                                            onCalculate: (crystals, days) {
                                              setState(() {
                                                _totals.update(
                                                  'fire_camps',
                                                  crystals,
                                                  Duration(days: days),
                                                );
                                              });
                                            },
                                          ),
                                    ),
                                  );
                                },
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFFFF5252),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              GradientTileButton(
                                title: 'Embassy',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FireCrystalEmbassyCalculatorPage(
                                            onCalculate: (crystals, days) {
                                              setState(() {
                                                _totals.update(
                                                  'fire_embassy',
                                                  crystals,
                                                  Duration(days: days),
                                                );
                                              });
                                            },
                                          ),
                                    ),
                                  );
                                },
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFFFF5252),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              GradientTileButton(
                                title: 'Command Centre',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FireCrystalCommandCentreCalculatorPage(
                                            onCalculate: (crystals, days) {
                                              setState(() {
                                                _totals.update(
                                                  'fire_command',
                                                  crystals,
                                                  Duration(days: days),
                                                );
                                              });
                                            },
                                          ),
                                    ),
                                  );
                                },
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFFFF5252),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              GradientTileButton(
                                title: 'War Academy',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FireCrystalWarAcademyCalculatorPage(
                                            onCalculate: (crystals, days) {
                                              setState(() {
                                                _totals.update(
                                                  'fire_war_academy',
                                                  crystals,
                                                  Duration(days: days),
                                                );
                                              });
                                            },
                                          ),
                                    ),
                                  );
                                },
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFFFF5252),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              GradientTileButton(
                                title: 'Research Centre',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FireCrystalResearchCalculatorPage(),
                                    ),
                                  );
                                },
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFFFF5252),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total Fire Crystals: ${_formatter.format(_totals.totalCrystals)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Time: ${_totals.timeFormatted}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Total Time with Speed Bonus: ${_totals.timeFormattedWithBonus(_fireCrystalBonusController.text)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _totals.reset();
                            });
                          },
                          child: const Text(
                            'Reset Total',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
    );
  }
}

/// Helper class to track Fire Crystal totals and time.
class FireCrystalTotals {
  final Map<String, _BuildingData> _buildingData = {};

  int get totalCrystals =>
      _buildingData.values.fold(0, (sum, b) => sum + b.crystals);

  Duration get totalTime =>
      _buildingData.values.fold(Duration.zero, (sum, b) => sum + b.duration);

  void update(String buildingKey, int crystals, Duration days) {
    _buildingData[buildingKey] = _BuildingData(
      crystals: crystals,
      refined: 0,
      duration: days,
    );
  }

  void reset() {
    _buildingData.clear();
  }

  String get timeFormatted {
    final total = totalTime;
    final days = total.inDays;
    final hours = total.inHours % 24;
    final minutes = total.inMinutes % 60;
    List<String> parts = [];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    return parts.isEmpty ? '0m' : parts.join(' ');
  }

  String timeFormattedWithBonus(String bonusText) {
    double bonus = double.tryParse(bonusText.trim()) ?? 0.0;
    double speedMultiplier = 1 + (bonus / 100);
    if (speedMultiplier <= 0) speedMultiplier = 1;
    int adjustedMinutes = (totalTime.inMinutes / speedMultiplier).round();
    Duration adjusted = Duration(minutes: adjustedMinutes);
    final days = adjusted.inDays;
    final hours = adjusted.inHours % 24;
    final minutes = adjusted.inMinutes % 60;
    List<String> parts = [];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    return parts.isEmpty ? '0m' : parts.join(' ');
  }
}

class _BuildingData {
  final int crystals;
  final int refined;
  final Duration duration;

  _BuildingData({
    required this.crystals,
    required this.refined,
    required this.duration,
  });
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
