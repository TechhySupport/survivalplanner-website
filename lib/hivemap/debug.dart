import 'package:flutter/material.dart';
import 'models.dart';

class DebugPanel extends StatelessWidget {
  final List<MapObject> objects;
  final List<String> debugLogs;
  final VoidCallback onClearLogs;
  final ValueChanged<MapObject>? onDeleteObject;

  const DebugPanel({
    super.key,
    required this.objects,
    required this.debugLogs,
    required this.onClearLogs,
    this.onDeleteObject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Debug Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  onPressed: onClearLogs,
                  tooltip: 'Clear Logs',
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Objects Section
          Expanded(
            child: ListView(
              children: [
                _buildSection('Placed Objects (${objects.length})', [
                  if (objects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No objects placed',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  else
                    ...objects.map((obj) => _buildObjectTile(obj)),
                ]),
                const Divider(height: 1),
                _buildSection('Activity Log', [
                  if (debugLogs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No activity yet',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  else
                    ...debugLogs.reversed
                        .take(50)
                        .map((log) => _buildLogTile(log)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey[300],
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildObjectTile(MapObject obj) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: obj.color, shape: BoxShape.circle),
          child: Icon(obj.icon, size: 18, color: Colors.white),
        ),
        title: Text(
          obj.displayName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Position: (${obj.x}, ${obj.y})',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: onDeleteObject != null
            ? IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                onPressed: () => onDeleteObject!(obj),
                tooltip: 'Delete',
              )
            : null,
      ),
    );
  }

  Widget _buildLogTile(String log) {
    Color? bgColor;
    if (log.contains('PLACED')) {
      bgColor = Colors.green[50];
    } else if (log.contains('DELETED')) {
      bgColor = Colors.red[50];
    } else if (log.contains('MOVED')) {
      bgColor = Colors.blue[50];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        log,
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}
