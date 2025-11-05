import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloud_sync_service.dart';
// Premium removed — site is fully free
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

import 'dart:async';

/// A page that displays up to 3 hero calculators where you enter a start and desired level,
/// and it computes the shards needed per widget and in total.
class HeroWidgetPage extends StatefulWidget {
  const HeroWidgetPage({super.key});

  @override
  _HeroWidgetPageState createState() => _HeroWidgetPageState();
}

class _HeroWidgetPageState extends State<HeroWidgetPage> {
  static const List<int> _shardTable = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  final List<Map<String, dynamic>> _widgets = [
    {'label': 'Widget 1', 'start': 0, 'desired': 0},
  ];
  int get _maxSlots => 3;

  static const String _pageKey = 'hero_widget';

  @override
  void initState() {
    super.initState();
    // Try to load previously saved state from Supabase
    _loadCloud();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalShards();
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard(
                        context,
                        title: 'Hero Widgets',
                        icon: Icons.widgets,
                        color: Colors.deepPurple,
                        chipValue: total,
                        child: Column(
                          children: [
                            ..._widgets.asMap().entries.map(
                              (e) => _widgetCard(e.key, e.value),
                            ),
                            _addWidgetButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.summarize, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Total Shards: $total',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Save to Cloud'),
                          onPressed: () async {
                            final session =
                                Supabase.instance.client.auth.currentSession;
                            if (session == null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                              setState(() {});
                              return;
                            }
                            await _saveCloud();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved to cloud')),
                            );
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(
                              () => _widgets.replaceRange(0, _widgets.length, [
                                {'label': 'Widget 1', 'start': 0, 'desired': 0},
                              ]),
                            );
                            _saveCloud();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
    );
  }

  // --- Light theme helpers & cards ---
  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
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
              '$chipValue',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _widgetCard(int idx, Map<String, dynamic> data) {
    final shards = _calculateShards(data['start'], data['desired']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: data['label'],
                  decoration: _lightInputDecoration('Name'),
                  onChanged: (t) {
                    setState(() => data['label'] = t);
                    _saveCloud();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black54),
                onPressed: () {
                  setState(() => _widgets.removeAt(idx));
                  _saveCloud();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _levelSelectorLight('Start', data['start'], (v) {
                setState(() => data['start'] = v);
                _saveCloud();
              }),
              const SizedBox(width: 12),
              _levelSelectorLight('Desired', data['desired'], (v) {
                setState(() => data['desired'] = v);
                _saveCloud();
              }),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WIDGETS',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$shards',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addWidgetButton() {
    final locked = _widgets.length >= _maxSlots;
    return InkWell(
      onTap: () {
        if (_widgets.length >= _maxSlots) return;
        final idx = _widgets.length + 1;
        setState(() {
          _widgets.add({'label': 'Widget $idx', 'start': 0, 'desired': 0});
        });
        _saveCloud();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: locked ? Colors.grey.shade200 : Colors.deepPurple,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              locked ? Icons.lock : Icons.add,
              color: locked ? Colors.black54 : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              locked ? 'Max slots reached' : 'Add Widget',
              style: TextStyle(
                color: locked ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelSelectorLight(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            value: value,
            isDense: true,
            items: List.generate(
              11,
              (i) => DropdownMenuItem(value: i, child: Text('$i')),
            ),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            decoration: _lightInputDecoration(''),
          ),
        ],
      ),
    );
  }

  InputDecoration _lightInputDecoration(String label) => InputDecoration(
    labelText: label.isEmpty ? null : label,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.deepPurple),
    ),
  );

  int _calculateShards(int start, int desired) {
    if (desired <= start) return 0;
    int sum = 0;
    for (int lvl = start; lvl < desired; lvl++) {
      sum += _shardTable[lvl];
    }
    return sum;
  }

  int _totalShards() => _widgets.fold(
    0,
    (total, data) => total + _calculateShards(data['start'], data['desired']),
  );

  // Removed legacy upgrade dialog in favor of centralized PaywallHelper.

  Future<void> _saveCloud() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final data = {
      'widgets': _widgets
          .map(
            (e) => {
              'label': e['label'] ?? 'Widget',
              'start': e['start'] ?? 0,
              'desired': e['desired'] ?? 0,
            },
          )
          .toList(),
    };
    try {
      await CloudSyncService.save(_pageKey, data);
    } catch (_) {
      // Swallow errors silently; UI shows explicit success on manual save.
    }
  }

  Future<void> _loadCloud() async {
    final data = await CloudSyncService.load(_pageKey);
    if (data == null) return;
    final widgets = data['widgets'];
    if (widgets is List) {
      final parsed = widgets.map<Map<String, dynamic>>((e) {
        if (e is Map) {
          return {
            'label': (e['label'] ?? 'Widget').toString(),
            'start': (e['start'] ?? 0) is int
                ? (e['start'] ?? 0) as int
                : int.tryParse('${e['start']}') ?? 0,
            'desired': (e['desired'] ?? 0) is int
                ? (e['desired'] ?? 0) as int
                : int.tryParse('${e['desired']}') ?? 0,
          };
        }
        return {'label': 'Widget', 'start': 0, 'desired': 0};
      }).toList();

      if (parsed.isNotEmpty) {
        setState(() {
          _widgets
            ..clear()
            ..addAll(parsed);
        });
      }
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
