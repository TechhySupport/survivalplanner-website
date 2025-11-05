import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hivemap/main.dart';

const supabaseUrl = 'https://wdjophtkpqtpdkbcwxsq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indkam9waHRrcHF0cGRrYmN3eHNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MzAxMTYsImV4cCI6MjA3MDIwNjExNn0.FG3LnqOIJ3fwp5qMAEmYRbF8mwF1ujBiGjEj7E8HnwI';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const HiveMapApp());
}

class HiveMapApp extends StatelessWidget {
  const HiveMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survival Planner HiveMap',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HiveMapEditor(),
      debugShowCheckedModeBanner: false,
    );
  }
}
