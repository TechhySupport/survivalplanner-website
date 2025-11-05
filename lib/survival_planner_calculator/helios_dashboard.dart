import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';

class HeliosDashboardPage extends StatefulWidget {
  const HeliosDashboardPage({super.key});

  @override
  State<HeliosDashboardPage> createState() => _HeliosDashboardPageState();
}

class _HeliosDashboardPageState extends State<HeliosDashboardPage> {
  final List<String> _sections = [
    'Infantry Helios',
    'Lancers Helios',
    'Marksman Helios'
  ];
  final Map<String, bool> _seen = {};
  int _totalCrystal = 0;
  int _totalSteel = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('HeliosDashboard');
    _loadSeenFlags();
    _loadTotals();
  }

  Future<void> _loadSeenFlags() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var section in _sections) {
        _seen[section] = prefs.getBool('seen_$section') ?? false;
      }
    });
  }

  Future<void> _markSeen(String section) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_$section', true);
    setState(() {
      _seen[section] = true;
    });
  }

  Future<void> _loadTotals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCrystal = prefs.getInt('helios_total_crystal') ?? 0;
      _totalSteel = prefs.getInt('helios_total_steel') ?? 0;
    });
  }

  Future<void> _resetTotals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('helios_total_crystal', 0);
    await prefs.setInt('helios_total_steel', 0);
    setState(() {
      _totalCrystal = 0;
      _totalSteel = 0;
    });
  }

  String _format(int number) => NumberFormat('#,###').format(number);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Helios Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 22),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _sections.map((label) => _heliosTile(label)).toList(),
            ),
            const SizedBox(height: 28),
            _totalsCard(),
          ],
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
          colors: [Color(0xFF5D4037), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Helios Overview',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Track shards & steel across troop types',
              style: TextStyle(color: Colors.white.withOpacity(.8))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill('🔥 Fire Crystals', _totalCrystal, Colors.deepOrangeAccent),
              _pill('🛠 Steel', _totalSteel, Colors.blueGrey),
            ],
          )
        ],
      ),
    );
  }

  Widget _heliosTile(String label) {
    final seen = _seen[label] == true;
    final emoji = label.startsWith('Infantry')
        ? '🛡'
        : label.startsWith('Lancers')
            ? '🗡'
            : '🏹';
    return GestureDetector(
      onTap: () {
        _markSeen(label);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open $label calculator')),
        );
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFCC80),
                  seen ? const Color(0xFFFF8A65) : const Color(0xFFEF6C00)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
              border:
                  Border.all(color: Colors.white.withOpacity(.2), width: 1.2),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFBF360C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: .3),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: seen ? .55 : 1,
                  child: Text(seen ? 'Viewed' : 'New',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                )
              ],
            ),
          ),
          if (!seen)
            const Positioned(
              top: 10,
              right: 12,
              child: CircleAvatar(radius: 6, backgroundColor: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Widget _totalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assessment_rounded,
                  color: Colors.deepOrange, size: 22),
              SizedBox(width: 8),
              Text('Totals',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill('🔥 Fire Crystals', _totalCrystal, Colors.deepOrange),
              _pill('🛠 Steel', _totalSteel, Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetTotals,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Total'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _pill(String label, int value, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withOpacity(.4)),
      ),
      child: Text('$label: ${_format(value)}',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: HSLColor.fromColor(c)
                  .withLightness(
                      (HSLColor.fromColor(c).lightness - .2).clamp(0.0, 1.0))
                  .toColor())),
    );
  }
}
