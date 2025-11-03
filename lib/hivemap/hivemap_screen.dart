import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/map_service.dart';
import 'hivemap_editor.dart';
import '../web/web_landing.dart';

class HiveMapScreen extends StatefulWidget {
  final String slug;
  final bool wantEdit; // from ?edit=1
  const HiveMapScreen({super.key, required this.slug, this.wantEdit = false});

  @override
  State<HiveMapScreen> createState() => _HiveMapScreenState();
}

class _HiveMapScreenState extends State<HiveMapScreen> {
  Map<String, dynamic>? _row; // null=loading, {}=not found
  bool _canEdit = false;
  bool _isOwner = false;
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _init();
  }

  Future<void> _init() async {
    final row = await MapService.loadMapBySlug(widget.slug);
    if (row == null) {
      setState(() => _row = {});
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    final ownerId = row['owner_id'] as String;
    final shareMode = (row['share_mode'] ?? 'private').toString();
    final isOwner = user != null && user.id == ownerId;
    // Editing rules:
    // - Owner can always edit
    // - Public edit is allowed only if share mode is 'edit' AND link has ?edit=1
    // - Otherwise: view-only
    final bool allowEdit;
    if (isOwner) {
      allowEdit = true;
    } else if (shareMode == 'edit' && widget.wantEdit) {
      allowEdit = true;
    } else {
      allowEdit = false;
    }

    // Prepare local cache for HiveMapEditor to load as the "last map"
    final p = await SharedPreferences.getInstance();
    final id = 'shared_${widget.slug}';
    final objects = MapService.extractObjectsList(row['data']);
    final dataStr = jsonEncode(objects);
    await p.setString('hivemap_map_$id', dataStr);
    // Update metas so editor can show a name and find it in picker
    final metaKey = 'hivemap_maps_meta_v1';
    final nowIso = DateTime.now().toIso8601String();
    List<dynamic> metas = [];
    try {
      final s = p.getString(metaKey);
      if (s != null && s.isNotEmpty) metas = jsonDecode(s);
    } catch (_) {}
    final name = (row['name'] ?? 'Shared Map').toString();
    final idx = metas.indexWhere((m) => m is Map && m['id'] == id);
    final meta = {
      'id': id,
      'name': name,
      'updatedAt': nowIso,
      'fromCloud': true,
    };
    if (idx == -1) {
      metas.add(meta);
    } else {
      metas[idx] = meta;
    }
    await p.setString(metaKey, jsonEncode(metas));
    await p.setString('hivemap_last_id', id);

    setState(() {
      _row = row;
      _canEdit = allowEdit;
      _isOwner = isOwner;
    });
  }

  Future<void> _openShareDialog() async {
    if (_row == null || _row!.isEmpty) return;
    String mode = (_row!['share_mode'] ?? 'private').toString();
    final slug = _row!['slug'] as String;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => AlertDialog(
          title: const Text('Share Map'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sharing mode'),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: mode,
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                  DropdownMenuItem(
                    value: 'view',
                    child: Text('View (read-only)'),
                  ),
                  DropdownMenuItem(
                    value: 'edit',
                    child: Text('Edit (anyone with link)'),
                  ),
                ],
                onChanged: (v) => setSB(() => mode = v ?? mode),
              ),
              const SizedBox(height: 12),
              const Text('Links'),
              const SizedBox(height: 6),
              _LinkRow(label: 'View', url: MapService.viewLink(slug)),
              const SizedBox(height: 6),
              _LinkRow(label: 'Edit', url: MapService.editLink(slug)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                await MapService.setShareMode(slug, mode);
                if (mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share settings updated')),
                  );
                }
                setState(() => _row!['share_mode'] = mode);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToSharedMap() async {
    if (_row == null || _row!.isEmpty) return;
    final slug = _row!['slug'] as String;
    final p = await SharedPreferences.getInstance();
    // Read latest doc from editor's last id
    final lastId = p.getString('hivemap_last_id');
    if (lastId == null) return;
    final s = p.getString('hivemap_map_$lastId');
    if (s == null || s.isEmpty) return;
    List<dynamic> objects = [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) objects = decoded;
    } catch (_) {}
    final payload = <String, dynamic>{'objects': objects};
    await MapService.saveMap(slug, payload);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Map saved to shared link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_row == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_row!.isEmpty) {
      return const Scaffold(body: Center(child: Text('Map not found')));
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text((_row!['name'] ?? 'Hive Map').toString()),
        actions: [
          TextButton.icon(
            onPressed: _openShareDialog,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          if (_canEdit)
            TextButton.icon(
              onPressed: _saveToSharedMap,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          if (_isOwner)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Map'),
                    content: const Text('Are you sure? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await MapService.deleteMap(widget.slug);
                    if (!mounted) return;
                    // Go back to home after deletion
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const WebLandingPage()),
                      (route) => false,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Delete failed: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Delete Map',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // Show the editor with the locally prepared map
          // Pass readOnly based on allowEdit decision
          return HiveMapEditor(readOnly: !_canEdit);
        },
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String url;
  const _LinkRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 52, child: Text('$label:')),
        Expanded(
          child: SelectableText(url, style: const TextStyle(fontSize: 12)),
        ),
        IconButton(
          tooltip: 'Copy',
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
        ),
      ],
    );
  }
}
