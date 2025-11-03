import 'package:flutter/material.dart';
import 'models.dart';

class ToolSelection {
  final ObjectType type;
  final String name; // e.g. "Flag", "BT1", "BT2", "BT3", "HQ"
  const ToolSelection(this.type, this.name);
}

class HiveToolbar extends StatelessWidget {
  final ToolSelection selected;
  final ValueChanged<ToolSelection> onSelected;

  const HiveToolbar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (ObjectType.flag, Icons.flag, 'Flag'),
      (ObjectType.bearTrap, Icons.shield, 'BT1'),
      (ObjectType.bearTrap, Icons.shield_outlined, 'BT2'),
      (ObjectType.bearTrap, Icons.security, 'BT3'),
      (ObjectType.hq, Icons.home, 'HQ'),
      (ObjectType.member, Icons.person, 'BT1 Member'),
      (ObjectType.member, Icons.person_outline, 'BT2 Member'),
      (ObjectType.member, Icons.group, 'BT3 Member'),
    ];

    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Wrap(
          spacing: 8,
          children: [
            for (final (type, icon, label) in items)
              ChoiceChip(
                selected: selected.type == type && selected.name == label,
                onSelected: (_) => onSelected(ToolSelection(type, label)),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 6),
                    Text(label),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
