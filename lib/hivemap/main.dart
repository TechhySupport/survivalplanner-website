import 'dart:math';
import 'package:flutter/material.dart';
import 'grid.dart';
import 'toolbar.dart';
import 'top_bar.dart';
import 'models.dart';
import 'member_manager.dart';

void main() {
  runApp(const HiveMapApp());
}

class HiveMapApp extends StatelessWidget {
  const HiveMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiveMap Grid',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HiveMapHome(),
    );
  }
}

// Export class name expected by the main app
class HiveMapEditorApp extends StatelessWidget {
  const HiveMapEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const HiveMapHome();
  }
}

class HiveMapHome extends StatefulWidget {
  const HiveMapHome({super.key});

  @override
  State<HiveMapHome> createState() => _HiveMapHomeState();
}

class _HiveMapHomeState extends State<HiveMapHome> {
  int _viewportSize = 30; // How many cells to show (15, 30, or 50)
  double _scale = 10.0; // Additional zoom level - 10.0 is now default 100%
  Offset _panOffset = Offset.zero; // Pan offset - default centered at (600,600)
  BuildingType? _selectedBuildingType; // Currently selected building type
  List<MapObject> _objects = []; // Objects placed on the map
  bool _isSelectMode = false; // Select/hover mode
  String? _hoverCoordinates; // Current hover coordinates
  List<String> _debugLogs = []; // Debug activity log
  int _centerX = 600; // Current center X coordinate
  int _centerY = 600; // Current center Y coordinate
  DateTime? _lastPlacementTime; // For calculating ping between placements
  
  // Map management
  String _mapName = 'New Map';
  final List<List<MapObject>> _undoStack = [];
  final List<List<MapObject>> _redoStack = [];
  bool _showMembers = false;
  
  // Member management - persistent storage
  final Map<BuildingType, List<Member>> _members = {
    BuildingType.btMember1: [],
    BuildingType.btMember2: [],
    BuildingType.btMember3: [],
  };

  @override
  void initState() {
    super.initState();
    // Add permanent buildings
    _initializePermanentBuildings();
    // Center the map at (600, 600) by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToCoordinate(600, 600);
      _addDebugLog('INIT: Map centered at (600, 600)');
    });
  }



  void _initializePermanentBuildings() {
    _objects = [
      MapObject(
        id: 'perm_sunfire',
        type: BuildingType.sunfireCastle,
        x: 597,
        y: 597,
      ),
      MapObject(
        id: 'perm_westplain',
        type: BuildingType.westplainTurret,
        x: 594,
        y: 604,
      ),
      MapObject(
        id: 'perm_eastcourt',
        type: BuildingType.eastcourtTurret,
        x: 604,
        y: 594,
      ),
      MapObject(
        id: 'perm_southwing',
        type: BuildingType.southwingTurret,
        x: 594,
        y: 594,
      ),
      MapObject(
        id: 'perm_northground',
        type: BuildingType.northgroundTurret,
        x: 604,
        y: 604,
      ),
      MapObject(
        id: 'perm_stronghold1',
        type: BuildingType.stronghold1,
        x: 600,
        y: 803,
      ),
      MapObject(
        id: 'perm_stronghold2',
        type: BuildingType.stronghold2,
        x: 403,
        y: 600,
      ),
      MapObject(
        id: 'perm_stronghold3',
        type: BuildingType.stronghold3,
        x: 600,
        y: 403,
      ),
      MapObject(
        id: 'perm_stronghold4',
        type: BuildingType.stronghold4,
        x: 803,
        y: 600,
      ),
      MapObject(
        id: 'perm_fortress1',
        type: BuildingType.fortress1,
        x: 240,
        y: 831,
      ),
      MapObject(
        id: 'perm_fortress2',
        type: BuildingType.fortress2,
        x: 240,
        y: 609,
      ),
      MapObject(
        id: 'perm_fortress3',
        type: BuildingType.fortress3,
        x: 240,
        y: 351,
      ),
      MapObject(
        id: 'perm_fortress4',
        type: BuildingType.fortress4,
        x: 369,
        y: 240,
      ),
      MapObject(
        id: 'perm_fortress5',
        type: BuildingType.fortress5,
        x: 591,
        y: 240,
      ),
      MapObject(
        id: 'perm_fortress6',
        type: BuildingType.fortress6,
        x: 591,
        y: 351,
      ),
      MapObject(
        id: 'perm_fortress7',
        type: BuildingType.fortress7,
        x: 591,
        y: 561,
      ),
      MapObject(
        id: 'perm_fortress8',
        type: BuildingType.fortress8,
        x: 591,
        y: 670,
      ),
      MapObject(
        id: 'perm_fortress9',
        type: BuildingType.fortress9,
        x: 441,
        y: 831,
      ),
      MapObject(
        id: 'perm_fortress10',
        type: BuildingType.fortress10,
        x: 351,
        y: 831,
      ),
      MapObject(
        id: 'perm_fortress11',
        type: BuildingType.fortress11,
        x: 240,
        y: 670,
      ),
      MapObject(
        id: 'perm_fortress12',
        type: BuildingType.fortress12,
        x: 141,
        y: 670,
      ),
    ];
  }

  void _addDebugLog(String message) {
    final now = DateTime.now();
    final timestamp = now.toString().substring(11, 23); // Include milliseconds
    print('[$timestamp] $message');
    _debugLogs.add('[$timestamp] $message');
    // Don't call setState here - debug logs shouldn't trigger UI rebuilds
  }

  void _zoomIn() {
    setState(() {
      _scale = (_scale * 1.2).clamp(10.0, 20.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale / 1.2).clamp(10.0, 20.0);
    });
  }

  void _resetView() {
    setState(() {
      _scale = 10.0; // Reset to default 100%
      _panOffset = Offset.zero;
    });
  }

  void _updateViewportSize(int newSize) {
    setState(() {
      _viewportSize = newSize;
    });
  }

  void _updatePanOffset(Offset newOffset) {
    setState(() {
      _panOffset = newOffset;
    });
  }

  void _updateScale(double newScale) {
    setState(() {
      _scale = newScale.clamp(10.0, 20.0);
    });
  }

  void _updateSelectedBuildingType(BuildingType? type) {
    setState(() {
      _selectedBuildingType = type;
      _isSelectMode = false; // Turn off select mode when selecting a building
    });
    if (type != null) {
      _addDebugLog('SELECTED: ${_getDisplayName(type)} for placement');
    } else {
      _addDebugLog('DESELECTED: Cleared building selection');
    }
  }

  void _onObjectPlaced(MapObject obj) {
    final clickTime = DateTime.now();

    // Calculate time since last placement
    String pingInfo = '';
    if (_lastPlacementTime != null) {
      final timeSinceLastMs = clickTime
          .difference(_lastPlacementTime!)
          .inMilliseconds;
      pingInfo = ' | ${timeSinceLastMs}ms since last click';
    }
    _lastPlacementTime = clickTime;

    // Check placement restrictions
    // Only 1 Bear Trap (any type) can be placed
    if (obj.type == BuildingType.bearTrap1 ||
        obj.type == BuildingType.bearTrap2 ||
        obj.type == BuildingType.bearTrap3) {
      final existingBearTraps = _objects.where((o) =>
          o.type == BuildingType.bearTrap1 ||
          o.type == BuildingType.bearTrap2 ||
          o.type == BuildingType.bearTrap3).length;
      if (existingBearTraps >= 1) {
        _addDebugLog(
          'BLOCKED: Only 1 Bear Trap can be placed at a time',
        );
        return;
      }
    }

    // Only 2 HQs can be placed
    if (obj.type == BuildingType.hq) {
      final existingHQs = _objects.where((o) => o.type == BuildingType.hq).length;
      if (existingHQs >= 2) {
        _addDebugLog(
          'BLOCKED: Only 2 HQs can be placed',
        );
        return;
      }
    }

    // Check if placement is blocked by any exclusion zone
    // Need to check all tiles that the new building will occupy
    for (final existingObj in _objects) {
      // Check all corners and center of the new building
      bool blocked = false;
      for (int dx = 0; dx <= obj.tileWidth; dx++) {
        for (int dy = 0; dy <= obj.tileHeight; dy++) {
          if (existingObj.isInExclusionZone(obj.x + dx, obj.y + dy)) {
            blocked = true;
            break;
          }
        }
        if (blocked) break;
      }

      if (blocked) {
        _addDebugLog(
          'BLOCKED: Cannot place ${obj.displayName} at (${obj.x}, ${obj.y}) - inside ${existingObj.displayName} exclusion zone',
        );
        return; // Reject placement
      }
    }

    // Save to undo stack before placing
    _saveToUndoStack();
    
    // Add object - setState will trigger rebuild but with optimizations
    _objects.add(obj);
    setState(() {});

    // Measure actual render time by waiting for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderCompleteTime = DateTime.now();
      final totalMs = renderCompleteTime.difference(clickTime).inMilliseconds;

      _addDebugLog(
        'PLACED: ${obj.displayName} at (${obj.x}, ${obj.y}) | Total render time: ${totalMs}ms$pingInfo',
      );
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (_isSelectMode) {
        _selectedBuildingType = null; // Clear building selection
      }
    });
    _addDebugLog('SELECT MODE: ${_isSelectMode ? "ON" : "OFF"}');
  }

  void _updateHoverCoordinates(String coords) {
    setState(() {
      _hoverCoordinates = coords.isEmpty ? null : coords;
    });
  }

  void _goToCoordinate(int x, int y) {
    final targetX = x.clamp(0, 1199);
    final targetY = y.clamp(0, 1199);

    setState(() {
      // Update the center coordinates to change which tiles are visible
      _centerX = targetX;
      _centerY = targetY;
      // Reset pan offset - the grid will now draw tiles around the new center
      _panOffset = Offset.zero;
    });
    _addDebugLog('NAVIGATE: Jumped to coordinate ($targetX, $targetY)');
  }

  void _onDeleteObject(MapObject obj) {
    final startTime = DateTime.now();

    _saveToUndoStack();
    
    setState(() {
      _objects.removeWhere((o) => o.id == obj.id);
    });

    final endTime = DateTime.now();
    final durationMs = endTime.difference(startTime).inMilliseconds;

    _addDebugLog(
      'DELETED: ${obj.displayName} from (${obj.x}, ${obj.y}) | Render: ${durationMs}ms',
    );
  }

  void _clearDebugLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  String _getDisplayName(BuildingType type) {
    return MapObject(id: '', type: type, x: 0, y: 0).displayName;
  }

  void _saveToUndoStack() {
    _undoStack.add(List<MapObject>.from(_objects));
    _redoStack.clear(); // Clear redo stack on new action
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0); // Limit undo stack size
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List<MapObject>.from(_objects));
    setState(() {
      _objects = _undoStack.removeLast();
    });
    _addDebugLog('UNDO: Reverted to previous state');
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List<MapObject>.from(_objects));
    setState(() {
      _objects = _redoStack.removeLast();
    });
    _addDebugLog('REDO: Restored next state');
  }

  void _resetMap() {
    _saveToUndoStack();
    setState(() {
      _initializePermanentBuildings();
      _mapName = 'New Map';
    });
    _addDebugLog('RESET: Map cleared');
  }

  void _toggleShowMembers() {
    showDialog(
      context: context,
      builder: (context) => MemberManagerDialog(members: _members),
    );
    _addDebugLog('SHOW MEMBERS: Dialog opened');
  }

  void _saveMap() {
    _addDebugLog('SAVE: Map saved (not yet implemented)');
    // TODO: Implement save functionality
  }

  void _openMap() {
    _addDebugLog('OPEN: Opening map (not yet implemented)');
    // TODO: Implement open functionality
  }

  void _deleteMap() {
    _addDebugLog('DELETE: Deleting map (not yet implemented)');
    // TODO: Implement delete functionality
  }

  void _editMapName() {
    final controller = TextEditingController(text: _mapName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Map Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter map name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mapName = controller.text.isEmpty ? 'New Map' : controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HiveMapTopBar(
            mapName: _mapName,
            onEditMapName: _editMapName,
            onUndo: _undo,
            onRedo: _redo,
            onReset: _resetMap,
            onSave: _saveMap,
            onOpen: _openMap,
            onDelete: _deleteMap,
            showMembers: _showMembers,
            onToggleShowMembers: _toggleShowMembers,
            canUndo: _undoStack.isNotEmpty,
            canRedo: _redoStack.isNotEmpty,
            viewportSize: _viewportSize,
            onViewportSizeChanged: _updateViewportSize,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: IsometricGridWidget(
                viewportSize: _viewportSize,
                scale: _scale,
                panOffset: _panOffset,
                onPanUpdate: _updatePanOffset,
                onScaleChanged: _updateScale,
                objects: _objects,
                selectedBuildingType: _selectedBuildingType,
                onObjectPlaced: _onObjectPlaced,
                isSelectMode: _isSelectMode,
                onHoverCoordinates: _updateHoverCoordinates,
                centerX: _centerX,
                centerY: _centerY,
              ),
            ),
          ),
          HiveMapToolbar(
            scale: _scale,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onResetView: _resetView,
            cellSize: _viewportSize,
            onCellSizeChanged: _updateViewportSize,
            selectedBuildingType: _selectedBuildingType,
            onBuildingTypeChanged: _updateSelectedBuildingType,
            isSelectMode: _isSelectMode,
            onToggleSelectMode: _toggleSelectMode,
            onGoToCoordinate: _goToCoordinate,
            hoverCoordinates: _hoverCoordinates,
          ),
        ],
      ),
    );
  }
}
