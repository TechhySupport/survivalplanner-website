import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'models.dart';
import 'placement_rules.dart';
import 'static_world.dart';

class GridRenderer extends StatelessWidget {
  final int gridW;
  final int gridH;
  final List<GridObject> objects;
  final int? highlightedIndex; // optional object index to emphasize
  final bool drawGrid;
  final bool showCoordinates; // render game coord labels on tiles if true
  final bool hideRadius; // hide radius circles for flags and HQ
  final bool showBuildingCoordinates; // show coordinates for buildings
  final int originGameX;
  final int originGameY;
  final int?
  selectedTileGameX; // selected tile (game coord) for crosshair/highlight
  final int? selectedTileGameY;
  final int? hoverGameX; // hover preview coordinates
  final int? hoverGameY;
  final ObjectType? hoverObjectType; // type of object being hovered for preview
  final bool showCrosshair; // whether to show crosshair for placement
  final bool
  showSelectedTileCoordinates; // show inline coordinates in select mode
  final bool
  flipAxisDirection; // when true, invert numeric direction so X increases upward and Y decreases to the right

  static const double tileW = 60; // isometric diamond width
  static const double tileH = 30; // isometric diamond height
  static const double halfW = tileW / 2;
  static const double halfH = tileH / 2;

  const GridRenderer({
    super.key,
    required this.gridW,
    required this.gridH,
    required this.objects,
    required this.originGameX,
    required this.originGameY,
    this.highlightedIndex,
    this.drawGrid = true,
    this.showCoordinates = false,
    this.hideRadius = false,
    this.showBuildingCoordinates = false,
    this.selectedTileGameX,
    this.selectedTileGameY,
    this.hoverGameX,
    this.hoverGameY,
    this.hoverObjectType,
    this.showCrosshair = false,
    this.showSelectedTileCoordinates = false,
    this.flipAxisDirection = false,
  });

  // Total bounding size for an isometric grid rectangle
  Size get size => Size((gridW + gridH) * halfW, (gridW + gridH) * halfH);

  // Origin X so that (0,0) appears inside bounds
  double get originX => gridH * halfW;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: _GridPainter(
          gridW: gridW,
          gridH: gridH,
          objects: objects,
          highlightedIndex: highlightedIndex,
          drawGrid: drawGrid,
          showCoordinates: showCoordinates,
          hideRadius: hideRadius,
          showBuildingCoordinates: showBuildingCoordinates,
          originX: originX,
          originGameX: originGameX,
          originGameY: originGameY,
          selectedTileGameX: selectedTileGameX,
          selectedTileGameY: selectedTileGameY,
          hoverGameX: hoverGameX,
          hoverGameY: hoverGameY,
          hoverObjectType: hoverObjectType,
          showCrosshair: showCrosshair,
          showSelectedTileCoordinates: showSelectedTileCoordinates,
          flipAxisDirection: flipAxisDirection,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int gridW;
  final int gridH;
  final List<GridObject> objects;
  final int? highlightedIndex;
  final bool drawGrid;
  final bool showCoordinates;
  final bool hideRadius;
  final bool showBuildingCoordinates;
  final double originX;
  final int originGameX;
  final int originGameY;
  final int? selectedTileGameX;
  final int? selectedTileGameY;
  final int? hoverGameX;
  final int? hoverGameY;
  final ObjectType? hoverObjectType;
  final bool showCrosshair;
  final bool showSelectedTileCoordinates;
  final bool flipAxisDirection;

  static const double tileH = GridRenderer.tileH;
  static const double halfW = GridRenderer.halfW;
  static const double halfH = GridRenderer.halfH;

  _GridPainter({
    required this.gridW,
    required this.gridH,
    required this.objects,
    required this.highlightedIndex,
    required this.drawGrid,
    required this.showCoordinates,
    required this.hideRadius,
    required this.showBuildingCoordinates,
    required this.originX,
    required this.originGameX,
    required this.originGameY,
    required this.selectedTileGameX,
    required this.selectedTileGameY,
    required this.hoverGameX,
    required this.hoverGameY,
    required this.hoverObjectType,
    required this.showCrosshair,
    required this.showSelectedTileCoordinates,
    required this.flipAxisDirection,
  });

  // Map an object to its short label
  String _labelFor(GridObject obj) {
    switch (obj.type) {
      case ObjectType.select:
        return ''; // Select tool doesn't have objects to label
      case ObjectType.flag:
        return 'F';
      case ObjectType.bearTrap:
        // Expect obj.name like BT1/BT2/BT3; fallback to BT
        String label = (obj.name.isNotEmpty) ? obj.name : 'BT';
        if (showBuildingCoordinates) {
          // Display raw game coordinates (match game input)
          label += '\nX=${obj.gameX} Y=${obj.gameY}';
        }
        return label;
      case ObjectType.hq:
        String label = 'HQ';
        if (showBuildingCoordinates) {
          label += '\nX=${obj.gameX} Y=${obj.gameY}';
        }
        return label;
      case ObjectType.member:
        // For members, show the assigned memberName if available; otherwise show rank
        String label = '';
        if ((obj.memberName ?? '').isNotEmpty) {
          label = obj.memberName!;
        } else if (obj.rank != null) {
          label = 'Rank ${obj.rank}';
        } else if (obj.name.contains('BT1') ||
            (obj.memberGroup ?? '').contains('BT1')) {
          label = 'MB1';
        } else if (obj.name.contains('BT2') ||
            (obj.memberGroup ?? '').contains('BT2')) {
          label = 'MB2';
        } else if (obj.name.contains('BT3') ||
            (obj.memberGroup ?? '').contains('BT3')) {
          label = 'MB3';
        } else {
          label = 'MB';
        }

        if (showBuildingCoordinates) {
          label += '\nX=${obj.gameX} Y=${obj.gameY}';
        }
        return label;
      case ObjectType.mountain:
        return 'M';
      case ObjectType.lake:
        return 'L';
      case ObjectType.allianceNode:
        return 'AN';
    }
  }

  // TODO: Make (0,0) the bottom (red) corner and (1199,1199) the top (green) corner.
  // X should increase going upward.
  // Y should decrease going rightward.
  // Flip or invert the coordinate math to match this orientation.
  //
  // final newX = baseX + (rowOffset * -1); // X increases upward
  // final newY = baseY - columnOffset;     // Y decreases rightward
  Offset _tileTop(int x, int y) {
    // Flipped isometric projection per requested axis:
    // X increases upward (top-right), Y decreases downward (bottom-right)
    final sx = originX + (x + y) * halfW;
    final sy = (y - x) * halfH;
    return Offset(sx, sy);
  }

  Path _diamondPathAt(int x, int y) {
    final top = _tileTop(x, y);
    final right = top.translate(halfW, halfH);
    final bottom = top.translate(0, tileH);
    final left = top.translate(-halfW, halfH);
    final p = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    return p;
  }

  void _drawTile(Canvas canvas, int x, int y, {Color? fill, Color? stroke}) {
    final path = _diamondPathAt(x, y);
    if (fill != null) {
      canvas.drawPath(path, Paint()..color = fill);
    }
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    int x,
    int y,
    String text, {
    TextStyle style = const TextStyle(fontSize: 10, color: Colors.black87),
    Color? backgroundColor,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    Offset offset = Offset.zero,
    double maxWidth = 80,
    double borderRadius = 4,
  }) {
    final top = _tileTop(x, y);
    final center = top
        .translate(0, tileH * 0.55)
        .translate(offset.dx, offset.dy);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    // Optional rounded background behind the text
    if (backgroundColor != null) {
      final rect = Rect.fromLTWH(
        center.dx - tp.width / 2 - padding.left,
        center.dy - tp.height / 2 - padding.top,
        tp.width + padding.left + padding.right,
        tp.height + padding.top + padding.bottom,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(borderRadius),
      );
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRRect(rrect, bgPaint);
    }

    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // Draws a two-line member label: Name (bold, larger) and group (small)
  void _drawMemberLabel(
    Canvas canvas,
    int x,
    int y,
    String name,
    String group,
  ) {
    final top = _tileTop(x, y);
    final center = top.translate(0, tileH * 0.55);
    final namePainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    final groupPainter = TextPainter(
      text: TextSpan(
        text: group,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    final totalHeight = namePainter.height + 2 + groupPainter.height;
    final start =
        center -
        Offset(
          (namePainter.width > groupPainter.width
                  ? namePainter.width
                  : groupPainter.width) /
              2,
          totalHeight / 2,
        );
    namePainter.paint(canvas, start);
    groupPainter.paint(
      canvas,
      Offset(
        start.dx + (namePainter.width - groupPainter.width) / 2,
        start.dy + namePainter.height + 2,
      ),
    );
  }

  String? _btGroupFor(GridObject obj) {
    // Determine BT group either from name or memberGroup
    final n = obj.name.toUpperCase();
    final g = (obj.memberGroup ?? '').toUpperCase();
    if (n.contains('BT1') || g == 'BT1') return 'BT1';
    if (n.contains('BT2') || g == 'BT2') return 'BT2';
    if (n.contains('BT3') || g == 'BT3') return 'BT3';
    return null;
  }

  Color _colorForObject(GridObject obj, bool isHighlighted) {
    switch (obj.type) {
      case ObjectType.select:
        return Colors.transparent; // Select tool doesn't have objects to color
      case ObjectType.flag:
        return Colors.indigoAccent;
      case ObjectType.hq:
        return Colors.deepOrange;
      case ObjectType.bearTrap:
        final grp = _btGroupFor(obj);
        final base = switch (grp) {
          'BT1' => Colors.blue,
          'BT2' => Colors.green,
          'BT3' => Colors.grey,
          _ => Colors.blueGrey,
        };
        return isHighlighted ? base.shade500 : base.shade400;
      case ObjectType.member:
        final grp = _btGroupFor(obj);
        // Dark variants
        final base = switch (grp) {
          'BT1' => Colors.blue,
          'BT2' => Colors.green,
          'BT3' => Colors.grey,
          _ => Colors.purple,
        };
        return isHighlighted ? base.shade900 : base.shade800;
      case ObjectType.mountain:
        return isHighlighted ? Colors.brown.shade600 : Colors.brown.shade500;
      case ObjectType.lake:
        return isHighlighted
            ? Colors.lightBlue.shade600
            : Colors.lightBlue.shade400;
      case ObjectType.allianceNode:
        return isHighlighted ? Colors.amber.shade700 : Colors.amber.shade600;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Base grid diamonds
    if (drawGrid) {
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
    }

    // Axis labels for flipped projection – still show raw game coordinates.
    if (showCoordinates) {
      // Top axis: X increases to the right (original orientation)
      for (int col = 0; col < gridW; col++) {
        final xVal = originGameX + col;
        _drawLabel(
          canvas,
          col,
          0,
          'X=$xVal',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
          offset: const Offset(0, -18),
          backgroundColor: Colors.white.withOpacity(0.75),
        );
      }
      // Left axis: Y increases downward (original orientation)
      for (int row = 0; row < gridH; row++) {
        final yVal = originGameY + row;
        _drawLabel(
          canvas,
          0,
          row,
          'Y=$yVal',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
          offset: const Offset(-46, 0),
          backgroundColor: Colors.white.withOpacity(0.75),
          maxWidth: 60,
        );
      }
    }

    // Draw immutable permanent structures first (below user objects)
    if (!arePermanentsHidden()) {
      final permanents = getPermanentStructures();
      PermanentStructure? castle;
      for (final p in permanents) {
        if (p.name.toLowerCase().contains('castle')) {
          castle = p;
          break;
        }
      }
      for (final ps in permanents) {
        // Optional influence zone (non-blocking, very light)
        if (ps.influenceR != null && ps.influenceTopLeft != null) {
          final iw = ps.influenceWidth!;
          final ih = ps.influenceHeight!;
          final (itx, ity) = ps.influenceTopLeft!;
          final fill = const Color(0xFF3B82F6).withOpacity(0.04); // blue-500
          final stroke = const Color(0xFF3B82F6).withOpacity(0.10);
          for (int dy = 0; dy < ih; dy++) {
            for (int dx = 0; dx < iw; dx++) {
              final gx = itx + dx;
              final gy = ity + dy;
              final tx = gx - originGameX;
              final ty = gy - originGameY;
              if (tx < 0 || ty < 0 || tx >= gridW || ty >= gridH) continue;
              _drawTile(
                canvas,
                tx,
                ty,
                fill: fill,
                stroke: (dx == 0 || dy == 0 || dx == iw - 1 || dy == ih - 1)
                    ? stroke
                    : null,
              );
            }
          }
        }
        final (ftx, fty) = ps.footprintTopLeft;
        // Choose footprint color by structure kind (by name)
        final lname = ps.name.toLowerCase();
        final bool isCastle = lname.contains('castle');
        final bool isTurret = lname.contains('turret');
        final Color baseFill = isCastle
            ? Colors.red.shade600
            : (isTurret ? Colors.green.shade600 : const Color(0xFF334155));
        final Color baseStroke = isCastle
            ? Colors.red.shade900
            : (isTurret ? Colors.green.shade900 : const Color(0xFF0F172A));
        // Draw footprint tiles if within viewport
        for (int dy = 0; dy < ps.h; dy++) {
          for (int dx = 0; dx < ps.w; dx++) {
            final gx = ftx + dx;
            final gy = fty + dy;
            final tx = gx - originGameX;
            final ty = gy - originGameY;
            if (tx < 0 || ty < 0 || tx >= gridW || ty >= gridH) continue;
            _drawTile(
              canvas,
              tx,
              ty,
              fill: baseFill.withOpacity(0.85),
              stroke: baseStroke.withOpacity(0.35),
            );
          }
        }

        // Highlight the raw anchor (bottom-right of footprint) explicitly
        final avx = ps.ax - originGameX;
        final avy = ps.ay - originGameY;
        if (avx >= 0 && avy >= 0 && avx < gridW && avy < gridH) {
          canvas.drawPath(
            _diamondPathAt(avx, avy),
            Paint()
              ..color = Colors.orange.withOpacity(0.95)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2,
          );
        }

        // Draw optional exclusion zone highlight using radius -> width formula
        final ew = ps.exclusionWidth;
        final eh = ps.exclusionHeight;
        final (etx, ety) = ps.exclusionTopLeft;
        if (ew > 0 && eh > 0) {
          final areaFill = const Color(0xFFEF4444).withOpacity(0.06); // red-500
          final areaStroke = const Color(0xFFEF4444).withOpacity(0.15);
          final borderStroke = const Color(
            0xFFDC2626,
          ).withOpacity(0.85); // red-600
          for (int dy = 0; dy < eh; dy++) {
            for (int dx = 0; dx < ew; dx++) {
              final gx = etx + dx;
              final gy = ety + dy;
              final tx = gx - originGameX;
              final ty = gy - originGameY;
              if (tx < 0 || ty < 0 || tx >= gridW || ty >= gridH) continue;
              final isBorder =
                  dx == 0 || dy == 0 || dx == ew - 1 || dy == eh - 1;
              _drawTile(
                canvas,
                tx,
                ty,
                fill: areaFill,
                stroke: isBorder ? borderStroke : areaStroke,
              );
            }
          }
        }

        // Label at center if visible (map turret names by camera view)
        final atx = ps.cx - originGameX;
        final aty = ps.cy - originGameY;
        if (atx >= 0 && aty >= 0 && atx < gridW && aty < gridH) {
          // Permanent structures are already defined in absolute game coordinates
          // Just use them directly - no transformation needed
          final centerAxisX = ps.cx;
          final centerAxisY = ps.cy;
          final anchorX = ps.ax;
          final anchorY = ps.ay;
          // Footprint corners in game coordinates
          final (tlx, tly) = ps.footprintTopLeft;
          final brx = ps.ax;
          final bry = ps.ay;
          String labelText = ps.name;
          final lname2 = ps.name.toLowerCase();
          if (lname2.contains('turret') && castle != null) {
            final dx = ps.cx - castle.cx;
            final dy = ps.cy - castle.cy;
            // Align names with in-game references:
            // Southwing is (-X,-Y), Northground is (+X,+Y)
            if (dx > 0 && dy > 0) {
              labelText = 'Northground Turret'; // (+X,+Y)
            } else if (dx < 0 && dy < 0) {
              labelText = 'Southwing Turret'; // (-X,-Y)
            } else if (dx > 0 && dy < 0) {
              labelText = 'Eastcourt Turret'; // (+X,-Y)
            } else if (dx < 0 && dy > 0) {
              labelText = 'Westplain Turret'; // (-X,+Y)
            } else {
              labelText = 'Turret';
            }
          }
          // Append both anchor and center coordinates for clarity
          labelText +=
              '\nCenter X=$centerAxisX Y=$centerAxisY'
              '\nAnchor X=$anchorX Y=$anchorY'
              '\nTL($tlx,$tly) BR($brx,$bry)';
          // Determine appearance and offset to reduce overlap for ALL permanents
          final isCastleLabel = lname2.contains('castle');
          final isTurretLabel = lname2.contains('turret');

          // Radial screen-space offset away from the castle to avoid overlap.
          // Works for turrets and any other permanent, not just vertical.
          Offset radialOffset = Offset.zero;
          if (castle != null && !isCastleLabel) {
            final dxTiles = ps.cx - castle.cx;
            final dyTiles = ps.cy - castle.cy;
            // Convert tile delta to isometric screen delta
            final screenDx = (dxTiles - dyTiles) * halfW;
            final screenDy = (dxTiles + dyTiles) * halfH;
            final mag = math.sqrt(screenDx * screenDx + screenDy * screenDy);
            if (mag > 0) {
              const double d = 18.0; // pixel push distance
              final scale = d / mag;
              radialOffset = Offset(screenDx * scale, screenDy * scale);
            } else {
              // Same tile as castle? Nudge upward a bit.
              radialOffset = const Offset(0, -18);
            }
          }
          final textColor = isCastleLabel
              ? Colors.red.shade900
              : (isTurretLabel ? Colors.green.shade900 : Colors.black);
          _drawLabel(
            canvas,
            atx,
            aty,
            labelText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            backgroundColor: Colors.white.withOpacity(0.82),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            offset: radialOffset,
            maxWidth: 180,
            borderRadius: 6,
          );
          // Draw a small center marker cross for debug
          final top = _tileTop(atx, aty).translate(0, tileH * 0.55);
          canvas.drawLine(
            top.translate(-6, 0),
            top.translate(6, 0),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 2,
          );
          canvas.drawLine(
            top.translate(0, -6),
            top.translate(0, 6),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 2,
          );
        }
      }
    }

    // Draw placed objects as isometric blocks by filling their footprint
    for (int i = 0; i < objects.length; i++) {
      final obj = objects[i];
      final f = footprintFor(obj.type);
      final tl = centerToTopLeft(obj.type, obj.gameX, obj.gameY);
      final isHighlighted = highlightedIndex != null && highlightedIndex == i;
      final color = _colorForObject(obj, isHighlighted);
      for (int dy = 0; dy < f.h; dy++) {
        for (int dx = 0; dx < f.w; dx++) {
          // Convert game cell to window-relative grid index
          final tx = (tl.x + dx) - originGameX;
          final ty = (tl.y + dy) - originGameY;
          if (tx < 0 || ty < 0 || tx >= gridW || ty >= gridH) continue;
          _drawTile(
            canvas,
            tx,
            ty,
            fill: isHighlighted
                ? color.withOpacity(0.65)
                : color.withOpacity(0.9),
          );
          canvas.drawPath(
            _diamondPathAt(tx, ty),
            Paint()
              ..color = Colors.black.withOpacity(isHighlighted ? 0.45 : 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = isHighlighted ? 1.6 : 1.2,
          );
        }
      }

      // Draw short label near the object's anchor tile
      final anchorGameX = tl.x + (f.w - 1) ~/ 2;
      final anchorGameY = tl.y + (f.h - 1) ~/ 2;
      final atx = anchorGameX - originGameX;
      final aty = anchorGameY - originGameY;
      if (atx >= 0 && aty >= 0 && atx < gridW && aty < gridH) {
        if (obj.type == ObjectType.member) {
          final grp = _btGroupFor(obj) ?? '';
          String display;
          if ((obj.memberName ?? '').isNotEmpty) {
            display = obj.memberName!;
          } else if (obj.rank != null) {
            display = 'Rank ${obj.rank}';
          } else {
            display = _labelFor(obj);
          }
          _drawMemberLabel(canvas, atx, aty, display, grp);
        } else {
          _drawLabel(
            canvas,
            atx,
            aty,
            _labelFor(obj),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          );
        }
      }

      // If it's a Flag, also draw a 7x7 area highlight centered on the flag
      if (obj.type == ObjectType.flag && !hideRadius) {
        // 7x7 area => radius 3 in both directions around the center cell
        const r = 3;
        final centerGX = obj.gameX;
        final centerGY = obj.gameY;
        final areaFill = Colors.indigoAccent.withOpacity(0.10);
        final areaStroke = Colors.indigo.withOpacity(0.20);
        for (int ddy = -r; ddy <= r; ddy++) {
          for (int ddx = -r; ddx <= r; ddx++) {
            final ax = centerGX + ddx;
            final ay = centerGY + ddy;
            // Convert to viewport indices
            final vx = ax - originGameX;
            final vy = ay - originGameY;
            if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
            _drawTile(canvas, vx, vy, fill: areaFill, stroke: areaStroke);
          }
        }
      }

      // If it's an HQ, also draw a 15x15 area highlight centered on the HQ
      if (obj.type == ObjectType.hq && !hideRadius) {
        // 15x15 area => radius 7 in both directions around the center cell
        const r = 7;
        final centerGX = obj.gameX;
        final centerGY = obj.gameY;
        final areaFill = Colors.redAccent.withOpacity(0.08);
        final areaStroke = Colors.red.withOpacity(0.15);
        for (int ddy = -r; ddy <= r; ddy++) {
          for (int ddx = -r; ddx <= r; ddx++) {
            final ax = centerGX + ddx;
            final ay = centerGY + ddy;
            // Convert to viewport indices
            final vx = ax - originGameX;
            final vy = ay - originGameY;
            if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
            _drawTile(canvas, vx, vy, fill: areaFill, stroke: areaStroke);
          }
        }
      }
    }

    // Hover shadow preview
    if (hoverGameX != null && hoverGameY != null && hoverObjectType != null) {
      final centerGX = hoverGameX!;
      final centerGY = hoverGameY!;
      final type = hoverObjectType!;

      // Get the actual footprint for the object type
      final footprint = footprintFor(type);
      final topLeft = centerToTopLeft(type, centerGX, centerGY);

      final areaFill = type == ObjectType.member
          ? Colors.green.withOpacity(0.15)
          : Colors.blue.withOpacity(0.15);
      final areaStroke = type == ObjectType.member
          ? Colors.green.withOpacity(0.4)
          : Colors.blue.withOpacity(0.4);

      // Draw all tiles in the footprint
      for (int dy = 0; dy < footprint.h; dy++) {
        for (int dx = 0; dx < footprint.w; dx++) {
          final ax = topLeft.x + dx;
          final ay = topLeft.y + dy;
          // Convert to viewport indices
          final vx = ax - originGameX;
          final vy = ay - originGameY;
          if (vx < 0 || vy < 0 || vx >= gridW || vy >= gridH) continue;
          _drawTile(canvas, vx, vy, fill: areaFill, stroke: areaStroke);
        }
      }
    } // Crosshair and selected tile highlight
    if (selectedTileGameX != null && selectedTileGameY != null) {
      final tx = selectedTileGameX! - originGameX;
      final ty = selectedTileGameY! - originGameY;
      if (tx >= 0 && ty >= 0 && tx < gridW && ty < gridH) {
        // Highlight selected tile
        _drawTile(
          canvas,
          tx,
          ty,
          fill: Colors.yellow.withOpacity(0.18),
          stroke: Colors.orange.withOpacity(0.8),
        );
        if (showSelectedTileCoordinates) {
          // Show the raw game coordinates - selectedTileGameX/Y are already absolute
          _drawLabel(
            canvas,
            tx,
            ty,
            'X=$selectedTileGameX Y=$selectedTileGameY',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            backgroundColor: Colors.white.withOpacity(0.82),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            maxWidth: 120,
            borderRadius: 6,
          );
        }
        if (showCoordinates && showCrosshair) {
          // Crosshair lines following isometric grid orientation - full grid
          final paint = Paint()
            ..color = Colors.red.withOpacity(0.6)
            ..strokeWidth = 4;

          // Calculate the full grid bounds for crosshair
          final gridCenterX = originX + (gridW / 2 - gridH / 2) * halfW;
          final gridCenterY = (gridW / 2 + gridH / 2) * halfH;
          final gridExtent = (gridW + gridH) * halfW;

          // Diagonal line from top-left to bottom-right (grid-aligned)
          canvas.drawLine(
            Offset(gridCenterX - gridExtent, gridCenterY - gridExtent / 2),
            Offset(gridCenterX + gridExtent, gridCenterY + gridExtent / 2),
            paint,
          );

          // Diagonal line from top-right to bottom-left (grid-aligned)
          canvas.drawLine(
            Offset(gridCenterX + gridExtent, gridCenterY - gridExtent / 2),
            Offset(gridCenterX - gridExtent, gridCenterY + gridExtent / 2),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return gridW != oldDelegate.gridW ||
        gridH != oldDelegate.gridH ||
        drawGrid != oldDelegate.drawGrid ||
        showCoordinates != oldDelegate.showCoordinates ||
        showBuildingCoordinates != oldDelegate.showBuildingCoordinates ||
        highlightedIndex != oldDelegate.highlightedIndex ||
        objects != oldDelegate.objects ||
        originX != oldDelegate.originX ||
        originGameX != oldDelegate.originGameX ||
        originGameY != oldDelegate.originGameY ||
        selectedTileGameX != oldDelegate.selectedTileGameX ||
        selectedTileGameY != oldDelegate.selectedTileGameY ||
        hoverGameX != oldDelegate.hoverGameX ||
        hoverGameY != oldDelegate.hoverGameY ||
        hoverObjectType != oldDelegate.hoverObjectType;
  }
}
