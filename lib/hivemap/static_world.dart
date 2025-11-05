import 'dart:math';

/// Immutable world structures that always exist on the map and cannot be
/// edited by users.
///
/// Coordinate semantics:
/// - Anchor (ax, ay) is the BOTTOM-RIGHT tile of the structure's footprint.
/// - Footprint size is (w x h) tiles.
/// - Exclusion radii (exclW/exclH) are specified as tiles FROM CENTER; the
///   exclusion rectangle size is (2R+1) in each axis and is centered on the
///   structure's CENTER, derived from (ax, ay, w, h).
/// - Influence radius (visual only) is also specified from center.
class PermanentStructure {
  final String name;
  // Bottom-right anchor of the footprint in game tile coordinates
  final int ax;
  final int ay;
  final int w;
  final int h;
  // Exclusion radius (tiles from center in X and Y). A value of 6 means
  // 6 tiles from center, i.e., an exclusion rectangle of size (2*6+1)x(2*6+1).
  final int exclW; // interpreted as radius X
  final int exclH; // interpreted as radius Y
  // Optional influence radius (non-blocking visual), tiles from center.
  final int? influenceR;

  const PermanentStructure({
    required this.name,
    required this.ax,
    required this.ay,
    required this.w,
    required this.h,
    this.exclW = 0,
    this.exclH = 0,
    this.influenceR,
  });

  PermanentStructure copyWith({
    String? name,
    int? ax,
    int? ay,
    int? w,
    int? h,
    int? exclW,
    int? exclH,
    int? influenceR,
  }) => PermanentStructure(
    name: name ?? this.name,
    ax: ax ?? this.ax,
    ay: ay ?? this.ay,
    w: w ?? this.w,
    h: h ?? this.h,
    exclW: exclW ?? this.exclW,
    exclH: exclH ?? this.exclH,
    influenceR: influenceR ?? this.influenceR,
  );

  /// Center coordinates derived from bottom-right anchor and footprint size.
  /// Note: Y uses subtraction so center stays correct on a Y-up game grid.
  int get cx => ax - ((w - 1) ~/ 2);
  int get cy => ay - ((h - 1) ~/ 2);

  /// Top-left of the footprint rectangle in tile coordinates.
  (int x, int y) get footprintTopLeft =>
      (cx - ((w - 1) ~/ 2), cy - ((h - 1) ~/ 2));

  /// Computed exclusion rectangle width/height from radius. If radius is 0,
  /// only the footprint area is excluded.
  int get exclusionWidth => (exclW == 0) ? w : (exclW * 2 + 1);
  int get exclusionHeight => (exclH == 0) ? h : (exclH * 2 + 1);

  /// Optional influence zone width/height and top-left (purely visual)
  int? get influenceWidth =>
      (influenceR == null) ? null : (influenceR! * 2 + 1);
  int? get influenceHeight =>
      (influenceR == null) ? null : (influenceR! * 2 + 1);
  (int x, int y)? get influenceTopLeft => (influenceR == null)
      ? null
      : (cx - (influenceWidth! ~/ 2), cy - (influenceHeight! ~/ 2));
  Iterable<Point<int>> influenceCells() sync* {
    if (influenceR == null) return;
    final iw = influenceWidth!;
    final ih = influenceHeight!;
    final (tx, ty) = influenceTopLeft!;
    for (int dy = 0; dy < ih; dy++) {
      for (int dx = 0; dx < iw; dx++) {
        yield Point(tx + dx, ty + dy);
      }
    }
  }

  /// Top-left of the exclusion rectangle; if radius is 0, equals footprint.
  (int x, int y) get exclusionTopLeft {
    final ew = exclusionWidth;
    final eh = exclusionHeight;
    return (cx - (ew ~/ 2), cy - (eh ~/ 2));
  }

  /// All cells covered by the structure's footprint.
  Iterable<Point<int>> footprintCells() sync* {
    final (tx, ty) = footprintTopLeft;
    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        yield Point(tx + dx, ty + dy);
      }
    }
  }

  /// All cells covered by the no-build exclusion zone. If exclW/H is 0, this is
  /// the same as the footprint.
  Iterable<Point<int>> exclusionCells() sync* {
    final ew = exclusionWidth;
    final eh = exclusionHeight;
    final (tx, ty) = exclusionTopLeft;
    for (int dy = 0; dy < eh; dy++) {
      for (int dx = 0; dx < ew; dx++) {
        yield Point(tx + dx, ty + dy);
      }
    }
  }
}

// Permanent structures data (bottom-right coordinates, footprint size, exclusion size)
// NOTE: Coordinates are provided as bottom-right X,Y of the footprint.
const List<PermanentStructure> initialPermanentStructures = [
  PermanentStructure(
    name: 'Sunfire Castle',
    ax: 602,
    ay: 602, // 597 + 7 for bottom-right
    w: 6,
    h: 6,
    exclW: 12,
    exclH: 12,
    influenceR: 20,
  ),

  // --- Turrets (2x2, perfect cross) — bottom-right anchors as specified
  PermanentStructure(name: 'Westplain Turret', ax: 594, ay: 604, w: 2, h: 2),
  PermanentStructure(name: 'Eastcourt Turret', ax: 604, ay: 594, w: 2, h: 2),
  PermanentStructure(name: 'Southwing Turret', ax: 594, ay: 594, w: 2, h: 2),
  PermanentStructure(name: 'Northground Turret', ax: 604, ay: 604, w: 2, h: 2),

  // --- Strongholds (6x6)
  PermanentStructure(
    name: 'Stronghold 1',
    ax: 600,
    ay: 803,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Stronghold 2',
    ax: 403,
    ay: 600,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Stronghold 3',
    ax: 600,
    ay: 403,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Stronghold 4',
    ax: 803,
    ay: 600,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),

  // --- Fortresses (6x6)
  PermanentStructure(
    name: 'Fortress 1',
    ax: 240,
    ay: 831,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 2',
    ax: 240,
    ay: 609,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 3',
    ax: 240,
    ay: 351,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 4',
    ax: 369,
    ay: 240,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 5',
    ax: 591,
    ay: 240,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 6',
    ax: 591,
    ay: 351,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 7',
    ax: 591,
    ay: 561,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 8',
    ax: 591,
    ay: 670,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 9',
    ax: 441,
    ay: 831,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 10',
    ax: 351,
    ay: 831,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 11',
    ax: 240,
    ay: 670,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
  PermanentStructure(
    name: 'Fortress 12',
    ax: 141,
    ay: 670,
    w: 6,
    h: 6,
    exclW: 6,
    exclH: 6,
  ),
];

// Mutable runtime copy used by the app (enables debug edits in God mode)
List<PermanentStructure> currentPermanentStructures =
    List<PermanentStructure>.from(initialPermanentStructures);

List<PermanentStructure> getPermanentStructures() => currentPermanentStructures;

// Temporary global toggle to hide permanents from rendering (visual only)
// Keeps placement rules intact (exclusions still block placement).
bool _permanentsHidden = true; // default to hidden as requested
bool arePermanentsHidden() => _permanentsHidden;
void setPermanentsHidden(bool v) {
  _permanentsHidden = v;
}

/// Replace a permanent structure at [index] with [ps].
void replacePermanentAt(int index, PermanentStructure ps) {
  if (index < 0 || index >= currentPermanentStructures.length) return;
  currentPermanentStructures[index] = ps;
}

/// Reset all permanent structures to their initial defaults.
void resetPermanentsToDefault() {
  currentPermanentStructures = List<PermanentStructure>.from(
    initialPermanentStructures,
  );
}

/// Find permanent structure index whose footprint contains (gx, gy), or -1.
int findPermanentIndexAt(int gx, int gy) {
  for (int i = 0; i < currentPermanentStructures.length; i++) {
    final ps = currentPermanentStructures[i];
    for (final p in ps.footprintCells()) {
      if (p.x == gx && p.y == gy) return i;
    }
  }
  return -1;
}

/// Returns a set of all blocked cells from structures' exclusion zones.
Set<Point<int>> permanentBlockedCells() {
  final s = <Point<int>>{};
  for (final ps in currentPermanentStructures) {
    s.addAll(ps.exclusionCells());
  }
  return s;
}

/// Returns a set of all cells physically occupied by the structures' footprints.
Set<Point<int>> permanentFootprintCells() {
  final s = <Point<int>>{};
  for (final ps in currentPermanentStructures) {
    s.addAll(ps.footprintCells());
  }
  return s;
}
