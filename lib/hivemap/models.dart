import 'package:flutter/foundation.dart';

/// Types of placeable objects on the grid
enum ObjectType {
  select,
  flag,
  bearTrap,
  hq,
  member,
  mountain,
  lake,
  allianceNode,
}

/// A placed object with its grid position (top-left for multi-tile objects)
@immutable
class GridObject {
  final ObjectType type;
  final String name; // e.g. "BT1", "BT2", "Flag", "HQ", "BT1 Member"
  final int gameX; // game coordinate center X (0..1199)
  final int gameY; // game coordinate center Y (0..1199)
  final int? rank; // for member objects: 1..99
  final String? memberGroup; // 'BT1'|'BT2'|'BT3' for members
  final String? memberName; // resolved name from list based on rank

  const GridObject({
    required this.type,
    required this.name,
    required this.gameX,
    required this.gameY,
    this.rank,
    this.memberGroup,
    this.memberName,
  });

  GridObject copyWith({
    ObjectType? type,
    String? name,
    int? gameX,
    int? gameY,
    int? rank,
    String? memberGroup,
    String? memberName,
  }) => GridObject(
    type: type ?? this.type,
    name: name ?? this.name,
    gameX: gameX ?? this.gameX,
    gameY: gameY ?? this.gameY,
    rank: rank ?? this.rank,
    memberGroup: memberGroup ?? this.memberGroup,
    memberName: memberName ?? this.memberName,
  );

  @override
  bool operator ==(Object other) =>
      other is GridObject &&
      other.type == type &&
      other.name == name &&
      other.gameX == gameX &&
      other.gameY == gameY &&
      other.rank == rank &&
      other.memberGroup == memberGroup &&
      other.memberName == memberName;

  @override
  int get hashCode =>
      Object.hash(type, name, gameX, gameY, rank, memberGroup, memberName);

  @override
  String toString() =>
      'GridObject(type: $type, name: $name, game: ($gameX,$gameY), rank: $rank, group: $memberGroup, member: $memberName)';
}
