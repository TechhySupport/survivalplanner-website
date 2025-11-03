import 'package:flutter/material.dart';

import 'models.dart';
import 'placement_rules.dart';

class GridRenderer extends StatelessWidget {
  final int gridW;
  final int gridH;
  final List<GridObject> objects;
  final int? highlightedIndex; // optional object index to emphasize
  final bool drawGrid;
  final bool showCoordinates; // render game coord labels on tiles if true
  final int originGameX;
  final int originGameY;
  final int?
  selectedTileGameX; // selected tile (game coord) for crosshair/highlight
  final int? selectedTileGameY;

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
    this.selectedTileGameX,
    this.selectedTileGameY,
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
          originX: originX,
          originGameX: originGameX,
          originGameY: originGameY,
          selectedTileGameX: selectedTileGameX,
          selectedTileGameY: selectedTileGameY,
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
  final double originX;
  final int originGameX;
  final int originGameY;
  final int? selectedTileGameX;
  final int? selectedTileGameY;

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
    required this.originX,
    required this.originGameX,
    required this.originGameY,
    required this.selectedTileGameX,
    required this.selectedTileGameY,
  });

  // Map an object to its short label
  String _labelFor(GridObject obj) {
    switch (obj.type) {
      case ObjectType.flag:
        return 'F';
      case ObjectType.bearTrap:
        // Expect obj.name like BT1/BT2/BT3; fallback to BT
        return (obj.name.isNotEmpty) ? obj.name : 'BT';
      case ObjectType.hq:
        return 'Bq';
      case ObjectType.member:
        // For members, show the assigned memberName if available; otherwise compact MBx
        if ((obj.memberName ?? '').isNotEmpty) return obj.memberName!;
        if (obj.name.contains('BT1') || (obj.memberGroup ?? '').contains('BT1'))
          return 'MB1';
        if (obj.name.contains('BT2') || (obj.memberGroup ?? '').contains('BT2'))
          return 'MB2';
        if (obj.name.contains('BT3') || (obj.memberGroup ?? '').contains('BT3'))
          return 'MB3';
        return 'MB';
      case ObjectType.mountain:
        return 'M';
      case ObjectType.lake:
        return 'L';
      case ObjectType.allianceNode:
        return 'AN';
    }
  }

  Offset _tileTop(int x, int y) {
    final sx = originX + (x - y) * halfW;
    final sy = (x + y) * halfH;
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
  }) {
    final top = _tileTop(x, y);
    final center = top.translate(0, tileH * 0.55);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
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

    // Axis labels around the map (top and left edges)
    if (showCoordinates) {
      // Top axis: label each visible column with X value only
      for (int x = 0; x < gridW; x++) {
        final top = _tileTop(x, 0);
        final gx = originGameX + x;
        final tp = TextPainter(
          text: TextSpan(
            text: 'X=$gx',
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 100);
        final pos = Offset(
          top.dx - tp.width / 2,
          (top.dy - 14).clamp(0, size.height),
        );
        tp.paint(canvas, pos);
      }
      // Left axis: label each visible row with Y value only
      for (int y = 0; y < gridH; y++) {
        final topLeft = _tileTop(0, y);
        final gy = originGameY + y;
        final tp = TextPainter(
          text: TextSpan(
            text: 'Y=$gy',
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 100);
        final dx = (topLeft.dx - halfW - 8 - tp.width).clamp(
          0.0,
          size.width - tp.width,
        );
        final dy = (topLeft.dy + halfH - tp.height / 2).clamp(
          0.0,
          size.height - tp.height,
        );
        tp.paint(canvas, Offset(dx, dy));
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
          final display = (obj.memberName ?? '').isNotEmpty
              ? obj.memberName!
              : _labelFor(obj);
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
      if (obj.type == ObjectType.flag) {
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
    }

    // Crosshair and selected tile highlight
    if (selectedTileGameX != null && selectedTileGameY != null) {
      final tx = selectedTileGameX! - originGameX;
      final ty = selectedTileGameY! - originGameY;
      if (tx >= 0 && ty >= 0 && tx < gridW && ty < gridH) {
        final top = _tileTop(tx, ty);
        final center = top.translate(0, tileH * 0.5);
        // Highlight selected tile
        _drawTile(
          canvas,
          tx,
          ty,
          fill: Colors.yellow.withOpacity(0.18),
          stroke: Colors.orange.withOpacity(0.8),
        );
        if (showCoordinates) {
          // Crosshair lines across viewport
          final paint = Paint()
            ..color = Colors.black.withOpacity(0.25)
            ..strokeWidth = 1;
          canvas.drawLine(
            Offset(0, center.dy),
            Offset(size.width, center.dy),
            paint,
          );
          canvas.drawLine(
            Offset(center.dx, 0),
            Offset(center.dx, size.height),
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
        highlightedIndex != oldDelegate.highlightedIndex ||
        objects != oldDelegate.objects ||
        originX != oldDelegate.originX ||
        originGameX != oldDelegate.originGameX ||
        originGameY != oldDelegate.originGameY ||
        selectedTileGameX != oldDelegate.selectedTileGameX ||
        selectedTileGameY != oldDelegate.selectedTileGameY;
  }
}
