import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';

class HiveMapToolbar extends StatefulWidget {
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;
  final int cellSize;
  final ValueChanged<int> onCellSizeChanged;
  final BuildingType? selectedBuildingType;
  final ValueChanged<BuildingType?> onBuildingTypeChanged;
  final bool isSelectMode;
  final VoidCallback onToggleSelectMode;
  final Function(int x, int y) onGoToCoordinate;
  final String? hoverCoordinates;

  const HiveMapToolbar({
    super.key,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    required this.cellSize,
    required this.onCellSizeChanged,
    this.selectedBuildingType,
    required this.onBuildingTypeChanged,
    required this.isSelectMode,
    required this.onToggleSelectMode,
    required this.onGoToCoordinate,
    this.hoverCoordinates,
  });

  @override
  State<HiveMapToolbar> createState() => _HiveMapToolbarState();
}

class _HiveMapToolbarState extends State<HiveMapToolbar> {
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Text(
              'HiveMap Editor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 32),

            // Coordinate Search
            const Text('Go to: '),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              height: 36,
              child: TextField(
                controller: _xController,
                decoration: const InputDecoration(
                  hintText: 'X',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 60,
              height: 36,
              child: TextField(
                controller: _yController,
                decoration: const InputDecoration(
                  hintText: 'Y',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () {
                final x = int.tryParse(_xController.text);
                final y = int.tryParse(_yController.text);
                if (x != null && y != null) {
                  widget.onGoToCoordinate(x.clamp(0, 1199), y.clamp(0, 1199));
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(40, 36),
              ),
              child: const Icon(Icons.navigation, size: 18),
            ),

            const SizedBox(width: 16),
            const VerticalDivider(),
            const SizedBox(width: 16),

            // Select Mode
            ElevatedButton.icon(
              onPressed: widget.onToggleSelectMode,
              icon: Icon(
                widget.isSelectMode
                    ? Icons.touch_app
                    : Icons.touch_app_outlined,
                size: 18,
              ),
              label: Text(widget.isSelectMode ? 'Select ON' : 'Select OFF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isSelectMode
                    ? Colors.blue
                    : Colors.grey[200],
                foregroundColor: widget.isSelectMode
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(100, 36),
              ),
            ),
            if (widget.hoverCoordinates != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  widget.hoverCoordinates!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(width: 16),
            const VerticalDivider(),
            const SizedBox(width: 16),

            // Viewport Size Selection
            const Text('View Size: '),
            const SizedBox(width: 8),
            _buildCellSizeButton(15),
            const SizedBox(width: 4),
            _buildCellSizeButton(30),
            const SizedBox(width: 4),
            _buildCellSizeButton(50),

            const SizedBox(width: 32),
            const VerticalDivider(),
            const SizedBox(width: 16),

            // Building Selection
            const Text('Place: '),
            const SizedBox(width: 8),
            _buildBuildingButton('BT1', BuildingType.btMember1, Colors.orange),
            const SizedBox(width: 4),
            _buildBuildingButton('BT2', BuildingType.btMember2, Colors.orange),
            const SizedBox(width: 4),
            _buildBuildingButton('BT3', BuildingType.btMember3, Colors.orange),
            const SizedBox(width: 4),
            _buildBuildingButton('Trap1', BuildingType.bearTrap1, Colors.brown),
            const SizedBox(width: 4),
            _buildBuildingButton('Trap2', BuildingType.bearTrap2, Colors.brown),
            const SizedBox(width: 4),
            _buildBuildingButton('Trap3', BuildingType.bearTrap3, Colors.brown),
            const SizedBox(width: 4),
            _buildBuildingButton('Flag', BuildingType.flag, Colors.yellow),
            const SizedBox(width: 4),
            _buildBuildingButton('HQ', BuildingType.hq, Colors.deepPurple),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => widget.onBuildingTypeChanged(null),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.selectedBuildingType == null
                    ? Colors.red
                    : Colors.grey[200],
                foregroundColor: widget.selectedBuildingType == null
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(50, 36),
              ),
              child: const Icon(Icons.clear, size: 18),
            ),

            const SizedBox(width: 32),
            const VerticalDivider(),
            const SizedBox(width: 16),

            // Zoom Controls
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: widget.onZoomOut,
              tooltip: 'Zoom Out',
            ),
            Text(
              '${((widget.scale / 10.0) * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 14),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: widget.onZoomIn,
              tooltip: 'Zoom In',
            ),

            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: widget.onResetView,
              tooltip: 'Reset View',
            ),

            const SizedBox(width: 32),

            // Info text
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Map: 1200x1200 | Viewing: ${widget.cellSize}x${widget.cellSize}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCellSizeButton(int size) {
    final isSelected = widget.cellSize == size;
    return ElevatedButton(
      onPressed: () => widget.onCellSizeChanged(size),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(60, 36),
      ),
      child: Text('${size}x$size'),
    );
  }

  Widget _buildBuildingButton(String label, BuildingType type, Color color) {
    final isSelected = widget.selectedBuildingType == type;
    return ElevatedButton(
      onPressed: () => widget.onBuildingTypeChanged(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(50, 36),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
