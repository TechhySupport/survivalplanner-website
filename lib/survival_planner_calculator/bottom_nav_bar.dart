// bottom_nav_bar.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'main.dart';
import 'troops_page.dart';
import 'more.dart';
import 'web_landing.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  // keys for each tab
  final _tabKeys = ['home', 'chief', 'heroes', 'building', 'troops', 'more'];
  Map<String, bool> _seen = {}; // initialize here

  @override
  void initState() {
    super.initState();
    _loadSeenFlags();
  }

  Future<void> _loadSeenFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, bool>{};
    for (var key in _tabKeys) {
      loaded[key] = prefs.getBool('seen_$key') ?? false;
    }
    setState(() => _seen = loaded);
  }

  Future<void> _markSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_$key', true);
    setState(() => _seen[key] = true);
  }

  @override
  Widget build(BuildContext context) {
    Widget buildTab({
      required String keyName,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      final showBadge = _seen[keyName] == false;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            _markSeen(keyName);
            onTap();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              if (showBadge)
                Positioned(
                  top: 4, // moved up
                  right: 8, // moved more to the right
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/navbackground.png',
              fit: BoxFit.cover,
            ),
          ),
          Row(
            children: [
              buildTab(
                keyName: 'home',
                icon: Icons.home,
                label: 'Home',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          kIsWeb ? const WebLandingPage() : const HomeScreen(),
                    ),
                  );
                },
              ),
              buildTab(
                keyName: 'chief',
                icon: Icons.shield,
                label: 'Chief',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChiefPage()),
                  );
                },
              ),
              buildTab(
                keyName: 'heroes',
                icon: Icons.person,
                label: 'Heroes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HeroPage()),
                  );
                },
              ),
              buildTab(
                keyName: 'building',
                icon: Icons.location_city,
                label: 'Building',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BuildingPage()),
                  );
                },
              ),
              buildTab(
                keyName: 'troops',
                icon: Icons.military_tech,
                label: 'Troops',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TroopsPage()),
                  );
                },
              ),
              buildTab(
                keyName: 'more',
                icon: Icons.more_horiz,
                label: 'More',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MorePage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
