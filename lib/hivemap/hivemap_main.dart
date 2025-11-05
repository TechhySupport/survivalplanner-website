import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Debug entry marker to distinguish dedicated HiveMap app boots
  // This prints in the web console when the HiveMap build is launched.
  // ignore: avoid_print
  debugPrint('DEBUG: HIVE MAP EDITOR entry (hivemap_main.dart) starting');

  // Initialize Supabase with the same configuration as the main app
  await Supabase.initialize(
    url: 'https://wdjophtkpqtpdkbcwxsq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indkam9waHRrcHF0cGRrYmN3eHNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MzAxMTYsImV4cCI6MjA3MDIwNjExNn0.FG3LnqOIJ3fwp5qMAEmYRbF8mwF1ujBiGjEj7E8HnwI',
  );

  // Set system UI mode for web
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const HiveMapApp());
}

class HiveMapApp extends StatelessWidget {
  const HiveMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiveMap - Interactive Hive Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HiveMapStandalone(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HiveMapStandalone extends StatefulWidget {
  const HiveMapStandalone({super.key});

  @override
  State<HiveMapStandalone> createState() => _HiveMapStandaloneState();
}

class _HiveMapStandaloneState extends State<HiveMapStandalone> {
  bool _debugSnackShown = false;

  @override
  void initState() {
    super.initState();
    // Post-frame: show a one-time debug snackbar and log to console
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_debugSnackShown && mounted) {
        _debugSnackShown = true;
        debugPrint('DEBUG: HIVE MAP EDITOR LOADED (lib/hivemap/main.dart)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DEBUG: Hive Map Editor (lib/hivemap/main.dart)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // App background + editor
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: const HiveMapEditor(readOnly: false),
          ),

          // Always-visible debug ribbon so it's obvious which app is loaded
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'HIVE MAP EDITOR • DEBUG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
