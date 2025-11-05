import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';

class FireCrystalShardScreen extends StatefulWidget {
  const FireCrystalShardScreen({super.key});

  @override
  _FireCrystalShardScreenState createState() => _FireCrystalShardScreenState();
}

class _FireCrystalShardScreenState extends State<FireCrystalShardScreen> {
  final TextEditingController _fcController = TextEditingController();
  final TextEditingController _shardController = TextEditingController();
  final FocusNode _fcNode = FocusNode();
  final FocusNode _shardNode = FocusNode();
  String _fcToShardResult = '';
  String _shardToFCResult = '';
  final NumberFormat _formatter = NumberFormat('#,###');
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('FireCrystalShardScreen');
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    // Load saved values or defaults
    _fcController.text = _prefs.getString('fc_input') ?? '10';
    _shardController.text = _prefs.getString('shard_input') ?? '13';
    // Listeners save & recalc
    _fcController.addListener(() {
      _prefs.setString('fc_input', _fcController.text);
      _calculateBoth();
    });
    _shardController.addListener(() {
      _prefs.setString('shard_input', _shardController.text);
      _calculateBoth();
    });
    _calculateBoth();
  }

  void _calculateBoth() {
    final int? fc = int.tryParse(_fcController.text);
    final int? shards = int.tryParse(_shardController.text);

    if (fc == null || fc <= 0) {
      _fcToShardResult = "Please enter a valid number of Fire Crystals.";
    } else {
      final result = (fc ~/ 10) * 13;
      _fcToShardResult =
          "$fc Fire Crystals will give you ${_formatter.format(result)} Shards.";
    }

    if (shards == null || shards <= 0) {
      _shardToFCResult = "Please enter a valid number of Shards.";
    } else {
      final fcNeeded = ((shards / 13).ceil()) * 10;
      _shardToFCResult =
          "You need approximately ${_formatter.format(fcNeeded)} Fire Crystals to get ${_formatter.format(shards)} Shards.";
    }

    setState(() {});
  }

  @override
  void dispose() {
    _fcController.dispose();
    _shardController.dispose();
    _fcNode.dispose();
    _shardNode.dispose();
    super.dispose();
  }

  KeyboardActionsConfig _keyboardConfig() => KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
        actions: [
          KeyboardActionsItem(
            focusNode: _fcNode,
            toolbarButtons: [
              (node) => IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Done',
                    onPressed: () => node.unfocus(),
                  ),
            ],
          ),
          KeyboardActionsItem(
            focusNode: _shardNode,
            toolbarButtons: [
              (node) => IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Done',
                    onPressed: () => node.unfocus(),
                  ),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fire Crystal Shard Conversion")),
      body: KeyboardActions(
        config: _keyboardConfig(),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Fire Crystals → Shards",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _fcController,
              focusNode: _fcNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration:
                  InputDecoration(labelText: 'Enter number of Fire Crystals'),
            ),
            Text(_fcToShardResult, style: TextStyle(fontSize: 16)),
            SizedBox(height: 30),
            Text("Shards Needed → Fire Crystals",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _shardController,
              focusNode: _shardNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration:
                  InputDecoration(labelText: 'Enter number of Shards needed'),
            ),
            Text(_shardToFCResult, style: TextStyle(fontSize: 16)),
            SizedBox(height: 30),
          ],
        ),
        ),
      ),
    );
  }
}
