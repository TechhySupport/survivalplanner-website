import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  @override
  void initState() {
    super.initState();
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
        ],
      ),
    );
  }
}
