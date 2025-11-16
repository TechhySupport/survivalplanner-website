import 'package:flutter/material.dart';

enum BuildingType {
  btMember1,
  btMember2,
  btMember3,
  bearTrap1,
  bearTrap2,
  bearTrap3,
  flag,
  hq,
  // Permanent buildings
  sunfireCastle,
  westplainTurret,
  eastcourtTurret,
  southwingTurret,
  northgroundTurret,
  stronghold1,
  stronghold2,
  stronghold3,
  stronghold4,
  fortress1,
  fortress2,
  fortress3,
  fortress4,
  fortress5,
  fortress6,
  fortress7,
  fortress8,
  fortress9,
  fortress10,
  fortress11,
  fortress12,
}

class MapObject {
  final String id;
  final BuildingType type;
  final int x;
  final int y;

  MapObject({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
  });

  MapObject copyWith({int? x, int? y}) {
    return MapObject(id: id, type: type, x: x ?? this.x, y: y ?? this.y);
  }

  // How many tiles wide and tall this building covers
  int get tileWidth {
    switch (type) {
      case BuildingType.sunfireCastle:
      case BuildingType.stronghold1:
      case BuildingType.stronghold2:
      case BuildingType.stronghold3:
      case BuildingType.stronghold4:
      case BuildingType.fortress1:
      case BuildingType.fortress2:
      case BuildingType.fortress3:
      case BuildingType.fortress4:
      case BuildingType.fortress5:
      case BuildingType.fortress6:
      case BuildingType.fortress7:
      case BuildingType.fortress8:
      case BuildingType.fortress9:
      case BuildingType.fortress10:
      case BuildingType.fortress11:
      case BuildingType.fortress12:
        return 6; // 6x6 buildings
      case BuildingType.westplainTurret:
      case BuildingType.eastcourtTurret:
      case BuildingType.southwingTurret:
      case BuildingType.northgroundTurret:
        return 2; // 2x2 for turrets
      case BuildingType.btMember1:
      case BuildingType.btMember2:
      case BuildingType.btMember3:
      case BuildingType.hq:
        return 3; // 3x3 for BT members and HQ
      default:
        return 1; // 1x1 for traps and flags
    }
  }

  int get tileHeight {
    return tileWidth; // All buildings are square
  }

  // Exclusion radius - area around building where nothing can be placed
  int get exclusionRadiusWidth {
    switch (type) {
      case BuildingType.sunfireCastle:
        return 30; // 10x10 exclusion radius for Sunfire Castle
      case BuildingType.stronghold1:
      case BuildingType.stronghold2:
      case BuildingType.stronghold3:
      case BuildingType.stronghold4:
      case BuildingType.fortress1:
      case BuildingType.fortress2:
      case BuildingType.fortress3:
      case BuildingType.fortress4:
      case BuildingType.fortress5:
      case BuildingType.fortress6:
      case BuildingType.fortress7:
      case BuildingType.fortress8:
      case BuildingType.fortress9:
      case BuildingType.fortress10:
      case BuildingType.fortress11:
      case BuildingType.fortress12:
        return 6;
      case BuildingType.hq:
        return 15; // 15x15 exclusion radius for HQ
      case BuildingType.flag:
        return 7; // 7x7 exclusion radius for Flag
      default:
        return 0; // No exclusion zone for turrets, BT members, traps
    }
  }

  int get exclusionRadiusHeight {
    return exclusionRadiusWidth; // Always square
  }

  // Check if a point (px, py) is within this building's exclusion zone
  bool isInExclusionZone(int px, int py) {
    if (exclusionRadiusWidth == 0) return false;

    // Calculate the center of the building
    final centerX = x + (tileWidth / 2);
    final centerY = y + (tileHeight / 2);

    // Check if point is within exclusion radius
    final dx = (px - centerX).abs();
    final dy = (py - centerY).abs();

    return dx <= exclusionRadiusWidth / 2 && dy <= exclusionRadiusHeight / 2;
  }

  String get displayName {
    switch (type) {
      case BuildingType.btMember1:
        return 'BT Member 1';
      case BuildingType.btMember2:
        return 'BT Member 2';
      case BuildingType.btMember3:
        return 'BT Member 3';
      case BuildingType.bearTrap1:
        return 'Bear Trap 1';
      case BuildingType.bearTrap2:
        return 'Bear Trap 2';
      case BuildingType.bearTrap3:
        return 'Bear Trap 3';
      case BuildingType.flag:
        return 'Flag';
      case BuildingType.hq:
        return 'HQ';
      case BuildingType.sunfireCastle:
        return 'Sunfire Castle';
      case BuildingType.westplainTurret:
        return 'Westplain Turret';
      case BuildingType.eastcourtTurret:
        return 'Eastcourt Turret';
      case BuildingType.southwingTurret:
        return 'Southwing Turret';
      case BuildingType.northgroundTurret:
        return 'Northground Turret';
      case BuildingType.stronghold1:
        return 'Stronghold 1';
      case BuildingType.stronghold2:
        return 'Stronghold 2';
      case BuildingType.stronghold3:
        return 'Stronghold 3';
      case BuildingType.stronghold4:
        return 'Stronghold 4';
      case BuildingType.fortress1:
        return 'Fortress 1';
      case BuildingType.fortress2:
        return 'Fortress 2';
      case BuildingType.fortress3:
        return 'Fortress 3';
      case BuildingType.fortress4:
        return 'Fortress 4';
      case BuildingType.fortress5:
        return 'Fortress 5';
      case BuildingType.fortress6:
        return 'Fortress 6';
      case BuildingType.fortress7:
        return 'Fortress 7';
      case BuildingType.fortress8:
        return 'Fortress 8';
      case BuildingType.fortress9:
        return 'Fortress 9';
      case BuildingType.fortress10:
        return 'Fortress 10';
      case BuildingType.fortress11:
        return 'Fortress 11';
      case BuildingType.fortress12:
        return 'Fortress 12';
    }
  }

  Color get color {
    switch (type) {
      case BuildingType.btMember1:
        return const Color.fromARGB(255, 166, 0, 255);
      case BuildingType.btMember2:
        return const Color.fromARGB(255, 30, 223, 12);
      case BuildingType.btMember3:
        return Colors.orange;
      case BuildingType.bearTrap1:
      case BuildingType.bearTrap2:
      case BuildingType.bearTrap3:
        return Colors.brown;
      case BuildingType.flag:
        return Colors.yellow;
      case BuildingType.hq:
        return Colors.deepPurple;
      case BuildingType.sunfireCastle:
        return Colors.red.shade900; // Dark red
      case BuildingType.westplainTurret:
      case BuildingType.eastcourtTurret:
      case BuildingType.southwingTurret:
      case BuildingType.northgroundTurret:
        return Colors.blue;
      case BuildingType.stronghold1:
      case BuildingType.stronghold2:
      case BuildingType.stronghold3:
      case BuildingType.stronghold4:
        return Colors.purple;
      case BuildingType.fortress1:
      case BuildingType.fortress2:
      case BuildingType.fortress3:
      case BuildingType.fortress4:
      case BuildingType.fortress5:
      case BuildingType.fortress6:
      case BuildingType.fortress7:
      case BuildingType.fortress8:
      case BuildingType.fortress9:
      case BuildingType.fortress10:
      case BuildingType.fortress11:
      case BuildingType.fortress12:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (type) {
      case BuildingType.btMember1:
      case BuildingType.btMember2:
      case BuildingType.btMember3:
        return Icons.person;
      case BuildingType.bearTrap1:
      case BuildingType.bearTrap2:
      case BuildingType.bearTrap3:
        return Icons.warning;
      case BuildingType.flag:
        return Icons.flag;
      case BuildingType.hq:
        return Icons.home;
      case BuildingType.sunfireCastle:
        return Icons.location_city;
      case BuildingType.westplainTurret:
      case BuildingType.eastcourtTurret:
      case BuildingType.southwingTurret:
      case BuildingType.northgroundTurret:
        return Icons.apartment;
      case BuildingType.stronghold1:
      case BuildingType.stronghold2:
      case BuildingType.stronghold3:
      case BuildingType.stronghold4:
        return Icons.account_balance;
      case BuildingType.fortress1:
      case BuildingType.fortress2:
      case BuildingType.fortress3:
      case BuildingType.fortress4:
      case BuildingType.fortress5:
      case BuildingType.fortress6:
      case BuildingType.fortress7:
      case BuildingType.fortress8:
      case BuildingType.fortress9:
      case BuildingType.fortress10:
      case BuildingType.fortress11:
      case BuildingType.fortress12:
        return Icons.business;
    }
  }
}
