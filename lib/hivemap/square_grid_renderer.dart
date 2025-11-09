import 'package:flutter/material.dart';
import 'models.dart';
import 'placement_rules.dart';
import 'static_world.dart';

/// A simplified orthographic (non-isometric) grid renderer.
/// Each tile is a square of size [tileSize] in logical pixels.
class SquareGridRenderer extends StatelessWidget {
  final int gridW;
  final int gridH;
  final List<GridObject> objects;
  final int originGameX;
  final int originGameY;
  // If true, interpret game coordinates as swapped (gameX=vertical, gameY=horizontal)
  final bool axisSwapped;
  final int? highlightedIndex;
  final bool showCoordinates;
  final bool hideRadius;
  final bool showBuildingCoordinates;
  final int? selectedTileGameX;
  final int? selectedTileGameY;
  final int? hoverGameX;
  final int? hoverGameY;
  final ObjectType? hoverObjectType;
  final bool showSelectedTileCoordinates;

  static const double tileSize = 36.0;

  const SquareGridRenderer({
    super.key,
    required this.gridW,
    required this.gridH,
    required this.objects,
    required this.originGameX,
    required this.originGameY,
    this.axisSwapped = false,
    this.highlightedIndex,
    this.showCoordinates = false,
    this.hideRadius = false,
    this.showBuildingCoordinates = false,
    this.selectedTileGameX,
    this.selectedTileGameY,
    this.hoverGameX,
    this.hoverGameY,
    this.hoverObjectType,
    this.showSelectedTileCoordinates = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gridW * tileSize,
      height: gridH * tileSize,
      child: CustomPaint(
        painter: _SquarePainter(
          gridW: gridW,
          gridH: gridH,
          objects: objects,
          originGameX: originGameX,
          originGameY: originGameY,
          axisSwapped: axisSwapped,
          highlightedIndex: highlightedIndex,
          showCoordinates: showCoordinates,
          hideRadius: hideRadius,
          showBuildingCoordinates: showBuildingCoordinates,
          selectedTileGameX: selectedTileGameX,
          selectedTileGameY: selectedTileGameY,
          hoverGameX: hoverGameX,
          hoverGameY: hoverGameY,
          hoverObjectType: hoverObjectType,
          showSelectedTileCoordinates: showSelectedTileCoordinates,
        ),
      ),
    );
  }
}

class _SquarePainter extends CustomPainter {
  final int gridW;
  final int gridH;
  final List<GridObject> objects;
  final int originGameX;
  final int originGameY;
  final bool axisSwapped;
  final int? highlightedIndex;
  final bool showCoordinates;
  final bool hideRadius;
  final bool showBuildingCoordinates;
  final int? selectedTileGameX;
  final int? selectedTileGameY;
  final int? hoverGameX;
  final int? hoverGameY;
  final ObjectType? hoverObjectType;
  final bool showSelectedTileCoordinates;

  static const double s = SquareGridRenderer.tileSize;

  _SquarePainter({
    required this.gridW,
    required this.gridH,
    required this.objects,
    required this.originGameX,
    required this.originGameY,
    required this.axisSwapped,
    required this.highlightedIndex,
    required this.showCoordinates,
    required this.hideRadius,
    required this.showBuildingCoordinates,
    required this.selectedTileGameX,
    required this.selectedTileGameY,
    required this.hoverGameX,
    required this.hoverGameY,
    required this.hoverObjectType,
    required this.showSelectedTileCoordinates,
  });

  Rect _tileRect(int x, int y) => Rect.fromLTWH(x * s, y * s, s, s);

  // Map raw game coords (gameX, gameY) to viewport tile indices (vx, vy)
  // respecting axis swap if enabled.
  (int vx, int vy) mapToViewport(int gameX, int gameY) {
    if (!axisSwapped) {
      return (gameX - originGameX, gameY - originGameY);
    } else {
      // Swapped: horizontal screen axis shows gameY, vertical screen axis shows gameX
      return (gameY - originGameY, gameX - originGameX);
    }
  }

  void _drawTile(Canvas canvas, int x, int y, {Color? fill, Color? stroke}) {
    final r = _tileRect(x, y);
    if (fill != null) canvas.drawRect(r, Paint()..color = fill);
    if (stroke != null) {
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = stroke,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    Rect target,
    String text, {
    double maxWidth = 120,
    TextStyle style = const TextStyle(fontSize: 11, color: Colors.black),
    Color? bg,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    final center = target.center;
    if (bg != null) {
      final rect = Rect.fromCenter(
        center: center,
        width: tp.width + 8,
        height: tp.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = bg,
      );
    }
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  Color _colorFor(GridObject obj, bool hl) {
    switch (obj.type) {
      case ObjectType.flag:
        return hl ? Colors.indigo : Colors.indigo.shade400;
      case ObjectType.bearTrap:
        if (obj.name.contains('BT1')) {
          return hl ? Colors.blue : Colors.blue.shade400;
        } else if (obj.name.contains('BT2')) {
          return hl ? Colors.green : Colors.green.shade400;
        } else {
          return hl ? Colors.grey.shade800 : Colors.grey.shade600;
        }
      case ObjectType.hq:
        return hl ? Colors.deepOrange : Colors.deepOrange.shade400;
      case ObjectType.member:
        return hl ? Colors.purple.shade700 : Colors.purple.shade500;
      case ObjectType.mountain:
        return hl ? Colors.brown.shade600 : Colors.brown.shade500;
      case ObjectType.lake:
        return hl ? Colors.lightBlue.shade600 : Colors.lightBlue.shade400;
      case ObjectType.allianceNode:
        return hl ? Colors.amber.shade700 : Colors.amber.shade600;
      case ObjectType.select:
        return Colors.transparent;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Base grid
    for (int y = 0; y < gridH; y++) {
      for (int x = 0; x < gridW; x++) {
        _drawTile(
          canvas,
          x,
          y,
          fill: const Color(0xFFF3F4F6),
          stroke: Colors.grey.withOpacity(0.35),
        );
      }
    }

    // Coordinates axes (swap semantics: vertical is X, horizontal is Y)
    if (showCoordinates) {
      // Display coordinates inverted so top-left starts at worldMax (e.g., 1199)
      // Top row shows Y values across columns (horizontal axis)
      for (int x = 0; x < gridW; x++) {
        final yVal = worldMax - (originGameX + x);
        _drawText(
          canvas,
          _tileRect(x, 0).deflate(4),
          'Y=$yVal',
          style: const TextStyle(fontSize: 10, color: Colors.black54),
          bg: Colors.white.withOpacity(0.7),
        );
      }
      // Left column shows X values down rows (vertical axis)
      for (int y = 0; y < gridH; y++) {
        final xVal = worldMax - (originGameY + y);
        _drawText(
          canvas,
          _tileRect(0, y).deflate(4),
          'X=$xVal',
          style: const TextStyle(fontSize: 10, color: Colors.black54),
          bg: Colors.white.withOpacity(0.7),
        );
      }
    }

    // Permanents footprint
    if (!arePermanentsHidden()) {
      final permanents = getPermanentStructures();
      for (final ps in permanents) {
        final (tlx, tly) = ps.footprintTopLeft;
        for (int dy = 0; dy < ps.h; dy++) {
          for (int dx = 0; dx < ps.w; dx++) {
            final gx = tlx + dx;
            final gy = tly + dy;
            final (vx, vy) = mapToViewport(gx, gy);
            if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
            _drawTile(
              canvas,
              vx,
              vy,
              fill: ps.name.toLowerCase().contains('castle')
                  ? Colors.red.shade600
                  : (ps.name.toLowerCase().contains('turret')
                        ? Colors.green.shade600
                        : const Color(0xFF334155)),
              stroke: Colors.black.withOpacity(0.25),
            );
          }
        }

        // Highlight the BOTTOM-RIGHT ANCHOR tile in pink for visual verification
        final (avx, avy) = mapToViewport(ps.ax, ps.ay);
        if (avx >= 0 && avy >= 0 && avx < gridW && avy < gridH) {
          final r = _tileRect(avx, avy).deflate(1.5);
          canvas.drawRect(
            r,
            Paint()
              ..color = Colors.pinkAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }
        // Center label
        final (cx, cy) = mapToViewport(ps.cx, ps.cy);
        if (cx >= 0 && cy >= 0 && cx < gridW && cy < gridH) {
          String label = ps.name;
          if (showBuildingCoordinates) {
            // Show both RAW (game) and DISPLAY (inverted) coordinates to avoid confusion.
            // Swapped axis semantics: display X derives from game Y; display Y derives from game X.
            final dispAnchorX = worldMax - ps.ay;
            final dispAnchorY = worldMax - ps.ax;
            final dispCenterX = worldMax - ps.cy;
            final dispCenterY = worldMax - ps.cx;
            final (tlRawX, tlRawY) = ps.footprintTopLeft; // footprint TL (raw)
            final tlDispX = worldMax - tlRawY; // display-inverted + swapped
            final tlDispY = worldMax - tlRawX;
            label +=
                "\nAnchor Raw(${ps.ax},${ps.ay}) Disp(${dispAnchorX},${dispAnchorY})";
            label +=
                "\nCenter Raw(${ps.cx},${ps.cy}) Disp(${dispCenterX},${dispCenterY})";
            label +=
                "\nTL Raw(${tlRawX},${tlRawY}) Disp(${tlDispX},${tlDispY})";
          }
          _drawText(
            canvas,
            _tileRect(cx, cy),
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            bg: Colors.white.withOpacity(0.85),
          );
        }
      }
    }

    // Objects
    for (int i = 0; i < objects.length; i++) {
      final obj = objects[i];
      final f = footprintFor(obj.type);
      final tl = centerToTopLeft(obj.type, obj.gameX, obj.gameY);
      final hl = highlightedIndex != null && highlightedIndex == i;
      final color = _colorFor(obj, hl);
      for (int dy = 0; dy < f.h; dy++) {
        for (int dx = 0; dx < f.w; dx++) {
          final (vx, vy) = mapToViewport(tl.x + dx, tl.y + dy);
          if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
          _drawTile(
            canvas,
            vx,
            vy,
            fill: color.withOpacity(hl ? 0.65 : 0.9),
            stroke: Colors.black.withOpacity(hl ? 0.5 : 0.3),
          );
        }
      }
      final (anchorX, anchorY) = mapToViewport(
        tl.x + (f.w - 1) ~/ 2,
        tl.y + (f.h - 1) ~/ 2,
      );
      if (anchorX >= 0 && anchorY >= 0 && anchorX < gridW && anchorY < gridH) {
        _drawText(
          canvas,
          _tileRect(anchorX, anchorY),
          obj.type == ObjectType.member ? (obj.memberName ?? 'MB') : obj.name,
          bg: Colors.white.withOpacity(0.8),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        );
      }

      if (obj.type == ObjectType.flag && !hideRadius) {
        const r = 3;
        for (int dy = -r; dy <= r; dy++) {
          for (int dx = -r; dx <= r; dx++) {
            final (vx, vy) = mapToViewport(obj.gameX + dx, obj.gameY + dy);
            if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
            _drawTile(
              canvas,
              vx,
              vy,
              fill: Colors.indigoAccent.withOpacity(0.10),
              stroke: Colors.indigo.withOpacity(0.15),
            );
          }
        }
      }
      if (obj.type == ObjectType.hq && !hideRadius) {
        const r = 7;
        for (int dy = -r; dy <= r; dy++) {
          for (int dx = -r; dx <= r; dx++) {
            final (vx, vy) = mapToViewport(obj.gameX + dx, obj.gameY + dy);
            if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
            _drawTile(
              canvas,
              vx,
              vy,
              fill: Colors.redAccent.withOpacity(0.08),
              stroke: Colors.red.withOpacity(0.15),
            );
          }
        }
      }
    }

    // Hover preview footprint
    if (hoverGameX != null && hoverGameY != null && hoverObjectType != null) {
      final f = footprintFor(hoverObjectType!);
      final tl = centerToTopLeft(hoverObjectType!, hoverGameX!, hoverGameY!);
      for (int dy = 0; dy < f.h; dy++) {
        for (int dx = 0; dx < f.w; dx++) {
          final (vx, vy) = mapToViewport(tl.x + dx, tl.y + dy);
          if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
          _drawTile(
            canvas,
            vx,
            vy,
            fill: Colors.blue.withOpacity(0.15),
            stroke: Colors.blue.withOpacity(0.40),
          );
        }
      }
    }

    // Selected tile highlight
    if (selectedTileGameX != null && selectedTileGameY != null) {
      final (vx, vy) = mapToViewport(selectedTileGameX!, selectedTileGameY!);
      if (vx >= 0 && vy >= 0 && vx < gridW && vy < gridH) {
        _drawTile(
          canvas,
          vx,
          vy,
          fill: Colors.yellow.withOpacity(0.20),
          stroke: Colors.orange.withOpacity(0.8),
        );
        if (showSelectedTileCoordinates) {
          // Swapped axis semantics: display X from gameY, display Y from gameX.
          final dispX = worldMax - selectedTileGameY!;
          final dispY = worldMax - selectedTileGameX!;
          _drawText(
            canvas,
            _tileRect(vx, vy),
            'X=$dispX Y=$dispY',
            bg: Colors.white.withOpacity(0.85),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SquarePainter old) {
    return gridW != old.gridW ||
        gridH != old.gridH ||
        originGameX != old.originGameX ||
        originGameY != old.originGameY ||
        objects != old.objects ||
        highlightedIndex != old.highlightedIndex ||
        showCoordinates != old.showCoordinates ||
        showBuildingCoordinates != old.showBuildingCoordinates ||
        selectedTileGameX != old.selectedTileGameX ||
        selectedTileGameY != old.selectedTileGameY ||
        hoverGameX != old.hoverGameX ||
        hoverGameY != old.hoverGameY ||
        hoverObjectType != old.hoverObjectType;
  }
}
