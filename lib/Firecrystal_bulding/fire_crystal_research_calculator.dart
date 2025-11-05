import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloud_sync_service.dart';
import 'dart:async';
import '../services/analytics_service.dart';
import '../survival_planner_calculator/utc_badge.dart';
import '../survival_planner_calculator/settings_page.dart';
import '../services/loginscreen.dart';
import '../survival_planner_calculator/bottom_nav_bar.dart';
import '../survival_planner_calculator/web_landing.dart';
import '../survival_planner_calculator/chief_page.dart';
import '../survival_planner_calculator/hero_page.dart';
import '../survival_planner_calculator/building_page.dart';
import '../survival_planner_calculator/event_page.dart';
import '../survival_planner_calculator/troops_page.dart';

class FireCrystalResearchCalculatorPage extends StatefulWidget {
  const FireCrystalResearchCalculatorPage({super.key});

  @override
  State<FireCrystalResearchCalculatorPage> createState() =>
      _FireCrystalResearchCalculatorPageState();
}

class _FireCrystalResearchCalculatorPageState
    extends State<FireCrystalResearchCalculatorPage> {
  int _currentLevel = 1;
  int _targetLevel = 2; // start one ahead
  Timer? _cloudTimer;

  void _enforceFreeLimits() {
    // No premium limits on the web
  }

  // --- Cloud Sync ---
  Future<void> _saveCloud() async {
    await CloudSyncService.save('fire_crystal_research_calculator', {
      'currentLevel': _currentLevel,
      'targetLevel': _targetLevel,
    });
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load(
      'fire_crystal_research_calculator',
    );
    if (data == null || !mounted) return;
    setState(() {
      if (data['currentLevel'] != null) {
        _currentLevel = data['currentLevel'] as int;
      }
      if (data['targetLevel'] != null) {
        _targetLevel = data['targetLevel'] as int;
      }
    });
    setState(() {
      _enforceFreeLimits();
    });
  }

  void _setLevel(bool isCurrent, int level) {
    setState(() {
      if (isCurrent) {
        _currentLevel = level;
      } else {
        _targetLevel = level;
      }
      _enforceFreeLimits();
    });
    _saveCloud();
  }

  Widget _buildLevelSelector(String label, bool isCurrent) {
    int selected = isCurrent ? _currentLevel : _targetLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: List.generate(5, (index) {
            final level = index + 1;
            return GestureDetector(
              onTap: () async {
                _setLevel(isCurrent, level);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: selected == level
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'lib/assets/firecrystals/fc${index + 1}.png',
                  height: 50,
                  width: 50,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('FireCrystalResearchCalculatorPage');
    _loadCloud();
    _cloudTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _saveCloud(),
    );
    Future.delayed(const Duration(seconds: 2), _saveCloud);
    _enforceFreeLimits();
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    super.dispose();
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelSelector('Current Level:', true),
                  const SizedBox(height: 24),
                  _buildLevelSelector('Target Level:', false),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveCloud();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selection saved.')),
                      );
                    },
                    child: const Text('Calculate'),
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
                  _currentLevel = 1;
                  _targetLevel = 2;
                });
                await _saveCloud();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            const Text('Fire Crystal Research'),
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
