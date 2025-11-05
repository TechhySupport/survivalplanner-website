import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:html' as html; // Web-only: used for downloading files
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'
    show MatrixUtils, RenderBox, RenderRepaintBoundary;
import 'package:shared_preferences/shared_preferences.dart';
import 'grid_renderer.dart';
import 'models.dart';
import 'placement_rules.dart';
import 'members.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'toolbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/map_service.dart';
import '../services/loginscreen.dart';
import 'package:image/image.dart' as img;

// Lightweight metadata for saved maps (local or cloud)
class _MapMeta {
  final String id;
  final String name;
  final DateTime updatedAt;
  final bool fromCloud;

  _MapMeta({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.fromCloud = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'updatedAt': updatedAt.toIso8601String(),
    'fromCloud': fromCloud,
  };

  static _MapMeta fromJson(Map<String, dynamic> m) {
    final raw = m['updatedAt'] ?? m['updated_at'];
    DateTime when;
    if (raw is String) {
      when = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is int) {
      when = DateTime.fromMillisecondsSinceEpoch(raw);
    } else {
      when = DateTime.now();
    }
    return _MapMeta(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? 'Untitled').toString(),
      updatedAt: when,
      fromCloud: (m['fromCloud'] as bool?) ?? false,
    );
  }
}

class HiveMapEditor extends StatefulWidget {
  final bool readOnly;
  const HiveMapEditor({super.key, this.readOnly = false});

  @override
  State<HiveMapEditor> createState() => _HiveMapEditorState();
}

class _HiveMapEditorState extends State<HiveMapEditor> {
  int _viewportSize = 30; // 15 | 30 | 50

  // Window origin in game coordinates (top-left of the visible grid)
  int _originGameX = 0;
  int _originGameY = 0;

  final List<GridObject> _objects = <GridObject>[];
  ToolSelection _selected = const ToolSelection(ObjectType.select, 'Select');
  // Members data store for list/import
  final List<MemberRecord> _members = <MemberRecord>[];

  int? _highlightedIndex;

  // Coordinates overlay and selection
  bool _showCoordinates = false;
  bool _showBuildingCoordinates = false;
  bool _hideRadius = false;
  int? _selectedTileX;
  int? _selectedTileY;

  // Member highlighting and animation
  Timer? _memberHighlightTimer;
  int? _highlightMemberIndex;
  int _highlightAnimationStep = 0;

  // BT rank tracking for auto-increment
  final Map<String, int> _lastBTRank = {'BT1': 0, 'BT2': 0, 'BT3': 0};

  // Attendance feature toggle
  bool _attendanceEnabled = false;

  // Hover preview state
  int? _hoverGameX;
  int? _hoverGameY;

  // Drag drawing state for lakes/mountains
  bool _isDragging = false;
  final Set<Point<int>> _draggedTiles = <Point<int>>{};

  // Drag move state for objects
  bool _isDragMoving = false;
  int? _dragMoveObjectIndex;

  // Map view lock state
  bool _isMapViewLocked = false;

  // First-time user setup state
  bool _isFirstTimeUser = true;
  bool _showSetupFlow = false;

  // Setup flow state
  Map<String, Map<String, int?>> _setupBTCoordinates = {
    'BT1': {'x': null, 'y': null},
    'BT2': {'x': null, 'y': null},
    'BT3': {'x': null, 'y': null},
  };
  bool _useBT3 = false;
  int _setupStep =
      0; // 0: welcome, 1: BT1, 2: BT2, 3: BT3?, 4: members, 5: complete

  // Context menu state
  Offset? _menuPosition; // viewport-local position
  int? _menuObjectIndex;

  final TransformationController _controller = TransformationController();
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();

  // Undo/Redo stacks for map object edits
  final List<List<GridObject>> _undoStack = <List<GridObject>>[];
  final List<List<GridObject>> _redoStack = <List<GridObject>>[];

  final TextEditingController _searchX = TextEditingController();
  final TextEditingController _searchY = TextEditingController();

  // ---- Multi-map & Cloud Sync ----
  String? _currentMapId;
  String _currentMapName = 'Untitled Map';
  bool _isSyncing = false;
  // Debounced cloud snapshot save (calculator_data)
  Timer? _cloudSaveDebounce;
  String? _lastSavedSignature; // traps+scale signature to avoid no-op saves

  // Supabase client accessed via Supabase.instance.client where needed

  // Local storage keys
  static const String _mapsMetaKey = 'hivemap_maps_meta_v1';
  static const String _mapDocPrefix = 'hivemap_map_';
  static const String _legacyMapKey = 'hivemap_saved_objects_v1';
  static const String _membersStorageKey = 'hivemap_members_v1';

  // Export (JPG) helpers
  final GlobalKey _exportKey = GlobalKey();
  bool _exportHostVisible = false;
  int _exportSize = 30; // 30 or 50
  bool _exportShowCoords = false;
  bool _exportShowGrid = true;

  String _genId() {
    final r = Random();
    // Use a JS-safe positive max (avoid 1<<32 which overflows to 0 in JS)
    const int maxRand = 0x3fffffff; // 2^30 - 1 (extra safety for web)
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(maxRand)}';
  }

  // Format power with commas
  String _formatPower(int power) {
    return power.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Find member coordinates by rank and group
  String _getMemberCoordinates(String group, int rank) {
    for (final obj in _objects) {
      if (obj.type == ObjectType.member &&
          obj.memberGroup == group &&
          obj.rank == rank) {
        return '${obj.gameX}, ${obj.gameY}';
      }
    }
    return 'Not placed';
  }

  // Navigate to member and highlight them
  void _navigateToMember(String group, int rank) {
    for (int i = 0; i < _objects.length; i++) {
      final obj = _objects[i];
      if (obj.type == ObjectType.member &&
          obj.memberGroup == group &&
          obj.rank == rank) {
        // Center view on member
        setState(() {
          _originGameX = (obj.gameX - _viewportSize ~/ 2).clamp(
            0,
            1200 - _viewportSize,
          );
          _originGameY = (obj.gameY - _viewportSize ~/ 2).clamp(
            0,
            1200 - _viewportSize,
          );
          _highlightMemberIndex = i;
          _highlightAnimationStep = 0;
        });

        // Start flashing animation
        _memberHighlightTimer?.cancel();
        _memberHighlightTimer = Timer.periodic(
          const Duration(milliseconds: 300),
          (timer) {
            setState(() {
              _highlightAnimationStep = (_highlightAnimationStep + 1) % 6;
            });
            if (_highlightAnimationStep == 0 && timer.tick >= 6) {
              timer.cancel();
              setState(() {
                _highlightMemberIndex = null;
              });
            }
          },
        );
        break;
      }
    }
  }

  // Show save options dialog
  Future<void> _showSaveDialog() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      // User is logged in, save to cloud
      await _saveMap();
      return;
    }

    // User not logged in, show options
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Map'),
        content: const Text('How would you like to save your map?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'local'),
            child: const Text('Save Locally'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'cloud'),
            child: const Text('Login & Save to Cloud'),
          ),
        ],
      ),
    );

    switch (result) {
      case 'local':
        await _saveMapLocal();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Map saved locally')));
        }
        break;
      case 'cloud':
        final loginResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (loginResult == true) {
          // User successfully logged in, now save to cloud
          await _saveMap();
        }
        break;
      case 'cancel':
      default:
        // Do nothing
        break;
    }
  }

  // Edit map name
  Future<void> _editMapName() async {
    final controller = TextEditingController(text: _currentMapName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Map Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Map Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _currentMapName) {
      setState(() {
        _currentMapName = result;
      });
      await _saveMap();
    }
  }

  Future<List<_MapMeta>> _loadLocalMapsMeta() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_mapsMetaKey);
    if (s == null || s.isEmpty) return [];
    try {
      final list = (jsonDecode(s) as List)
          .map((e) => _MapMeta.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalMapsMeta(List<_MapMeta> metas) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _mapsMetaKey,
      jsonEncode(metas.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _ensureMigratedFromLegacy() async {
    final p = await SharedPreferences.getInstance();
    final metas = await _loadLocalMapsMeta();
    if (metas.isNotEmpty) return;
    final s = p.getString(_legacyMapKey);
    if (s == null || s.isEmpty) return;
    final id = _genId();
    await p.setString('$_mapDocPrefix$id', s);
    final meta = _MapMeta(
      id: id,
      name: 'My Hive Map',
      updatedAt: DateTime.now(),
    );
    await _saveLocalMapsMeta([meta]);
    _currentMapId = id;
    _currentMapName = meta.name;
  }

  Future<void> _openMapPicker({bool force = false}) async {
    if (!force && _currentMapId != null) return;
    final metas = await _loadLocalMapsMeta();
    final cloud = await _fetchCloudMetasSafe();
    final merged = _mergeMetas(metas, cloud);
    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Hive Maps'),
        content: SizedBox(
          width: 520,
          height: 340,
          child: merged.isEmpty
              ? const Center(child: Text('No maps yet'))
              : ListView.builder(
                  itemCount: merged.length,
                  itemBuilder: (_, i) {
                    final m = merged[i];
                    return ListTile(
                      leading: Icon(
                        m.fromCloud ? Icons.cloud_outlined : Icons.folder,
                      ),
                      title: Text(m.name),
                      subtitle: Text('Updated ${m.updatedAt.toLocal()}'),
                      onTap: () => Navigator.pop(ctx, m),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, '__create__'),
            icon: const Icon(Icons.add),
            label: const Text('Create new map'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == '__create__') {
      await _createNewMap();
    } else if (result is _MapMeta) {
      await _loadMapByMeta(result);
    }
  }

  List<_MapMeta> _mergeMetas(List<_MapMeta> a, List<_MapMeta> b) {
    final map = <String, _MapMeta>{for (final m in a) m.id: m};
    for (final m in b) {
      final existing = map[m.id];
      if (existing == null || m.updatedAt.isAfter(existing.updatedAt)) {
        map[m.id] = m;
      }
    }
    final list = map.values.toList()
      ..sort((x, y) => y.updatedAt.compareTo(x.updatedAt));
    return list;
  }

  Future<void> _createNewMap() async {
    final nameCtrl = TextEditingController(text: 'New Map');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create a new map'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Map name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    _pushUndoState();
    setState(() {
      _objects.clear();
      _currentMapId = _genId();
      _currentMapName = name;
    });
    await _saveMapLocal();
    await _maybeSyncToCloud();
  }

  Future<void> _loadMapByMeta(_MapMeta meta) async {
    final ok = await _loadMapLocal(meta.id);
    if (!ok) {
      await _loadMapCloud(meta.id);
    }
    setState(() {
      _currentMapId = meta.id;
      _currentMapName = meta.name;
    });
  }

  @override
  void initState() {
    super.initState();
    // Start centered roughly at world center
    final center = (worldMax + 1) ~/ 2; // ~600
    _setViewportAround(center, center);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerOnViewportCenter(),
    );
    _loadMap();
    _loadMembers();
    // Also try loading cloud-saved single map (one per user)
    loadHiveMap();

    // Check if this is a first-time user
    _checkFirstTimeUser();

    // Re-attempt cloud load/save once auth session becomes available/refreshed
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final evt = data.event;
      if (evt == AuthChangeEvent.signedIn ||
          evt == AuthChangeEvent.tokenRefreshed) {
        debugPrint('hivemap: auth event $evt – syncing cloud');
        // Load any cloud-saved traps and also push local to cloud
        loadHiveMap();
        _scheduleCloudSnapshotSave();
      }
    });
  }

  @override
  void dispose() {
    _cloudSaveDebounce?.cancel();
    _authSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details) {
    // Check if we're in drag move mode first
    if (_isDragMoving && _dragMoveObjectIndex != null) {
      final gameCoords = _convertTapToGameCoords(details.globalPosition);
      if (gameCoords != null) {
        final idx = _dragMoveObjectIndex!;
        final obj = _objects[idx];

        // Check if we can place the object at this position
        final ok = canPlaceCenter(
          existing: _objects,
          type: obj.type,
          centerX: gameCoords.x,
          centerY: gameCoords.y,
          ignoreIndex: idx,
        );

        if (ok) {
          _pushUndoState();
          setState(() {
            _objects[idx] = obj.copyWith(
              gameX: gameCoords.x,
              gameY: gameCoords.y,
            );
            _highlightedIndex = idx;
            _isDragMoving = false;
            _dragMoveObjectIndex = null;
          });
          _saveMap();
          _setViewportAround(gameCoords.x, gameCoords.y);
          _centerOnViewportCenter();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot move here (overlap or out of bounds)'),
              ),
            );
          }
        }
      }
      return;
    }

    // Convert to scene coordinates
    final sceneCtx = _sceneKey.currentContext;
    if (sceneCtx == null) return; // Scene not ready
    final renderObj = sceneCtx.findRenderObject();
    if (renderObj is! RenderBox) return;
    final local = renderObj.globalToLocal(details.globalPosition);
    final inv = _controller.value.clone()..invert();
    final scene = MatrixUtils.transformPoint(inv, local);

    // Scene -> grid indices
    const halfW = GridRenderer.halfW;
    const halfH = GridRenderer.halfH;
    final originX = _viewportSize * halfW;
    final nx = (scene.dx - originX) / halfW;
    final ny = (scene.dy) / halfH;
    final gx = ((ny + nx) / 2).floor();
    final gy = ((ny - nx) / 2).floor();
    if (gx < 0 || gy < 0 || gx >= _viewportSize || gy >= _viewportSize) return;

    // Grid indices -> game coordinates
    final gameGX = _originGameX + gx;
    final gameGY = _originGameY + gy;
    // Always record the selected tile (game coordinates)
    setState(() {
      _selectedTileX = gameGX;
      _selectedTileY = gameGY;
    });

    // Hit test existing objects first (using game coordinates)
    final hit = hitTestObjects(_objects, gameGX, gameGY);
    if (hit != -1) {
      final rb = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
      if (rb != null) {
        final localPos = rb.globalToLocal(details.globalPosition);
        setState(() {
          _menuPosition = localPos;
          _menuObjectIndex = hit;
          _highlightedIndex = hit;
        });
      }
      return;
    }
    // Place currently selected tool on tap (no coordinate dialog)
    final t = _selected.type;

    // Don't place objects when select tool is active
    if (t == ObjectType.select) {
      return;
    }

    // Check if trying to place a BT when one already exists
    if (t == ObjectType.bearTrap) {
      final existingBTs = _objects.where(
        (obj) => obj.type == ObjectType.bearTrap,
      );
      for (final bt in existingBTs) {
        if (bt.name == _selected.name) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_selected.name} already exists on the map'),
              ),
            );
          }
          return;
        }
      }
    }

    final ok = canPlaceCenter(
      existing: _objects,
      type: t,
      centerX: gameGX,
      centerY: gameGY,
    );
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot place ${_selected.name} here (overlap or out of bounds)',
            ),
          ),
        );
      }
      return;
    }
    // Snapshot before placement for undo
    _pushUndoState();
    setState(() {
      String? mGroup;
      int? rank;
      String? memberName;
      if (t == ObjectType.member) {
        if (_selected.name.contains('BT1')) {
          mGroup = 'BT1';
          if (_lastBTRank['BT1']! >= 100) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot add more than 100 BT1 members'),
                ),
              );
            }
            return;
          }
          _lastBTRank['BT1'] = _lastBTRank['BT1']! + 1;
          rank = _lastBTRank['BT1'];
        } else if (_selected.name.contains('BT2')) {
          mGroup = 'BT2';
          if (_lastBTRank['BT2']! >= 100) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot add more than 100 BT2 members'),
                ),
              );
            }
            return;
          }
          _lastBTRank['BT2'] = _lastBTRank['BT2']! + 1;
          rank = _lastBTRank['BT2'];
        } else if (_selected.name.contains('BT3')) {
          mGroup = 'BT3';
          if (_lastBTRank['BT3']! >= 100) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot add more than 100 BT3 members'),
                ),
              );
            }
            return;
          }
          _lastBTRank['BT3'] = _lastBTRank['BT3']! + 1;
          rank = _lastBTRank['BT3'];
        }

        // Auto-resolve member name from rank if available
        if (mGroup != null && rank != null) {
          final rankedMembers = _rankedMembersByGroup(mGroup);
          if (rank <= rankedMembers.length) {
            memberName = rankedMembers[rank - 1].name;
          }
        }
      }
      _objects.add(
        GridObject(
          type: t,
          name: _selected.name,
          gameX: gameGX,
          gameY: gameGY,
          memberGroup: mGroup,
          rank: rank,
          memberName: memberName,
        ),
      );
      _highlightedIndex = _objects.length - 1;
      _menuPosition = null;
      _menuObjectIndex = null;
      _selectedTileX = gameGX;
      _selectedTileY = gameGY;

      // If placing a BT, center the grid on it
      if (t == ObjectType.bearTrap) {
        _setViewportAround(gameGX, gameGY);
        _centerOnViewportCenter();
      }
    });
    _saveMap();
  }

  void _handleHover(PointerHoverEvent event) {
    // Convert to scene coordinates
    final sceneCtx = _sceneKey.currentContext;
    if (sceneCtx == null) return;
    final renderObj = sceneCtx.findRenderObject();
    if (renderObj is! RenderBox) return;
    final local = renderObj.globalToLocal(event.position);
    final inv = _controller.value.clone()..invert();
    final scene = MatrixUtils.transformPoint(inv, local);

    // Scene -> grid indices
    const halfW = GridRenderer.halfW;
    const halfH = GridRenderer.halfH;
    final originX = _viewportSize * halfW;
    final nx = (scene.dx - originX) / halfW;
    final ny = (scene.dy) / halfH;
    final gx = ((ny + nx) / 2).floor();
    final gy = ((ny - nx) / 2).floor();
    if (gx < 0 || gy < 0 || gx >= _viewportSize || gy >= _viewportSize) {
      _clearHover();
      return;
    }

    // Grid indices -> game coordinates
    final gameGX = _originGameX + gx;
    final gameGY = _originGameY + gy;

    setState(() {
      _hoverGameX = gameGX;
      _hoverGameY = gameGY;
    });
  }

  void _clearHover() {
    setState(() {
      _hoverGameX = null;
      _hoverGameY = null;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    final type = _selected.type;

    // Don't allow drag drawing when select tool is active
    if (type == ObjectType.select) {
      return;
    }

    // Enable drag drawing for lakes, mountains, and members
    if (type != ObjectType.lake &&
        type != ObjectType.mountain &&
        type != ObjectType.member) {
      return;
    }

    _isDragging = true;
    _draggedTiles.clear();

    // Add the starting tile
    final coords = _convertTapToGameCoords(details.globalPosition);
    if (coords != null) {
      _addDragTile(coords.x, coords.y);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final coords = _convertTapToGameCoords(details.globalPosition);
    if (coords != null) {
      _addDragTile(coords.x, coords.y);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;
    _finalizeDragDrawing();
  }

  ({int x, int y})? _convertTapToGameCoords(Offset globalPosition) {
    final sceneCtx = _sceneKey.currentContext;
    if (sceneCtx == null) return null;
    final renderObj = sceneCtx.findRenderObject();
    if (renderObj is! RenderBox) return null;
    final local = renderObj.globalToLocal(globalPosition);
    final inv = _controller.value.clone()..invert();
    final scene = MatrixUtils.transformPoint(inv, local);

    const halfW = GridRenderer.halfW;
    const halfH = GridRenderer.halfH;
    final originX = _viewportSize * halfW;
    final nx = (scene.dx - originX) / halfW;
    final ny = (scene.dy) / halfH;
    final gx = ((ny + nx) / 2).floor();
    final gy = ((ny - nx) / 2).floor();
    if (gx < 0 || gy < 0 || gx >= _viewportSize || gy >= _viewportSize)
      return null;

    final gameGX = _originGameX + gx;
    final gameGY = _originGameY + gy;
    return (x: gameGX, y: gameGY);
  }

  void _addDragTile(int gameX, int gameY) {
    final point = Point<int>(gameX, gameY);
    if (_draggedTiles.contains(point)) return;

    final type = _selected.type;
    final ok = canPlaceCenter(
      existing: _objects,
      type: type,
      centerX: gameX,
      centerY: gameY,
    );

    if (ok) {
      _draggedTiles.add(point);

      String? mGroup;
      int? rank;
      String? memberName;

      // Handle member placement with auto-incrementing ranks
      if (type == ObjectType.member) {
        if (_selected.name.contains('BT1')) {
          mGroup = 'BT1';
          if (_lastBTRank['BT1']! >= 100) {
            return; // Skip placement if limit reached
          }
          _lastBTRank['BT1'] = _lastBTRank['BT1']! + 1;
          rank = _lastBTRank['BT1'];
        } else if (_selected.name.contains('BT2')) {
          mGroup = 'BT2';
          if (_lastBTRank['BT2']! >= 100) {
            return; // Skip placement if limit reached
          }
          _lastBTRank['BT2'] = _lastBTRank['BT2']! + 1;
          rank = _lastBTRank['BT2'];
        } else if (_selected.name.contains('BT3')) {
          mGroup = 'BT3';
          if (_lastBTRank['BT3']! >= 100) {
            return; // Skip placement if limit reached
          }
          _lastBTRank['BT3'] = _lastBTRank['BT3']! + 1;
          rank = _lastBTRank['BT3'];
        }

        // Auto-resolve member name from rank if available
        if (mGroup != null && rank != null) {
          final rankedMembers = _rankedMembersByGroup(mGroup);
          if (rank <= rankedMembers.length) {
            memberName = rankedMembers[rank - 1].name;
          }
        }
      }

      // Add the object immediately for visual feedback
      setState(() {
        _objects.add(
          GridObject(
            type: type,
            name: _selected.name,
            gameX: gameX,
            gameY: gameY,
            memberGroup: mGroup,
            rank: rank,
            memberName: memberName,
          ),
        );
      });
    }
  }

  void _finalizeDragDrawing() {
    if (_draggedTiles.isNotEmpty) {
      _saveMap();
    }
    _draggedTiles.clear();
  }

  void _moveGrid(int deltaX, int deltaY) {
    if (_isMapViewLocked) return; // Don't move if locked

    setState(() {
      _originGameX += deltaX;
      _originGameY += deltaY;

      // Ensure we don't go below 0
      if (_originGameX < 0) _originGameX = 0;
      if (_originGameY < 0) _originGameY = 0;

      // Ensure we don't go beyond world bounds
      final maxOrigin = worldMax - _viewportSize + 1;
      if (_originGameX > maxOrigin) _originGameX = maxOrigin;
      if (_originGameY > maxOrigin) _originGameY = maxOrigin;
    });
  }

  void _openMembersListDialog() {
    showDialog<void>(
      context: context,
      builder: (outerCtx) {
        String filter = 'All';
        Color groupColor(String g) {
          switch (g.toUpperCase()) {
            case 'BT1':
              return Colors.blue.shade100;
            case 'BT2':
              return Colors.green.shade100;
            case 'BT3':
              return Colors.grey.shade300;
            default:
              return Colors.blueGrey.shade100;
          }
        }

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            List<MemberRecord> listForFilter() {
              if (filter == 'All') {
                return [
                  ..._rankedMembersByGroup('BT1'),
                  ..._rankedMembersByGroup('BT2'),
                  ..._rankedMembersByGroup('BT3'),
                ];
              }
              return _rankedMembersByGroup(filter);
            }

            int rankInGroup(MemberRecord item) {
              final sorted = _rankedMembersByGroup(item.group);
              final idx = sorted.indexWhere(
                (m) =>
                    m.name.toLowerCase() == item.name.toLowerCase() &&
                    m.power == item.power,
              );
              return (idx >= 0 ? idx : 0) + 1;
            }

            final members = listForFilter();

            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Members'),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: filter == 'All',
                            onSelected: (_) =>
                                setStateDialog(() => filter = 'All'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('BT1'),
                            selected: filter == 'BT1',
                            onSelected: (_) =>
                                setStateDialog(() => filter = 'BT1'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('BT2'),
                            selected: filter == 'BT2',
                            onSelected: (_) =>
                                setStateDialog(() => filter = 'BT2'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('BT3'),
                            selected: filter == 'BT3',
                            onSelected: (_) =>
                                setStateDialog(() => filter = 'BT3'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: _attendanceEnabled,
                        onChanged: (value) {
                          setState(() => _attendanceEnabled = value);
                          setStateDialog(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('Enable Attendance Mode'),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: 900,
                height: 560,
                child: members.isEmpty
                    ? const Center(child: Text('No members'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.6,
                            ),
                        itemCount: members.length,
                        itemBuilder: (_, i) {
                          final item = members[i];
                          final rank = rankInGroup(item);
                          final color = groupColor(item.group);
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: color, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '#$rank',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _navigateToMember(item.group, rank);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          if (_attendanceEnabled) ...[
                                            Text(
                                              '${item.group} • True Power: ${_formatPower(item.power)}',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Total Power: ${_formatPower(item.effectivePower)} (${item.attendance}%)',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ] else
                                            Text(
                                              '${item.group} • Power ${_formatPower(item.power)}',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13,
                                              ),
                                            ),
                                          if (_attendanceEnabled) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Attendance: ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Slider(
                                                    value: item.attendance
                                                        .toDouble(),
                                                    min: 0,
                                                    max: 100,
                                                    divisions: 20,
                                                    label:
                                                        '${item.attendance}%',
                                                    onChanged: (value) {
                                                      // Just update the visual state during dragging
                                                      setStateDialog(() {});
                                                    },
                                                    onChangeEnd: (value) {
                                                      final newAttendance =
                                                          value.round();
                                                      final memberIndex =
                                                          _members.indexWhere(
                                                            (m) =>
                                                                m.name ==
                                                                    item.name &&
                                                                m.group ==
                                                                    item.group,
                                                          );
                                                      if (memberIndex != -1) {
                                                        setState(() {
                                                          _members[memberIndex] =
                                                              _members[memberIndex]
                                                                  .copyWith(
                                                                    attendance:
                                                                        newAttendance,
                                                                  );
                                                        });
                                                        setStateDialog(() {});
                                                        _saveMembers();
                                                      }
                                                    },
                                                  ),
                                                ),
                                                Text(
                                                  '${item.attendance}%',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Text(
                                            'Coordinates: ${_getMemberCoordinates(item.group, rank)}',
                                            style: const TextStyle(
                                              color: Colors.black45,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          final edited =
                                              await _promptMemberEditor(
                                                existing: item,
                                              );
                                          if (edited == null) return;
                                          setState(() {
                                            final globalIdx = _members
                                                .indexWhere(
                                                  (m) =>
                                                      m.name.toLowerCase() ==
                                                          item.name
                                                              .toLowerCase() &&
                                                      m.group == item.group &&
                                                      m.power == item.power,
                                                );
                                            if (globalIdx != -1) {
                                              _members[globalIdx] = edited;
                                            }
                                          });
                                          await _saveMembers();
                                          _refreshAllMemberNames();
                                          setStateDialog(() {});
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          setState(() {
                                            _members.removeWhere(
                                              (m) =>
                                                  m.name.toLowerCase() ==
                                                      item.name.toLowerCase() &&
                                                  m.group == item.group &&
                                                  m.power == item.power,
                                            );
                                          });
                                          await _saveMembers();
                                          _refreshAllMemberNames();
                                          setStateDialog(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(outerCtx),
                  child: const Text('Close'),
                ),
                if (!widget.readOnly)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final created = await _promptMemberEditor();
                      if (created == null) return;
                      setState(() {
                        _members.add(created);
                      });
                      await _saveMembers();
                      _refreshAllMemberNames();
                      setStateDialog(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Member'),
                  ),
                if (!widget.readOnly)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _importMembersFromSpreadsheet();
                      setStateDialog(() {});
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Import Spreadsheet'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: Container(
              key: _viewportKey,
              color: const Color(0xFFF7F9FC),
              child: Stack(
                children: [
                  InteractiveViewer(
                    key: _sceneKey,
                    transformationController: _controller,
                    minScale: 0.4,
                    maxScale: 4.0,
                    constrained: false,
                    child: MouseRegion(
                      onHover: widget.readOnly ? null : _handleHover,
                      onExit: widget.readOnly ? null : (_) => _clearHover(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: widget.readOnly ? null : _handleTap,
                        onPanStart: widget.readOnly ? null : _handlePanStart,
                        onPanUpdate: widget.readOnly ? null : _handlePanUpdate,
                        onPanEnd: widget.readOnly ? null : _handlePanEnd,
                        child: GridRenderer(
                          gridW: _viewportSize,
                          gridH: _viewportSize,
                          objects: _objects,
                          originGameX: _originGameX,
                          originGameY: _originGameY,
                          highlightedIndex:
                              _highlightedIndex ?? _highlightMemberIndex,
                          showCoordinates: _showCoordinates,
                          hideRadius: _hideRadius,
                          showBuildingCoordinates: _showBuildingCoordinates,
                          selectedTileGameX: _selectedTileX,
                          selectedTileGameY: _selectedTileY,
                          hoverGameX: _hoverGameX,
                          hoverGameY: _hoverGameY,
                          hoverObjectType:
                              _isDragMoving && _dragMoveObjectIndex != null
                              ? _objects[_dragMoveObjectIndex!].type
                              : _selected.type,
                          showCrosshair: _selected.type != ObjectType.select,
                        ),
                      ),
                    ),
                  ),

                  // Navigation arrows
                  if (!widget.readOnly) ...[
                    // Top arrow
                    Positioned(
                      top: 20,
                      left: MediaQuery.of(context).size.width / 2 - 20,
                      child: IconButton(
                        onPressed: () => _moveGrid(0, -1),
                        icon: const Icon(Icons.keyboard_arrow_up),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                    // Bottom arrow
                    Positioned(
                      bottom: 20,
                      left: MediaQuery.of(context).size.width / 2 - 20,
                      child: IconButton(
                        onPressed: () => _moveGrid(0, 1),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                    // Left arrow
                    Positioned(
                      top: MediaQuery.of(context).size.height / 2 - 20,
                      left: 20,
                      child: IconButton(
                        onPressed: () => _moveGrid(-1, 0),
                        icon: const Icon(Icons.keyboard_arrow_left),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                    // Center coordinates display
                    Positioned(
                      top: MediaQuery.of(context).size.height / 2 + 30,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Center: (${_originGameX + _viewportSize ~/ 2}, ${_originGameY + _viewportSize ~/ 2})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Map view lock button
                    Positioned(
                      top: MediaQuery.of(context).size.height / 2 + 60,
                      left: 20,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isMapViewLocked = !_isMapViewLocked;
                          });
                        },
                        icon: Icon(
                          _isMapViewLocked ? Icons.lock : Icons.lock_open,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isMapViewLocked
                              ? Colors.red.withOpacity(0.8)
                              : Colors.white.withOpacity(0.8),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                    // Right arrow
                    Positioned(
                      top: MediaQuery.of(context).size.height / 2 - 20,
                      right: 20,
                      child: IconButton(
                        onPressed: () => _moveGrid(1, 0),
                        icon: const Icon(Icons.keyboard_arrow_right),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ],
                  if (_menuPosition != null &&
                      _menuObjectIndex != null &&
                      !widget.readOnly)
                    Positioned(
                      left: _menuPosition!.dx,
                      top: _menuPosition!.dy,
                      child: _ObjectMenu(
                        object: _objects[_menuObjectIndex!],
                        onDragMove: () {
                          // Enable drag move mode
                          setState(() {
                            _isDragMoving = true;
                            _dragMoveObjectIndex = _menuObjectIndex;
                            _menuPosition = null;
                            _menuObjectIndex = null;
                          });
                        },
                        onCoordinateMove: () async {
                          final idx = _menuObjectIndex!;
                          final obj = _objects[idx];
                          _menuPosition = null;
                          _menuObjectIndex = null;
                          final coords = await _promptCoordinates(
                            initialX: obj.gameX,
                            initialY: obj.gameY,
                          );
                          if (coords == null) return;
                          final ok = canPlaceCenter(
                            existing: _objects,
                            type: obj.type,
                            centerX: coords.x,
                            centerY: coords.y,
                            ignoreIndex: idx,
                          );
                          if (!ok) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cannot move here (overlap or out of bounds)',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          _pushUndoState();
                          setState(() {
                            _objects[idx] = obj.copyWith(
                              gameX: coords.x,
                              gameY: coords.y,
                            );
                            _highlightedIndex = idx;
                          });
                          _saveMap();
                          _setViewportAround(coords.x, coords.y);
                          _centerOnViewportCenter();
                        },
                        onEdit:
                            _objects[_menuObjectIndex!].type ==
                                ObjectType.member
                            ? () async {
                                final idx = _menuObjectIndex!;
                                final obj = _objects[idx];
                                final r = await _promptRank(initial: obj.rank);
                                if (r == null) return;
                                _pushUndoState();
                                setState(() {
                                  _objects[idx] = obj.copyWith(rank: r);
                                  _highlightedIndex = idx;
                                });
                                _saveMap();
                                // Update displayed name immediately based on new rank
                                _applyMemberRankToName(idx);
                              }
                            : null,
                        onDelete: () {
                          _pushUndoState();
                          setState(() {
                            final idx = _menuObjectIndex!;
                            _objects.removeAt(idx);
                            _menuPosition = null;
                            _menuObjectIndex = null;
                            _highlightedIndex = null;
                          });
                          _saveMap();
                        },
                      ),
                    ),
                  if (_exportHostVisible)
                    Positioned(
                      left: -10000,
                      top: -10000,
                      child: RepaintBoundary(
                        key: _exportKey,
                        child: GridRenderer(
                          gridW: _exportSize,
                          gridH: _exportSize,
                          objects: _objects,
                          originGameX: _originGameX,
                          originGameY: _originGameY,
                          highlightedIndex: null,
                          drawGrid: _exportShowGrid,
                          showCoordinates: _exportShowCoords,
                          hideRadius: _hideRadius,
                          showBuildingCoordinates:
                              false, // Don't show building coords in export
                          selectedTileGameX: null,
                          selectedTileGameY: null,
                          showCrosshair: false, // No crosshair in export
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // Add toolbar for object selection
        if (!widget.readOnly)
          HiveToolbar(
            selected: _selected,
            onSelected: (selection) {
              setState(() {
                _selected = selection;
              });
            },
          ),
        if (!widget.readOnly) const Divider(height: 1),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // File menu (hidden in read-only)
                if (!widget.readOnly)
                  PopupMenuButton<String>(
                    tooltip: 'File',
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        'File',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    onSelected: (v) async {
                      switch (v) {
                        case 'Share':
                          await _openShareDialogFromFileMenu();
                          break;
                        case 'Export as JPG':
                          await _openExportDialog();
                          break;
                        case 'Reset Setup':
                          await _resetFirstTimeSetup();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'Share', child: Text('Share…')),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'Export as JPG',
                        child: Text('Export as JPG'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'Reset Setup',
                        child: Text('Reset First-Time Setup'),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                // Insert menu (hidden in read-only)
                if (!widget.readOnly)
                  PopupMenuButton<String>(
                    tooltip: 'Insert',
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        'Insert',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'Flag':
                          _selectTool(ObjectType.flag, 'Flag');
                          break;
                        case 'BT1':
                          _selectTool(ObjectType.bearTrap, 'BT1');
                          break;
                        case 'BT2':
                          _selectTool(ObjectType.bearTrap, 'BT2');
                          break;
                        case 'BT3':
                          _selectTool(ObjectType.bearTrap, 'BT3');
                          break;
                        case 'HQ':
                          _selectTool(ObjectType.hq, 'HQ');
                          break;
                        case 'MB1':
                          _selectMemberTool('BT1');
                          break;
                        case 'MB2':
                          _selectMemberTool('BT2');
                          break;
                        case 'MB3':
                          _selectMemberTool('BT3');
                          break;
                        case 'Mountain':
                          _selectTool(ObjectType.mountain, 'Mountain');
                          break;
                        case 'Lake':
                          _selectTool(ObjectType.lake, 'Lake');
                          break;
                        case 'Alliance Node':
                          _selectTool(ObjectType.allianceNode, 'Alliance Node');
                          break;
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'Flag', child: Text('Flag')),
                      PopupMenuItem(value: 'BT1', child: Text('BT 1')),
                      PopupMenuItem(value: 'BT2', child: Text('BT 2')),
                      PopupMenuItem(value: 'BT3', child: Text('BT 3')),
                      PopupMenuItem(value: 'HQ', child: Text('HQ')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'MB1', child: Text('BT1 Member')),
                      PopupMenuItem(value: 'MB2', child: Text('BT2 Member')),
                      PopupMenuItem(value: 'MB3', child: Text('BT3 Member')),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'Mountain',
                        child: Text('Mountain (1x1)'),
                      ),
                      PopupMenuItem(value: 'Lake', child: Text('Lake (1x1)')),
                      PopupMenuItem(
                        value: 'Alliance Node',
                        child: Text('Alliance Node (2x2)'),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _openMembersListDialog,
                  child: const Text(
                    'Show Members',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (!widget.readOnly)
                  TextButton(
                    onPressed: _openResetDialog,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (widget.readOnly)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'View Only',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (!widget.readOnly)
                  OutlinedButton.icon(
                    onPressed: _undoStack.isNotEmpty ? _undo : null,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                if (!widget.readOnly) const SizedBox(width: 6),
                if (!widget.readOnly)
                  OutlinedButton.icon(
                    onPressed: _redoStack.isNotEmpty ? _redo : null,
                    icon: const Icon(Icons.redo),
                    label: const Text('Redo'),
                  ),
                const Spacer(),
                InkWell(
                  onTap: () => _editMapName(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Map: $_currentMapName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!widget.readOnly)
                  OutlinedButton.icon(
                    onPressed: _isSyncing ? null : _showSaveDialog,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSyncing ? 'Saving…' : 'Save'),
                  ),
                if (!widget.readOnly) const SizedBox(width: 6),
                if (!widget.readOnly)
                  OutlinedButton.icon(
                    onPressed: () => _openMapPicker(force: true),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open'),
                  ),
                if (!widget.readOnly) const SizedBox(width: 6),
                if (!widget.readOnly)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final id = _currentMapId;
                      if (id == null) return;
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete this map?'),
                          content: Text(
                            '"$_currentMapName" will be deleted. This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _deleteCurrentMap();
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    label: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectTool(ObjectType type, String name) {
    setState(() {
      _selected = ToolSelection(type, name);
      _menuPosition = null;
      _menuObjectIndex = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text('Tap on the grid to place $name'),
      ),
    );
  }

  // Special method for selecting member tools with rank management
  Future<void> _selectMemberTool(String group) async {
    if (_lastBTRank[group] == 0) {
      // First time placing this group, ask for starting rank
      final rank = await _promptRank(initial: 1);
      if (rank == null) return;
      _lastBTRank[group] =
          rank - 1; // Set to one less so first placement gets the entered rank
    }

    _selectTool(ObjectType.member, '$group Member');
  }

  Widget _buildBottomControls() {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            const Text('Scale:'),
            const SizedBox(width: 6),
            for (final s in const [15, 30, 50])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  selected: _viewportSize == s,
                  label: Text('${s}x$s'),
                  onSelected: (_) {
                    final cx = _originGameX + (_viewportSize ~/ 2);
                    final cy = _originGameY + (_viewportSize ~/ 2);
                    setState(() {
                      _viewportSize = s;
                    });
                    _setViewportAround(cx, cy);
                    _centerOnViewportCenter();
                    // Persist selected scale to cloud snapshot
                    _scheduleCloudSnapshotSave();
                  },
                ),
              ),
            const Spacer(),
            Text(
              'Zoom: ${(_controller.value.getMaxScaleOnAxis() * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _searchX,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'X',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _searchY,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Y',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _goToSearchCoords,
              child: const Text('GO'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () =>
                  setState(() => _showCoordinates = !_showCoordinates),
              child: Text(
                _showCoordinates ? 'Hide Coordinates' : 'Show Coordinates',
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => setState(
                () => _showBuildingCoordinates = !_showBuildingCoordinates,
              ),
              child: Text(
                _showBuildingCoordinates
                    ? 'Hide Building Coordinates'
                    : 'Show Building Coordinates',
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => setState(() => _hideRadius = !_hideRadius),
              child: Text(_hideRadius ? 'Show Radius' : 'Hide Radius'),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _selectAllObjects,
                icon: const Icon(Icons.select_all),
                label: const Text('Select All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _deleteAllObjects,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Delete All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ----- Export as JPG -----
  Future<void> _openExportDialog() async {
    bool wantCoords = false;
    bool wantGrid = true;
    int selSize = 30;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => AlertDialog(
          title: const Text('Export as JPG'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show coordinates'),
                value: wantCoords,
                onChanged: (v) => setSB(() => wantCoords = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show grid'),
                value: wantGrid,
                onChanged: (v) => setSB(() => wantGrid = v ?? true),
              ),
              const SizedBox(height: 8),
              const Text('Scale'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Radio<int>(
                    value: 30,
                    groupValue: selSize,
                    onChanged: (v) => setSB(() => selSize = v ?? 30),
                  ),
                  const Text('30x30'),
                  const SizedBox(width: 16),
                  Radio<int>(
                    value: 50,
                    groupValue: selSize,
                    onChanged: (v) => setSB(() => selSize = v ?? 50),
                  ),
                  const Text('50x50'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _exportAsJpg(
                  showCoords: wantCoords,
                  showGrid: wantGrid,
                  gridSize: selSize,
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsJpg({
    required bool showCoords,
    required bool showGrid,
    required int gridSize,
  }) async {
    // Prepare hidden renderer
    setState(() {
      _exportShowCoords = showCoords;
      _exportShowGrid = showGrid;
      _exportSize = gridSize;
      _exportHostVisible = true;
    });
    // Wait for the frame to build and paint
    await Future.delayed(const Duration(milliseconds: 50));
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary =
          _exportKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      final decoded = img.decodePng(pngBytes);
      if (decoded == null) return;
      final jpgBytes = img.encodeJpg(decoded, quality: 92);
      final b64 = base64Encode(jpgBytes);
      final fname =
          'hive_map_${gridSize}x${gridSize}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = 'data:image/jpeg;base64,$b64';
      html.AnchorElement(href: url)
        ..download = fname
        ..click();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded $fname')));
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $err')));
    } finally {
      if (mounted) {
        setState(() => _exportHostVisible = false);
      }
    }
  }

  // ----- Undo / Redo -----
  List<GridObject> _snapshotObjects() => List<GridObject>.from(_objects);

  void _pushUndoState() {
    _undoStack.add(_snapshotObjects());
    _redoStack.clear();
  }

  // ignore: unused_element
  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_snapshotObjects());
    final prev = _undoStack.removeLast();
    setState(() {
      _objects
        ..clear()
        ..addAll(prev);
      _highlightedIndex = null;
      _menuPosition = null;
      _menuObjectIndex = null;
    });
    _saveMap();
  }

  // ignore: unused_element
  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_snapshotObjects());
    final next = _redoStack.removeLast();
    setState(() {
      _objects
        ..clear()
        ..addAll(next);
      _highlightedIndex = null;
      _menuPosition = null;
      _menuObjectIndex = null;
    });
    _saveMap();
  }

  // ----- Reset actions -----
  void _openResetDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Reset Flags tiles'),
              onTap: () {
                Navigator.pop(ctx);
                _resetFlags();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Reset player tiles'),
              onTap: () {
                Navigator.pop(ctx);
                _resetPlayerTiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: const Text("Reset players' rank positions"),
              onTap: () {
                Navigator.pop(ctx);
                _resetPlayerRanks();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Reset ALL'),
              subtitle: const Text(
                'This will clear flags, player tiles, and ranks',
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c2) => AlertDialog(
                    title: const Text('Are you sure?'),
                    content: const Text(
                      'This will remove all flags and player tiles, and reset player ranks. This cannot be undone except via Undo.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c2, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(c2, true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
                Navigator.pop(ctx);
                if (confirm == true) {
                  _resetAll();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resetFlags() {
    if (_objects.where((o) => o.type == ObjectType.flag).isEmpty) return;
    _pushUndoState();
    setState(() {
      _objects.removeWhere((o) => o.type == ObjectType.flag);
    });
    _saveMap();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All flags cleared')));
    }
  }

  void _resetPlayerTiles() {
    if (_objects.where((o) => o.type == ObjectType.member).isEmpty) return;
    _pushUndoState();
    setState(() {
      _objects.removeWhere((o) => o.type == ObjectType.member);
    });
    _saveMap();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All player tiles removed')));
    }
  }

  void _resetPlayerRanks() {
    final hasRanks = _objects.any(
      (o) => o.type == ObjectType.member && o.rank != null,
    );
    if (!hasRanks) return;
    _pushUndoState();
    setState(() {
      for (int i = 0; i < _objects.length; i++) {
        final o = _objects[i];
        if (o.type == ObjectType.member) {
          _objects[i] = o.copyWith(rank: null, memberName: null);
        }
      }
    });
    _saveMap();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Players' rank positions reset")),
      );
    }
  }

  void _resetAll() {
    _pushUndoState();
    setState(() {
      // Remove flags and player tiles; clear ranks for any remaining members (if any)
      _objects.removeWhere(
        (o) => o.type == ObjectType.flag || o.type == ObjectType.member,
      );
      for (int i = 0; i < _objects.length; i++) {
        final o = _objects[i];
        if (o.type == ObjectType.member) {
          _objects[i] = o.copyWith(rank: null, memberName: null);
        }
      }
    });
    _saveMap();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All flags and player tiles cleared; ranks reset'),
        ),
      );
    }
  }

  void _centerViewOn(int cx, int cy) {
    final rb = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final viewport = rb.size;
    const halfW = GridRenderer.halfW;
    const halfH = GridRenderer.halfH;
    final originX = _viewportSize * halfW;
    // Scene coords of tile center
    final sx = originX + (cx - cy) * halfW;
    final sy = (cx + cy) * halfH + halfH; // center of diamond
    final scale = _controller.value.getMaxScaleOnAxis();
    final target = Offset(sx, sy);
    final viewCenter = Offset(viewport.width / 2, viewport.height / 2);

    final m = Matrix4.identity()..scale(scale);
    m.setTranslationRaw(
      viewCenter.dx - target.dx * scale,
      viewCenter.dy - target.dy * scale,
      0,
    );
    _controller.value = m;
  }

  void _centerOnViewportCenter() =>
      _centerViewOn(_viewportSize ~/ 2, _viewportSize ~/ 2);

  void _setViewportAround(int gameX, int gameY) {
    if (_isMapViewLocked) return; // Don't move if locked

    int startX = gameX - (_viewportSize ~/ 2);
    int startY = gameY - (_viewportSize ~/ 2);
    final maxStart = worldMax - _viewportSize + 1;
    startX = startX.clamp(0, maxStart);
    startY = startY.clamp(0, maxStart);
    setState(() {
      _originGameX = startX;
      _originGameY = startY;
    });
  }

  void _goToSearchCoords() {
    final x = int.tryParse(_searchX.text.trim());
    final y = int.tryParse(_searchY.text.trim());
    if (x == null || y == null) return;
    if (x < 0 || x > worldMax || y < 0 || y > worldMax) return;
    _setViewportAround(x, y);
    _centerOnViewportCenter();
  }

  void _selectAllObjects() {
    setState(() {
      _highlightedIndex = null; // Clear individual highlight
      // Show a message about selecting all objects
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_objects.length} objects selected'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ===== FIRST-TIME USER SETUP FLOW =====

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSetup = prefs.getBool('hivemap_has_seen_setup') ?? false;

    if (!hasSeenSetup && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeDialog();
      });
    }
  }

  void _showWelcomeDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Welcome to HiveMap Editor!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This tool helps you plan your hive layout and manage your bear trap teams.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Would you like help setting up your map or jump straight to editing?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _enterEditor();
            },
            child: const Text('Enter Editor'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startSetupFlow();
            },
            child: const Text('Help Build'),
          ),
        ],
      ),
    );
  }

  void _enterEditor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hivemap_has_seen_setup', true);
    setState(() {
      _isFirstTimeUser = false;
    });
  }

  void _startSetupFlow() {
    setState(() {
      _showSetupFlow = true;
      _setupStep = 1; // Start with BT1 setup
    });
    _showBT1Setup();
  }

  void _showBT1Setup() {
    _showBTSetupDialog('BT1', 'Bear Trap 1', () => _showBT2Setup());
  }

  void _showBT2Setup() {
    _showBTSetupDialog('BT2', 'Bear Trap 2', () => _showBT3ChoiceDialog());
  }

  void _showBT3ChoiceDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Bear Trap 3'),
        content: const Text('Do you use Bear Trap 3?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _useBT3 = false;
              });
              _showMembersSetup();
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _useBT3 = true;
              });
              _showBT3Setup();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showBT3Setup() {
    _showBTSetupDialog('BT3', 'Bear Trap 3', () => _showMembersSetup());
  }

  void _showBTSetupDialog(String btKey, String btName, VoidCallback onNext) {
    final TextEditingController xController = TextEditingController();
    final TextEditingController yController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Where is $btName?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the coordinates for $btName:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: xController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'X Coordinate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: yController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Y Coordinate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final x = int.tryParse(xController.text.trim());
              final y = int.tryParse(yController.text.trim());

              if (x == null ||
                  y == null ||
                  x < 0 ||
                  x > worldMax ||
                  y < 0 ||
                  y > worldMax) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid coordinates (0-1199)'),
                  ),
                );
                return;
              }

              Navigator.of(ctx).pop();

              // Store coordinates and place BT
              setState(() {
                _setupBTCoordinates[btKey] = {'x': x, 'y': y};
              });

              _placeBearTrap(btKey, x, y);
              onNext();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _placeBearTrap(String btKey, int x, int y) {
    _pushUndoState();
    setState(() {
      _objects.add(
        GridObject(type: ObjectType.bearTrap, name: btKey, gameX: x, gameY: y),
      );
    });
    _saveMap();

    // Center view on the placed BT
    _setViewportAround(x, y);
    _centerOnViewportCenter();
  }

  void _showMembersSetup() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Members'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Would you like to import your member list or add members manually later?',
            ),
            SizedBox(height: 16),
            Text(
              'Import option will download a template CSV file for you to fill out.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _completeSetup();
            },
            child: const Text('Add Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showImportDialog();
            },
            child: const Text('Import CSV'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Members'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1. Download the template CSV file'),
            SizedBox(height: 8),
            Text('2. Fill it out with your member information'),
            SizedBox(height: 8),
            Text('3. Upload the completed file'),
            SizedBox(height: 16),
            Text(
              'Template includes: Member Name, BT Group (BT1/BT2/BT3), Rank, Attendance %',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _completeSetup();
            },
            child: const Text('Skip'),
          ),
          OutlinedButton(
            onPressed: _downloadTemplate,
            child: const Text('Download Template'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _importMembersFromSpreadsheet();
              _completeSetup();
            },
            child: const Text('Upload CSV'),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() {
    // Create CSV template content
    const csvContent = '''Member Name,BT Group,Rank,Attendance %
John Doe,BT1,1,100
Jane Smith,BT1,2,95
Bob Johnson,BT2,1,90
Alice Brown,BT2,2,85
Charlie Wilson,BT3,1,80''';

    // Create and download the file
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'Survival Planner - Members import.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Template CSV downloaded: "Survival Planner - Members import.csv"',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hivemap_has_seen_setup', true);

    setState(() {
      _isFirstTimeUser = false;
      _showSetupFlow = false;
      _setupStep = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setup complete! Welcome to HiveMap Editor.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resetFirstTimeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hivemap_has_seen_setup', false);

    setState(() {
      _isFirstTimeUser = true;
      _showSetupFlow = false;
      _setupStep = 0;
      // Reset setup state
      _setupBTCoordinates = {
        'BT1': {'x': null, 'y': null},
        'BT2': {'x': null, 'y': null},
        'BT3': {'x': null, 'y': null},
      };
      _useBT3 = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'First-time setup has been reset. Reload the page to see the welcome dialog.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _deleteAllObjects() {
    if (_objects.isEmpty) return;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Objects'),
        content: Text(
          'Are you sure you want to delete all ${_objects.length} objects? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _pushUndoState();
        setState(() {
          _objects.clear();
          _highlightedIndex = null;
          _menuPosition = null;
          _menuObjectIndex = null;
          // Reset BT ranks
          _lastBTRank['BT1'] = 0;
          _lastBTRank['BT2'] = 0;
          _lastBTRank['BT3'] = 0;
        });
        _saveMap();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All objects deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<Point<int>?> _promptCoordinates({int? initialX, int? initialY}) async {
    final xController = TextEditingController(text: initialX?.toString() ?? '');
    final yController = TextEditingController(text: initialY?.toString() ?? '');
    return showDialog<Point<int>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter coordinates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xController,
              decoration: const InputDecoration(labelText: 'X coordinate'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: yController,
              decoration: const InputDecoration(labelText: 'Y coordinate'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final x = int.tryParse(xController.text.trim());
              final y = int.tryParse(yController.text.trim());
              if (x == null ||
                  y == null ||
                  x < 0 ||
                  y < 0 ||
                  x > worldMax ||
                  y > worldMax) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid integers 0..1199')),
                );
                return;
              }
              Navigator.pop(ctx, Point<int>(x, y));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<int?> _promptRank({int? initial}) async {
    final controller = TextEditingController(text: initial?.toString() ?? '');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Rank (1-99)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Rank'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null || v < 1 || v > 99) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a rank from 1 to 99')),
                );
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applyMemberRankToName(int index) {
    if (index < 0 || index >= _objects.length) return;
    final obj = _objects[index];
    if (obj.type != ObjectType.member) return;
    final r = obj.rank;
    final g = (obj.memberGroup ?? '').toUpperCase();
    if (r == null || r < 1) {
      setState(() {
        _objects[index] = obj.copyWith(memberName: null);
      });
      return;
    }
    // Use power-ranked order within the selected group (desc by power)
    final list = _rankedMembersByGroup(g);
    final rank = r.clamp(1, 99); // ranks limited to 1..99
    if (rank <= list.length) {
      final name = list[rank - 1].name;
      setState(() {
        _objects[index] = obj.copyWith(memberName: name);
      });
    } else {
      setState(() {
        _objects[index] = obj.copyWith(memberName: null);
      });
    }
    _saveMap();
  }

  void _refreshAllMemberNames() {
    for (int i = 0; i < _objects.length; i++) {
      if (_objects[i].type == ObjectType.member && _objects[i].rank != null) {
        _applyMemberRankToName(i);
      }
    }
  }

  // --------- Persistence & Sync ---------
  // File → Share…
  Future<void> _openShareDialogFromFileMenu() async {
    // Require sign-in for sharing
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in required'),
          content: const Text(
            'You need to sign in to create a shareable link for this map.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Ensure we have a map id and the latest objects saved locally
    await _saveMapLocal();
    final mapId = _currentMapId!;

    // Try to read an existing slug for this map
    final prefs = await SharedPreferences.getInstance();
    String? slug = prefs.getString('hivemap_shared_slug_$mapId');
    String mode = 'private';

    // Existing share: fetch current mode
    if (slug != null) {
      try {
        final row = await MapService.loadMapBySlug(slug);
        if (row != null) {
          mode = (row['share_mode'] ?? 'private').toString();
        }
      } catch (_) {}

      // At this point slug must be non-null
      if (slug.isEmpty) return;

      await _showShareDialogWithSlug(slug, mode);
    }
  }

  Future<void> _showShareDialogWithSlug(String slug, String initialMode) async {
    String mode = initialMode;
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
              Row(
                children: [
                  const SizedBox(width: 52, child: Text('View:')),
                  Expanded(
                    child: SelectableText(
                      MapService.viewLink(slug),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: MapService.viewLink(slug)),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('View link copied to clipboard'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 52, child: Text('Edit:')),
                  Expanded(
                    child: SelectableText(
                      MapService.editLink(slug),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: MapService.editLink(slug)),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit link copied to clipboard'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await MapService.setShareMode(slug, mode);
                  if (mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share settings updated')),
                    );
                  }
                } catch (err) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update sharing: $err')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMap() async {
    await _saveMapLocal();
    await _maybeSyncToCloud();
    // Save simplified single-map snapshot to calculator_data (one per user)
    _scheduleCloudSnapshotSave();
  }

  // Debounce wrapper to coalesce frequent save requests
  void _scheduleCloudSnapshotSave({
    Duration delay = const Duration(milliseconds: 700),
  }) {
    _cloudSaveDebounce?.cancel();
    _cloudSaveDebounce = Timer(delay, () {
      // Fire and forget; internal no-op guard prevents redundant writes
      // ignore: discarded_futures
      saveHiveMap();
    });
  }

  // Save per-map locally and update metadata
  Future<void> _saveMapLocal() async {
    if (_currentMapId == null) {
      _currentMapId = _genId();
    }
    final p = await SharedPreferences.getInstance();
    await p.setString('$_mapDocPrefix$_currentMapId', _serializeObjects());
    final metas = await _loadLocalMapsMeta();
    final idx = metas.indexWhere((m) => m.id == _currentMapId);
    final meta = _MapMeta(
      id: _currentMapId!,
      name: _currentMapName,
      updatedAt: DateTime.now(),
    );
    if (idx == -1) {
      metas.add(meta);
    } else {
      metas[idx] = meta;
    }
    await _saveLocalMapsMeta(metas);
    await p.setString('hivemap_last_id', _currentMapId!);
  }

  // Load map by id from local storage
  Future<bool> _loadMapLocal(String id) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('$_mapDocPrefix$id');
    if (s == null || s.isEmpty) return false;
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        final loaded = <GridObject>[];
        for (final e in decoded) {
          if (e is Map<String, dynamic>) {
            final tName = e['t'] as String?;
            final n = (e['n'] as String?) ?? '';
            final x = (e['x'] as num?)?.toInt();
            final y = (e['y'] as num?)?.toInt();
            if (tName == null || x == null || y == null) continue;
            ObjectType? t;
            for (final v in ObjectType.values) {
              if (v.name == tName) {
                t = v;
                break;
              }
            }
            if (t == null) continue;
            final r = (e['r'] as num?)?.toInt();
            final g = e['g'] as String?;
            final m = e['m'] as String?;
            loaded.add(
              GridObject(
                type: t,
                name: n,
                gameX: x,
                gameY: y,
                rank: r,
                memberGroup: g,
                memberName: m,
              ),
            );
          }
        }
        if (mounted) {
          setState(() {
            _objects
              ..clear()
              ..addAll(loaded);
          });
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Serialize current objects into a compact JSON string
  String _serializeObjects() {
    final list = _objects
        .map(
          (o) => {
            't': o.type.name,
            'n': o.name,
            'x': o.gameX,
            'y': o.gameY,
            if (o.rank != null) 'r': o.rank,
            if (o.memberGroup != null) 'g': o.memberGroup,
            if (o.memberName != null) 'm': o.memberName,
          },
        )
        .toList();
    return jsonEncode(list);
  }

  // Best-effort cloud sync of current map (if logged in)
  Future<void> _maybeSyncToCloud() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; // offline or not logged in
    if (_currentMapId == null) return;
    try {
      if (mounted) setState(() => _isSyncing = true);
      final payload = {
        'id': _currentMapId,
        'name': _currentMapName,
        'data': _serializeObjects(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await Supabase.instance.client.from('hive_maps').upsert(payload);
    } catch (_) {
      // ignore network errors
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // Fetch cloud map list for picker; safe to call if logged out (returns empty)
  Future<List<_MapMeta>> _fetchCloudMetasSafe() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    try {
      final rows = await Supabase.instance.client
          .from('hive_maps')
          .select('id,name,updated_at')
          .order('updated_at', ascending: false);
      return (rows as List)
          .map(
            (e) => _MapMeta.fromJson({
              'id': e['id'],
              'name': e['name'],
              'updated_at': e['updated_at'],
              'fromCloud': true,
            }),
          )
          .toList();
    } catch (_) {
      // ignore
    }
    return [];
  }

  // --- Simple one-map-per-user cloud save/load (calculator_data) ---
  StreamSubscription? _authSub;
  int _trapFootprintSize(GridObject o) {
    // Current BT trap footprint is 6x6
    return 6;
  }

  Future<void> saveHiveMap() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final traps = _objects
        .where((o) => o.type == ObjectType.bearTrap)
        .map(
          (t) => {
            'name': t.name,
            'x': t.gameX,
            'y': t.gameY,
            'size': _trapFootprintSize(t),
          },
        )
        .toList();

    // Build a stable signature to avoid no-op saves
    final sig = _buildCloudSnapshotSignature(traps, _viewportSize);
    if (_lastSavedSignature == sig) {
      // Skip redundant write
      return;
    }

    try {
      final resp = await Supabase.instance.client
          .from('calculator_data')
          .upsert({
            'user_id': user.id,
            'page': 'hive_map_editor',
            'data': {'traps': traps, 'scale': _viewportSize},
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,page')
          .select();
      final rows = resp as List?;
      debugPrint(
        'hivemap: saved ${traps.length} traps for ${user.id}. Return: ${rows?.length ?? 'n/a'} row(s)',
      );
      _lastSavedSignature = sig;
    } catch (err) {
      // best-effort; log real error
      debugPrint('hivemap: saveHiveMap failed: $err');
    }
  }

  String _buildCloudSnapshotSignature(
    List<Map<String, dynamic>> traps,
    int scale,
  ) {
    final parts =
        traps
            .map((t) => '${t['name']}:${t['x']}:${t['y']}:${t['size']}')
            .toList()
          ..sort();
    return '$scale|${parts.join(';')}';
  }

  Future<void> loadHiveMap() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('calculator_data')
          .select('data')
          .eq('user_id', user.id)
          .eq('page', 'hive_map_editor')
          .maybeSingle();

      if (res != null) {
        final data = res['data'] as Map<dynamic, dynamic>;
        final trapsData = (data['traps'] as List?) ?? const [];
        final scale = data['scale'];

        // If nothing saved yet in cloud, don't touch local objects
        if (trapsData.isEmpty) {
          if (scale is int && (scale == 15 || scale == 30 || scale == 50)) {
            setState(() => _viewportSize = scale);
            final center = (worldMax + 1) ~/ 2;
            _setViewportAround(center, center);
            _centerOnViewportCenter();
          }
          debugPrint(
            'hivemap: loadHiveMap found 0 traps – keeping local state',
          );
          return;
        }

        final loaded = <GridObject>[];
        for (final t in trapsData) {
          final m = t as Map<dynamic, dynamic>;
          final name = (m['name'] ?? 'BT').toString();
          final x = (m['x'] as num?)?.toInt();
          final y = (m['y'] as num?)?.toInt();
          if (x == null || y == null) continue;
          loaded.add(
            GridObject(
              type: ObjectType.bearTrap,
              name: name,
              gameX: x,
              gameY: y,
            ),
          );
        }
        if (mounted) {
          setState(() {
            if (scale is int && (scale == 15 || scale == 30 || scale == 50)) {
              _viewportSize = scale;
            }
            // Replace only bear traps from cloud; keep flags/members intact
            _objects.removeWhere((o) => o.type == ObjectType.bearTrap);
            _objects.addAll(loaded);
          });
          // recentre view after changing scale/objects
          final center = (worldMax + 1) ~/ 2;
          _setViewportAround(center, center);
          _centerOnViewportCenter();
          debugPrint(
            'hivemap: loaded ${loaded.length} traps from calculator_data',
          );
        }
      }
    } catch (err) {
      // ignore failures
      debugPrint('hivemap: loadHiveMap failed: $err');
    }
  }

  // Load a map from Supabase and cache locally
  Future<void> _loadMapCloud(String id) async {
    try {
      final row = await Supabase.instance.client
          .from('hive_maps')
          .select('data,name,updated_at')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return;
      final dataStr = (row['data'] ?? '').toString();
      if (dataStr.isEmpty) return;
      final decoded = jsonDecode(dataStr);
      if (decoded is! List) return;
      final loaded = <GridObject>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final tName = e['t'] as String?;
          final n = (e['n'] as String?) ?? '';
          final x = (e['x'] as num?)?.toInt();
          final y = (e['y'] as num?)?.toInt();
          if (tName == null || x == null || y == null) continue;
          ObjectType? t;
          for (final v in ObjectType.values) {
            if (v.name == tName) {
              t = v;
              break;
            }
          }
          if (t == null) continue;
          final r = (e['r'] as num?)?.toInt();
          final g = e['g'] as String?;
          final m = e['m'] as String?;
          loaded.add(
            GridObject(
              type: t,
              name: n,
              gameX: x,
              gameY: y,
              rank: r,
              memberGroup: g,
              memberName: m,
            ),
          );
        }
      }
      // cache locally
      final p = await SharedPreferences.getInstance();
      await p.setString('$_mapDocPrefix$id', dataStr);
      final name = (row['name'] ?? 'Untitled').toString();
      final whenStr = (row['updated_at'] ?? '').toString();
      final when = DateTime.tryParse(whenStr) ?? DateTime.now();
      final metas = await _loadLocalMapsMeta();
      final meta = _MapMeta(id: id, name: name, updatedAt: when);
      final existingIndex = metas.indexWhere((mm) => mm.id == id);
      if (existingIndex == -1) {
        metas.add(meta);
      } else {
        metas[existingIndex] = meta;
      }
      await _saveLocalMapsMeta(metas);
      if (mounted) {
        setState(() {
          _objects
            ..clear()
            ..addAll(loaded);
        });
      }
    } catch (_) {
      // ignore cloud load errors
    }
  }

  // Initial load: migrate legacy, open last map if available, else picker/new
  Future<void> _loadMap() async {
    await _ensureMigratedFromLegacy();
    final p = await SharedPreferences.getInstance();
    final lastId = p.getString('hivemap_last_id');
    if (lastId != null) {
      final ok = await _loadMapLocal(lastId);
      if (ok) {
        final metas = await _loadLocalMapsMeta();
        final meta = metas.firstWhere(
          (m) => m.id == lastId,
          orElse: () => _MapMeta(
            id: lastId,
            name: _currentMapName,
            updatedAt: DateTime.now(),
          ),
        );
        setState(() {
          _currentMapId = lastId;
          _currentMapName = meta.name;
        });
        return;
      }
    }
    final localMetas = await _loadLocalMapsMeta();
    final cloudMetas = await _fetchCloudMetasSafe();
    if (localMetas.isNotEmpty || cloudMetas.isNotEmpty) {
      await _openMapPicker(force: true);
    } else {
      await _createNewMap();
    }
  }

  Future<void> _saveMembers() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_membersStorageKey, encodeMembers(_members));
  }

  Future<void> _loadMembers() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_membersStorageKey);
    if (s == null || s.isEmpty) return;
    try {
      final loaded = decodeMembers(s);
      if (mounted) {
        setState(() {
          _members
            ..clear()
            ..addAll(loaded);
        });
      }
    } catch (_) {
      // ignore
    }
  }

  // Returns a new list of members in the given group, sorted by power desc,
  // then by name asc to stabilize ties. Group match is case-insensitive.
  List<MemberRecord> _rankedMembersByGroup(String g) {
    final upper = g.toUpperCase();
    final list = _members
        .where((m) => m.group.toUpperCase() == upper)
        .toList(growable: false);
    final sorted = List<MemberRecord>.from(list);
    sorted.sort((a, b) {
      // Use effective power if attendance is enabled, otherwise use regular power
      final powerA = _attendanceEnabled ? a.effectivePower : a.power;
      final powerB = _attendanceEnabled ? b.effectivePower : b.power;
      final pc = powerB.compareTo(powerA); // desc
      if (pc != 0) return pc;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  // Delete current map locally and in cloud (if logged in), then prompt for next
  Future<void> _deleteCurrentMap() async {
    final id = _currentMapId;
    if (id == null) return;
    final p = await SharedPreferences.getInstance();
    // remove local doc
    await p.remove('$_mapDocPrefix$id');
    // update metas
    final metas = await _loadLocalMapsMeta();
    metas.removeWhere((m) => m.id == id);
    await _saveLocalMapsMeta(metas);
    final last = p.getString('hivemap_last_id');
    if (last == id) {
      await p.remove('hivemap_last_id');
    }
    await _deleteCloudSafe(id);
    if (mounted) {
      setState(() {
        _objects.clear();
        _currentMapId = null;
        _currentMapName = 'Untitled Map';
      });
    }
    if (metas.isNotEmpty) {
      await _openMapPicker(force: true);
    } else {
      await _createNewMap();
    }
  }

  Future<void> _deleteCloudSafe(String id) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('hive_maps').delete().eq('id', id);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _importMembersFromSpreadsheet() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions: const ['xlsx', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    List<MemberRecord> parsed = [];
    try {
      if ((file.extension ?? '').toLowerCase() == 'xlsx') {
        final book = ex.Excel.decodeBytes(bytes);
        if (book.tables.isNotEmpty) {
          final sheet = book.tables.values.first;
          for (int r = 1; r < sheet.maxRows && r < 400; r++) {
            final row = sheet.row(r);
            String cellVal(int c) =>
                (c < row.length ? (row[c]?.value?.toString() ?? '') : '');
            final name = cellVal(0).trim();
            if (name.isEmpty) continue;
            final group = cellVal(1).trim().toUpperCase();
            final powerStr = cellVal(2).trim();
            final g = (group == 'BT1' || group == 'BT2' || group == 'BT3')
                ? group
                : 'BT1';
            final p = int.tryParse(powerStr.replaceAll(',', '')) ?? 0;
            parsed.add(MemberRecord(name: name, group: g, power: p));
          }
        }
      } else {
        final text = String.fromCharCodes(bytes);
        final lines = text.split(RegExp(r'\r?\n'));
        for (int i = 1; i < lines.length && i < 400; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = line.split(',');
          final name = cols.isNotEmpty ? cols[0].trim() : '';
          if (name.isEmpty) continue;
          final group = cols.length > 1 ? cols[1].trim().toUpperCase() : '';
          final powerStr = cols.length > 2 ? cols[2].trim() : '0';
          final g = (group == 'BT1' || group == 'BT2' || group == 'BT3')
              ? group
              : 'BT1';
          final p = int.tryParse(powerStr.replaceAll(',', '')) ?? 0;
          parsed.add(MemberRecord(name: name, group: g, power: p));
        }
      }
      setState(() {
        _members
          ..clear()
          ..addAll(parsed);
      });
      await _saveMembers();
      _refreshAllMemberNames();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${parsed.length} members')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import members')),
        );
      }
    }
  }

  Future<MemberRecord?> _promptMemberEditor({MemberRecord? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String group = existing?.group.toUpperCase() == 'BT2'
        ? 'BT2'
        : existing?.group.toUpperCase() == 'BT3'
        ? 'BT3'
        : 'BT1';
    final powerCtrl = TextEditingController(
      text: existing?.power.toString() ?? '0',
    );
    return showDialog<MemberRecord>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Member' : 'Edit Member'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Group:'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: group,
                    items: const [
                      DropdownMenuItem(value: 'BT1', child: Text('BT1')),
                      DropdownMenuItem(value: 'BT2', child: Text('BT2')),
                      DropdownMenuItem(value: 'BT3', child: Text('BT3')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        group = v;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: powerCtrl,
                decoration: const InputDecoration(labelText: 'Power'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              final p =
                  int.tryParse(powerCtrl.text.trim().replaceAll(',', '')) ?? 0;
              Navigator.pop(
                ctx,
                MemberRecord(name: name, group: group, power: p),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ObjectMenu extends StatelessWidget {
  final GridObject object;
  final VoidCallback onDragMove;
  final VoidCallback onCoordinateMove;
  final VoidCallback onDelete;
  final VoidCallback? onEdit; // optional edit (rank) for members

  const _ObjectMenu({
    required this.object,
    required this.onDragMove,
    required this.onCoordinateMove,
    required this.onDelete,
    this.onEdit,
  });

  String get _typeLabel =>
      (object.type == ObjectType.member && (object.memberName ?? '').isNotEmpty)
      ? '${object.memberName} (${object.memberGroup ?? ''}${object.rank != null ? ' #${object.rank}' : ''})'
      : object.name;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_typeLabel  (${object.gameX},${object.gameY})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: onDragMove,
                  icon: const Icon(Icons.pan_tool),
                  label: const Text('Move'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onCoordinateMove,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Coord'),
                ),
                const SizedBox(width: 4),
                if (onEdit != null) ...[
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
