import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hivemap/main.dart';
import 'survival_planner_calculator/main.dart' as calculator;

const supabaseUrl = 'https://wdjophtkpqtpdkbcwxsq.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indkam9waHRrcHF0cGRrYmN3eHNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MzAxMTYsImV4cCI6MjA3MDIwNjExNn0.FG3LnqOIJ3fwp5qMAEmYRbF8mwF1ujBiGjEj7E8HnwI';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const SurvivalPlannerApp());
}

class SurvivalPlannerApp extends StatelessWidget {
  const SurvivalPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survival Planner',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      initialRoute: _getInitialRoute(),
      routes: {
        '/': (context) => const AppLandingPage(),
        '/hivemap': (context) => const HiveMapEditor(),
        '/calculator': (context) => const calculator.MyApp(),
      },
      onGenerateRoute: (settings) {
        // Handle deep linking for web
        if (settings.name?.startsWith('/hivemap') == true) {
          return MaterialPageRoute(
            builder: (context) => const HiveMapEditor(),
            settings: settings,
          );
        }
        if (settings.name?.startsWith('/calculator') == true) {
          return MaterialPageRoute(
            builder: (context) => const calculator.MyApp(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }

  String _getInitialRoute() {
    if (kIsWeb) {
      // Check URL fragments for routing
      final hash = Uri.base.fragment;
      if (hash.contains('hivemap') ||
          hash.contains('file:hivemap_editor.dart')) {
        return '/hivemap';
      }
      if (hash.contains('calculator')) {
        return '/calculator';
      }

      // Check query parameters
      final queryParams = Uri.base.queryParameters;
      if (queryParams['go'] == 'hivemap') {
        return '/hivemap';
      }
      if (queryParams['go'] == 'calculator') {
        return '/calculator';
      }
    }
    return '/';
  }
}

class AppLandingPage extends StatelessWidget {
  const AppLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survival Planner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gamepad_outlined, size: 100, color: Colors.blue),
            const SizedBox(height: 30),
            const Text(
              'Welcome to Survival Planner',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Choose your tool:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureCard(
                  context,
                  title: 'HiveMap Editor',
                  description: 'Interactive map editor for base planning',
                  icon: Icons.map_outlined,
                  route: '/hivemap',
                ),
                const SizedBox(width: 30),
                _buildFeatureCard(
                  context,
                  title: 'Calculators',
                  description: 'Resource and building calculators',
                  icon: Icons.calculate_outlined,
                  route: '/calculator',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 250,
          height: 200,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: Theme.of(context).primaryColor),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
