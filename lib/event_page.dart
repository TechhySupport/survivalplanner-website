// event_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Add if not present
import 'generated/app_localizations.dart';
import 'bottom_nav_bar.dart';
import 'SVS_calculator.dart'; // Make sure this file exists and exports SVSCalculatorPage
import 'events/king_of_icefield.dart';
import 'events/armament_competition.dart';
import 'events/officer_project.dart';
import 'utc_badge.dart';
import 'services/analytics_service.dart';
import 'settings_page.dart';
import 'services/loginscreen.dart';
import 'web/web_landing.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'troops_page.dart';

// --- GradientTileButton widget ---
class GradientTileButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final List<Color>? gradient;
  final double borderRadius;
  final double height;

  const GradientTileButton({
    super.key,
    required this.title,
    required this.onTap,
    this.leadingIcon,
    this.gradient,
    this.borderRadius = 22,
    this.height = 120,
  });

  @override
  State<GradientTileButton> createState() => _GradientTileButtonState();
}

class _GradientTileButtonState extends State<GradientTileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.gradient ??
        const [Color(0xFF5AA9FF), Color(0xFF6C7CFF), Color(0xFF8A6CFF)];

    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      scale: _pressed ? 0.98 : 1.0,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 12),
                color: Color(0x40000000),
              ),
            ],
          ),
          child: Stack(
            children: [
              // subtle glass highlight
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(widget.leadingIcon, color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Color(0x33000000),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // soft inner glow border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  int _svsTotal = 0;
  int _kingTotal = 0;
  int _armamentTotal = 0;
  int _officerTotal = 0; // 👈 Add this

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('EventPage');
    _loadSVSTotal();
    _loadKingTotal();
    _loadArmamentTotal();
    _loadOfficerTotal(); // 👈 Add this
  }

  Future<void> _loadSVSTotal() async {
    final total = await SVSCalculatorPage.getLastSVSTotal();
    setState(() => _svsTotal = total);
  }

  Future<void> _loadKingTotal() async {
    final prefs = await SharedPreferences.getInstance();
    int getTotalMinutes(String dKey, String hKey, String mKey) {
      final d = int.tryParse(prefs.getString(dKey) ?? '') ?? 0;
      final h = int.tryParse(prefs.getString(hKey) ?? '') ?? 0;
      final m = int.tryParse(prefs.getString(mKey) ?? '') ?? 0;
      return d * 24 * 60 + h * 60 + m;
    }

    final c = getTotalMinutes(
      'king_construction_days',
      'king_construction_hours',
      'king_construction_minutes',
    );
    final r = getTotalMinutes(
      'king_research_days',
      'king_research_hours',
      'king_research_minutes',
    );
    final t = getTotalMinutes(
      'king_troop_days',
      'king_troop_hours',
      'king_troop_minutes',
    );
    final g = getTotalMinutes(
      'king_general_days',
      'king_general_hours',
      'king_general_minutes',
    );

    final widgets =
        (int.tryParse(prefs.getString('king_hero_widgets') ?? '') ?? 0) * 8000;
    final rare =
        (int.tryParse(prefs.getString('king_rare_shards') ?? '') ?? 0) * 350;
    final epic =
        (int.tryParse(prefs.getString('king_epic_shards') ?? '') ?? 0) * 1220;
    final mystic =
        (int.tryParse(prefs.getString('king_mystic_shards') ?? '') ?? 0) * 3040;
    final mithril =
        (int.tryParse(prefs.getString('king_mithril') ?? '') ?? 0) * 144000;

    final speedupPoints = (c + r + t + g) * 30;
    final total = speedupPoints + widgets + rare + epic + mystic + mithril;
    setState(() => _kingTotal = total);
  }

  Future<void> _loadArmamentTotal() async {
    final prefs = await SharedPreferences.getInstance();
    int getTotalMinutes(String dKey, String hKey, String mKey) {
      final d = int.tryParse(prefs.getString(dKey) ?? '') ?? 0;
      final h = int.tryParse(prefs.getString(hKey) ?? '') ?? 0;
      final m = int.tryParse(prefs.getString(mKey) ?? '') ?? 0;
      return d * 24 * 60 + h * 60 + m;
    }

    final construction = getTotalMinutes(
      'construction_days',
      'construction_hours',
      'construction_minutes',
    );
    final research = getTotalMinutes(
      'research_days',
      'research_hours',
      'research_minutes',
    );
    final troop = getTotalMinutes('troop_days', 'troop_hours', 'troop_minutes');

    final fireCrystal =
        (int.tryParse(prefs.getString('fire_crystal') ?? '') ?? 0) * 100;
    final refinedFireCrystal =
        (int.tryParse(prefs.getString('refined_fire_crystal') ?? '') ?? 0) *
        1500;
    final mithril =
        (int.tryParse(prefs.getString('mithril') ?? '') ?? 0) * 28800;
    final essenceStone =
        (int.tryParse(prefs.getString('essence_stone') ?? '') ?? 0) * 800;
    final heroWidget =
        (int.tryParse(prefs.getString('hero_widget') ?? '') ?? 0) * 1600;

    final total =
        construction +
        research +
        troop +
        fireCrystal +
        refinedFireCrystal +
        mithril +
        essenceStone +
        heroWidget;
    setState(() => _armamentTotal = total);
  }

  Future<void> _loadOfficerTotal() async {
    final prefs = await SharedPreferences.getInstance();
    final essence =
        (int.tryParse(prefs.getString('essence_stone') ?? '') ?? 0) * 6000;
    final mithril =
        (int.tryParse(prefs.getString('mithril') ?? '') ?? 0) * 216000;

    const levelPoints = {
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

    int marksmenLevel =
        int.tryParse(prefs.getString('marksmen_level') ?? '') ?? 1;
    int marksmenTotal =
        int.tryParse(prefs.getString('marksmen_total') ?? '') ?? 0;
    int infantryLevel =
        int.tryParse(prefs.getString('infantry_level') ?? '') ?? 1;
    int infantryTotal =
        int.tryParse(prefs.getString('infantry_total') ?? '') ?? 0;
    int lancersLevel =
        int.tryParse(prefs.getString('lancers_level') ?? '') ?? 1;
    int lancersTotal =
        int.tryParse(prefs.getString('lancers_total') ?? '') ?? 0;

    final marksmenPoints = (levelPoints[marksmenLevel] ?? 1) * marksmenTotal;
    final infantryPoints = (levelPoints[infantryLevel] ?? 1) * infantryTotal;
    final lancersPoints = (levelPoints[lancersLevel] ?? 1) * lancersTotal;

    final total =
        essence + mithril + marksmenPoints + infantryPoints + lancersPoints;
    setState(() => _officerTotal = total);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final formatter = NumberFormat('#,###');
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
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _EventsHeroSection()),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      GradientTileButton(
                        title: localizations.eventPointCalculator,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SVSCalculatorPage(),
                            ),
                          ).then((_) => _loadSVSTotal());
                        },
                      ),
                      GradientTileButton(
                        title: 'King of Icefield',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KingOfIcefieldPage(),
                            ),
                          ).then((_) => _loadKingTotal());
                        },
                      ),
                      GradientTileButton(
                        title: 'Armament Competition',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ArmamentCompetitionPage(),
                            ),
                          ).then((_) => _loadArmamentTotal());
                        },
                      ),
                      GradientTileButton(
                        title: 'Officer Project',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OfficerProjectPage(),
                            ),
                          ).then((_) => _loadOfficerTotal());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_svsTotal > 0)
                        Text(
                          'SVS Points: ${formatter.format(_svsTotal)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (_svsTotal > 0 && _kingTotal > 0)
                        const SizedBox(height: 8),
                      if (_kingTotal > 0)
                        Text(
                          'King of Icefield Points: ${formatter.format(_kingTotal)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if ((_svsTotal > 0 || _kingTotal > 0) &&
                          _armamentTotal > 0)
                        const SizedBox(height: 8),
                      if (_armamentTotal > 0)
                        Text(
                          'Armament Competition Points: ${formatter.format(_armamentTotal)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if ((_svsTotal > 0 ||
                              _kingTotal > 0 ||
                              _armamentTotal > 0) &&
                          _officerTotal > 0)
                        const SizedBox(height: 8),
                      if (_officerTotal > 0)
                        Text(
                          'Officer Project Points: ${formatter.format(_officerTotal)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                      if (_svsTotal > 0 ||
                          _kingTotal > 0 ||
                          _armamentTotal > 0 ||
                          _officerTotal > 0)
                        ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            // SVS keys
                            for (var key in [
                              'construction_days',
                              'construction_hours',
                              'construction_minutes',
                              'research_days',
                              'research_hours',
                              'research_minutes',
                              'troop_days',
                              'troop_hours',
                              'troop_minutes',
                              'general_days',
                              'general_hours',
                              'general_minutes',
                              'hero_widgets',
                              'rare_shards',
                              'epic_shards',
                              'mystic_shards',
                              'mithril',
                            ]) {
                              await prefs.remove(key);
                            }
                            // King of Icefield keys
                            for (var key in [
                              'king_construction_days',
                              'king_construction_hours',
                              'king_construction_minutes',
                              'king_research_days',
                              'king_research_hours',
                              'king_research_minutes',
                              'king_troop_days',
                              'king_troop_hours',
                              'king_troop_minutes',
                              'king_general_days',
                              'king_general_hours',
                              'king_general_minutes',
                              'king_hero_widgets',
                              'king_rare_shards',
                              'king_epic_shards',
                              'king_mystic_shards',
                              'king_mithril',
                            ]) {
                              await prefs.remove(key);
                            }
                            // Armament Competition keys
                            for (var key in [
                              'construction_days',
                              'construction_hours',
                              'construction_minutes',
                              'research_days',
                              'research_hours',
                              'research_minutes',
                              'troop_days',
                              'troop_hours',
                              'troop_minutes',
                              'fire_crystal',
                              'refined_fire_crystal',
                              'mithril',
                              'essence_stone',
                              'hero_widget',
                            ]) {
                              await prefs.remove(key);
                            }
                            // Officer Project keys
                            for (var key in [
                              'essence_stone',
                              'mithril',
                              'marksmen_level',
                              'marksmen_total',
                              'infantry_level',
                              'infantry_total',
                              'lancers_level',
                              'lancers_total',
                            ]) {
                              await prefs.remove(key);
                            }
                            // Refresh all totals
                            await _loadSVSTotal();
                            await _loadKingTotal();
                            await _loadArmamentTotal();
                            await _loadOfficerTotal();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reset All'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: _EventsFooter()),
        ],
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
    );
  }
}

class _EventsHeroSection extends StatelessWidget {
  const _EventsHeroSection();
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Event Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'SVS, Icefield, Armament, and Officer planners in one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsFooter extends StatelessWidget {
  const _EventsFooter();
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
