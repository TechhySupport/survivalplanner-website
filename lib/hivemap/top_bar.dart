import 'package:flutter/material.dart';

class HiveMapTopBar extends StatelessWidget {
  final String mapName;
  final VoidCallback onEditMapName;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool showMembers;
  final VoidCallback onToggleShowMembers;
  final bool canUndo;
  final bool canRedo;
  final int viewportSize;
  final ValueChanged<int> onViewportSizeChanged;

  const HiveMapTopBar({
    super.key,
    required this.mapName,
    required this.onEditMapName,
    required this.onUndo,
    required this.onRedo,
    required this.onReset,
    required this.onSave,
    required this.onOpen,
    required this.onDelete,
    required this.showMembers,
    required this.onToggleShowMembers,
    required this.canUndo,
    required this.canRedo,
    required this.viewportSize,
    required this.onViewportSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // File menu
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'File',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'undo',
                enabled: canUndo,
                child: Row(
                  children: [
                    Icon(Icons.undo, size: 18, color: canUndo ? Colors.black87 : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Undo', style: TextStyle(color: canUndo ? Colors.black87 : Colors.grey)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'redo',
                enabled: canRedo,
                child: Row(
                  children: [
                    Icon(Icons.redo, size: 18, color: canRedo ? Colors.black87 : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Redo', style: TextStyle(color: canRedo ? Colors.black87 : Colors.grey)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'undo') onUndo();
              if (value == 'redo') onRedo();
            },
          ),
          
          const SizedBox(width: 8),
          
          // Show Members button
          TextButton(
            onPressed: onToggleShowMembers,
            style: TextButton.styleFrom(
              backgroundColor: showMembers ? Colors.blue.shade50 : Colors.transparent,
              foregroundColor: showMembers ? Colors.blue.shade700 : Colors.black87,
            ),
            child: const Text('Show Members'),
          ),
          
          const SizedBox(width: 8),
          
          // Undo button - right under File
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? onUndo : null,
            tooltip: 'Undo',
            iconSize: 20,
          ),
          
          // Redo button - right under File
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: canRedo ? onRedo : null,
            tooltip: 'Redo',
            iconSize: 20,
          ),
          
          const SizedBox(width: 16),
          
          // Reset button
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Reset'),
          ),
          
          const Spacer(),
          
          // View Size buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('View: ', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              _buildViewSizeButton(15, viewportSize, onViewportSizeChanged),
              const SizedBox(width: 4),
              _buildViewSizeButton(30, viewportSize, onViewportSizeChanged),
              const SizedBox(width: 4),
              _buildViewSizeButton(50, viewportSize, onViewportSizeChanged),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Map name
          InkWell(
            onTap: onEditMapName,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mapName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Save button
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Open button
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Delete button
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildViewSizeButton(int size, int currentSize, ValueChanged<int> onChanged) {
    final isSelected = currentSize == size;
    return ElevatedButton(
      onPressed: () => onChanged(size),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(60, 32),
      ),
      child: Text('${size}x$size', style: const TextStyle(fontSize: 12)),
    );
  }
}
