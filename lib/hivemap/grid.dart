import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'models.dart';

class IsometricGridPainter extends CustomPainter {
  final int maxCoord = 1200;
  final int viewportSize; // How many cells to show (15, 30, or 50)
  final double scale; // Additional zoom level
  final Offset panOffset; // Pan offset
  final List<MapObject> objects; // Objects placed on the map
  final int centerX; // Center X coordinate (e.g., 600)
  final int centerY; // Center Y coordinate (e.g., 600)

  IsometricGridPainter({
    required this.viewportSize,
    required this.scale,
    required this.panOffset,
    required this.objects,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Calculate scale based on viewportSize
    // viewportSize controls how much of the map is visible
    // 15 = zoomed in (only see 15x15 portion of the 1200x1200 map)
    // 50 = zoomed out (see 50x50 portion of the 1200x1200 map)
    // The key is to scale based on viewportSize, not maxCoord
    final baseScale = (min(size.width, size.height) * 0.8) / (viewportSize * 2);
    final finalScale = baseScale * scale;

    // Grid spacing - 1 unit per tile (each grid square = 1x1 tile)
    final gridSpacing = 1;

    // Convert logical coordinates to screen coordinates
    // Target: (0,0)=bottom, (1199,1199)=top, (0,1199)=left, (1199,0)=right
    Offset logicalToScreen(int x, int y) {
      // Offset coordinates relative to current center
      final relX = x - centerX;
      final relY = y - centerY;

      // Apply isometric projection (relative to center)
      final screenX =
          -(relY - relX) * finalScale * 0.5 + size.width / 2 + panOffset.dx;
      final screenY =
          -(relY + relX) * finalScale * 0.25 + size.height / 2 + panOffset.dy;
      return Offset(screenX, screenY);
    }

    // ONLY draw grid lines within viewport range!
    // Calculate the visible range based on center coordinate and viewport size
    final halfViewport = viewportSize ~/ 2;
    final minX = (this.centerX - halfViewport).clamp(0, maxCoord);
    final maxX = (this.centerX + halfViewport).clamp(0, maxCoord);
    final minY = (this.centerY - halfViewport).clamp(0, maxCoord);
    final maxY = (this.centerY + halfViewport).clamp(0, maxCoord);

    // Draw vertical lines (constant x) - ONLY in visible range
    for (int x = minX; x <= maxX; x += gridSpacing) {
      final start = logicalToScreen(x, minY);
      final end = logicalToScreen(x, maxY);
      canvas.drawLine(start, end, paint);
    }

    // Draw horizontal lines (constant y) - ONLY in visible range
    for (int y = minY; y <= maxY; y += gridSpacing) {
      final start = logicalToScreen(minX, y);
      final end = logicalToScreen(maxX, y);
      canvas.drawLine(start, end, paint);
    }

    // Draw placed objects
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final obj in objects) {
      // Draw building covering multiple tiles
      final width = obj.tileWidth;
      final height = obj.tileHeight;

      // Skip buildings outside the visible viewport
      if (obj.x + width < minX ||
          obj.x > maxX ||
          obj.y + height < minY ||
          obj.y > maxY) {
        continue;
      }

      // Get the four corners of the building footprint
      final topLeft = logicalToScreen(obj.x, obj.y + height);
      final topRight = logicalToScreen(obj.x + width, obj.y + height);
      final bottomRight = logicalToScreen(obj.x + width, obj.y);
      final bottomLeft = logicalToScreen(obj.x, obj.y);

      // Draw filled polygon for building footprint
      final path = Path()
        ..moveTo(topLeft.dx, topLeft.dy)
        ..lineTo(topRight.dx, topRight.dy)
        ..lineTo(bottomRight.dx, bottomRight.dy)
        ..lineTo(bottomLeft.dx, bottomLeft.dy)
        ..close();

      final objPaint = Paint()
        ..color = obj.color.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, objPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // Draw object label at center
      final centerPos = logicalToScreen(
        obj.x + (width ~/ 2),
        obj.y + (height ~/ 2),
      );

      textPainter.text = TextSpan(
        text: obj.displayName,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white70,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        centerPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) {
    return oldDelegate.viewportSize != viewportSize ||
        oldDelegate.scale != scale ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.objects != objects ||
        oldDelegate.centerX != centerX ||
        oldDelegate.centerY != centerY;
  }
}

class IsometricGridWidget extends StatefulWidget {
  final int viewportSize;
  final double scale;
  final Offset panOffset;
  final ValueChanged<Offset> onPanUpdate;
  final ValueChanged<double> onScaleChanged;
  final List<MapObject> objects;
  final BuildingType? selectedBuildingType;
  final ValueChanged<MapObject> onObjectPlaced;
  final bool isSelectMode;
  final ValueChanged<String>? onHoverCoordinates;
  final int centerX;
  final int centerY;

  const IsometricGridWidget({
    super.key,
    required this.viewportSize,
    required this.scale,
    required this.panOffset,
    required this.onPanUpdate,
    required this.onScaleChanged,
    required this.objects,
    this.selectedBuildingType,
    required this.onObjectPlaced,
    required this.isSelectMode,
    this.onHoverCoordinates,
    required this.centerX,
    required this.centerY,
  });

  @override
  State<IsometricGridWidget> createState() => _IsometricGridWidgetState();
}

class _IsometricGridWidgetState extends State<IsometricGridWidget> {
  // Convert screen coordinates back to logical coordinates
  Offset screenToLogical(Offset screenPos, Size size) {
    final screenCenterX = size.width / 2;
    final screenCenterY = size.height / 2;
    final baseScale =
        (min(size.width, size.height) * 0.8) / (widget.viewportSize * 2);
    final finalScale = baseScale * widget.scale;

    // Reverse the isometric projection
    // Forward: screenX = -(relY - relX) * finalScale * 0.5 + screenCenterX + panOffset.dx
    // Forward: screenY = -(relY + relX) * finalScale * 0.25 + screenCenterY + panOffset.dy
    final offsetX = screenPos.dx - screenCenterX - widget.panOffset.dx;
    final offsetY = screenPos.dy - screenCenterY - widget.panOffset.dy;

    // Solve for relX and relY:
    // offsetX = -(relY - relX) * finalScale * 0.5
    // offsetY = -(relY + relX) * finalScale * 0.25
    final isoX = -offsetX / (finalScale * 0.5); // isoX = relY - relX
    final isoY = -offsetY / (finalScale * 0.25); // isoY = relY + relX

    // Solve: relY - relX = isoX and relY + relX = isoY
    // Adding: 2*relY = isoX + isoY => relY = (isoX + isoY) / 2
    // Subtracting: -2*relX = isoX - isoY => relX = (isoY - isoX) / 2
    final relY = (isoX + isoY) / 2;
    final relX = (isoY - isoX) / 2;

    // Convert back to absolute coordinates
    final x = relX + widget.centerX;
    final y = relY + widget.centerY;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (widget.isSelectMode && widget.onHoverCoordinates != null) {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPos = renderBox.globalToLocal(event.position);
          final logicalPos = screenToLogical(localPos, renderBox.size);

          final x = logicalPos.dx.round().clamp(0, 1199);
          final y = logicalPos.dy.round().clamp(0, 1199);

          widget.onHoverCoordinates!('($x, $y)');
        }
      },
      onExit: (event) {
        if (widget.onHoverCoordinates != null) {
          widget.onHoverCoordinates!('');
        }
      },
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final delta = event.scrollDelta.dy;
            final newScale = (widget.scale * (1 - delta * 0.001)).clamp(
              10.0,
              20.0,
            );
            widget.onScaleChanged(newScale);
          }
        },
        onPointerDown: (event) {
          // Only allow placement if a building type is selected and not in select mode
          if (!widget.isSelectMode && widget.selectedBuildingType != null) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(event.position);
            final logicalPos = screenToLogical(localPos, renderBox.size);

            final x = logicalPos.dx.round().clamp(0, 1199);
            final y = logicalPos.dy.round().clamp(0, 1199);

            final newObject = MapObject(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: widget.selectedBuildingType!,
              x: x,
              y: y,
            );

            widget.onObjectPlaced(newObject);
          }
        },
        child: GestureDetector(
          onPanUpdate: (details) {
            // Increase pan sensitivity by 2x for faster dragging
            widget.onPanUpdate(widget.panOffset + (details.delta * 5.0));
          },
          child: CustomPaint(
            painter: IsometricGridPainter(
              viewportSize: widget.viewportSize,
              scale: widget.scale,
              panOffset: widget.panOffset,
              objects: widget.objects,
              centerX: widget.centerX,
              centerY: widget.centerY,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}
