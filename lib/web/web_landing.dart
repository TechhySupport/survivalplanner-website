import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../chief_page.dart';
import '../hero_page.dart';
import '../building_page.dart';
import '../event_page.dart';
import '../troops_page.dart';
import '../services/loginscreen.dart';
import '../settings_page.dart';
import '../hivemap/hivemap_editor.dart';

class WebLandingPage extends StatelessWidget {
  const WebLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final isLoggedIn = session != null;
    final size = MediaQuery.of(context).size;
    final maxWidth = 1200.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: _TopNavBar(
                    isLoggedIn: isLoggedIn,
                    onLoginTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    onLogoutTap: () async {
                      await client.auth.signOut();
                      (context as Element).markNeedsBuild();
                    },
                    onSettingsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _HeroSection(width: size.width)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: _FeatureGrid(),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;
  final VoidCallback onSettingsTap;

  const _TopNavBar({
    required this.isLoggedIn,
    required this.onLoginTap,
    required this.onLogoutTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Survival Planner',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const Spacer(),
        _NavLink(
          label: 'Chief',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChiefPage()),
          ),
        ),
        _NavLink(
          label: 'Heroes',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HeroPage()),
          ),
        ),
        _NavLink(
          label: 'Building',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BuildingPage()),
          ),
        ),
        _NavLink(
          label: 'Event',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventPage()),
          ),
        ),
        _NavLink(
          label: 'Troops',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TroopsPage()),
          ),
        ),
        _NavLink(
          label: 'Hive Map',
          onTap: () async {
            final client = Supabase.instance.client;
            final loggedIn = client.auth.currentSession != null;
            if (!loggedIn) {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (ok != true) return;
            }
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    title: const Text('Hive Map Editor'),
                  ),
                  body: const HiveMapEditor(),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: onSettingsTap,
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('Settings'),
        ),
        const SizedBox(width: 8),
        if (isLoggedIn)
          OutlinedButton.icon(
            onPressed: onLogoutTap,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
          )
        else
          ElevatedButton.icon(
            onPressed: onLoginTap,
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Login'),
          ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final double width;
  const _HeroSection({required this.width});
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
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: width > 1000 ? 620 : double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Master Every Event—Win More With Smarter Tools',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Calculate faster. Plan better. From Chief Gear to Troops, our web tools help you dominate without the guesswork.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () {
                            // Push into any tool page; Chief is a good entry.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChiefPage(),
                              ),
                            );
                          },
                          child: const Text('Open Tools'),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cards = [
      _FeatureCard(
        icon: Icons.build,
        title: 'Chief Gear',
        desc: 'Optimize stats and upgrades with instant math.',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChiefPage()),
        ),
      ),
      _FeatureCard(
        icon: Icons.person,
        title: 'Heroes',
        desc: 'Plan builds and hero progress quickly.',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HeroPage()),
        ),
      ),
      _FeatureCard(
        icon: Icons.home_work,
        title: 'Building',
        desc: 'Resources, times, and best paths—instantly.',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuildingPage()),
        ),
      ),
      _FeatureCard(
        icon: Icons.event,
        title: 'Events',
        desc: 'Armament, Icefield, and more with less stress.',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventPage()),
        ),
      ),
      _FeatureCard(
        icon: Icons.groups,
        title: 'Troops',
        desc: 'Plan training and costs accurately.',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TroopsPage()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => cards[i],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.blue.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blueAccent),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(desc, style: const TextStyle(color: Colors.black54)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Open',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: Colors.blueAccent, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Web edition is fully free — no upsell banner.

class _Footer extends StatelessWidget {
  const _Footer();
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
              'Plan. Prepare. Prevail.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
