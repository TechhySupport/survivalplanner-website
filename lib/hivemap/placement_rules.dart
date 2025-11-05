import 'dart:math';

import 'models.dart';
import 'static_world.dart';

const int worldMax = 1199; // valid game coordinates are 0..1199 inclusive

/// Returns footprint width and height (in tiles) for the given object type.
({int w, int h}) footprintFor(ObjectType type) {
  switch (type) {
    case ObjectType.select:
      return (w: 0, h: 0); // Select tool doesn't place objects
    case ObjectType.flag:
      return (w: 1, h: 1);
    case ObjectType.bearTrap:
      // BT traps occupy 3x3 tiles
      return (w: 3, h: 3);
    case ObjectType.hq:
      return (w: 3, h: 3);
    case ObjectType.member:
      return (w: 2, h: 2);
    case ObjectType.mountain:
      return (w: 1, h: 1);
    case ObjectType.lake:
      return (w: 1, h: 1);
    case ObjectType.allianceNode:
      return (w: 2, h: 2);
  }
}

/// Convert center coordinates to top-left of footprint.
({int x, int y}) centerToTopLeft(ObjectType type, int cx, int cy) {
  final f = footprintFor(type);
  final x = cx - (f.w ~/ 2);
  final y = cy - (f.h ~/ 2);
  return (x: x, y: y);
}

/// Produces all occupied cells for the object's footprint placed at top-left (x, y).
Iterable<Point<int>> footprintCellsTopLeft(
  ObjectType type,
  int x,
  int y,
) sync* {
  final f = footprintFor(type);
  for (var dy = 0; dy < f.h; dy++) {
    for (var dx = 0; dx < f.w; dx++) {
      yield Point<int>(x + dx, y + dy);
    }
  }
}

/// Produces all occupied cells using center coordinates.
Iterable<Point<int>> footprintCellsFromCenter(
  ObjectType type,
  int cx,
  int cy,
) sync* {
  final tl = centerToTopLeft(type, cx, cy);
  yield* footprintCellsTopLeft(type, tl.x, tl.y);
}

/// Validates placement within bounds and no-overlap with existing objects using center coordinates.
bool canPlaceCenter({
  required List<GridObject> existing,
  required ObjectType type,
  required int centerX,
  required int centerY,
  int? ignoreIndex,
}) {
  final f = footprintFor(type);
  final tl = centerToTopLeft(type, centerX, centerY);
  // Ensure footprint lies fully in world bounds 0..worldMax
  if (tl.x < 0 || tl.y < 0) return false;
  if (tl.x + f.w - 1 > worldMax || tl.y + f.h - 1 > worldMax) return false;

  // Precompute occupied by existing
  final occupied = <Point<int>>{};
  for (int i = 0; i < existing.length; i++) {
    if (ignoreIndex != null && i == ignoreIndex) continue;
    final obj = existing[i];
    for (final p in footprintCellsFromCenter(obj.type, obj.gameX, obj.gameY)) {
      occupied.add(p);
    }
  }

  // Add permanent structures: their exclusion zones are not buildable.
  // This ensures no user-placed object can overlap those zones.
  final blocked = permanentBlockedCells();
  occupied.addAll(blocked);

  // Check overlap for new object
  for (final p in footprintCellsTopLeft(type, tl.x, tl.y)) {
    if (occupied.contains(p)) return false;
  }

  return true;
}

/// Returns index of object whose footprint contains (gx,gy), or -1 if none.
int hitTestObjects(List<GridObject> objects, int gx, int gy) {
  for (int i = 0; i < objects.length; i++) {
    final o = objects[i];
    for (final p in footprintCellsFromCenter(o.type, o.gameX, o.gameY)) {
      if (p.x == gx && p.y == gy) return i;
    }
  }
  return -1;
}
