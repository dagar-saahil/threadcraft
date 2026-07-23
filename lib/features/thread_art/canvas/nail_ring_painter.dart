import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NailRingPainter extends CustomPainter {
  final int nailCount;
  final List<int> completedPath;
  final int currentNail;
  final int nextNail;
  final ui.Image? backgroundImage;
  final String shape;
  final bool showBackground;   // ← NEW
  final bool useColorThread;   // ← NEW
  final Color? singleThreadColor;
  NailRingPainter({
    required this.nailCount,
    required this.completedPath,
    required this.currentNail,
    required this.nextNail,
    this.backgroundImage,
    this.shape = 'Circle',
    this.showBackground = true,   // ← NEW
    this.useColorThread = true,   // ← NEW
    this.singleThreadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── Draw background ──
    if (showBackground && backgroundImage != null) {
      // Show photo
      final src = Rect.fromLTWH(
        0, 0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      );
      canvas.drawImageRect(backgroundImage!, src, dst, Paint());
      // Darker overlay ensures additive blending has room to accumulate
// Without this, additive threads saturate too quickly on bright areas
      canvas.drawRect(
        dst,
        Paint()..color = Colors.black.withOpacity(0.62),
      );
    } else {
      // White/clean background (no photo)
      canvas.drawRect(dst, Paint()..color = const Color(0xFFF5F5F5));
    }

    // ── Get nail positions based on shape ──
    final nails = _getNailPositions(size);

    // ── Draw shape outline ──
    _drawShapeOutline(canvas, size);

    // ── Draw completed thread lines ──
    _drawThreadLines(canvas, nails);

    // ── Draw all nails + numbers ──
    for (int i = 0; i < nails.length; i++) {
      _drawNail(canvas, nails[i], i, size);
    }

    // ── Highlight next nail ──
    if (nextNail < nails.length) {
      _drawHighlightedNail(
          canvas, nails[nextNail], nextNail, AppColors.purple, size);
    }

    // ── Highlight current nail ──
    if (currentNail < nails.length) {
      _drawHighlightedNail(
          canvas, nails[currentNail], currentNail, AppColors.orange, size);
    }
  }

  // ── GET NAIL POSITIONS BASED ON SHAPE ──
  List<Offset> _getNailPositions(Size size) {
    switch (shape) {
      case 'Square':
        return _squareNails(size);
      case 'Rectangle':
        return _rectangleNails(size);
      default:
        return _circleNails(size);
    }
  }

  // ── CIRCLE nails ──
  List<Offset> _circleNails(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - 22;
    return List.generate(nailCount, (i) {
      final angle = (2 * pi * i / nailCount) - (pi / 2);
      return Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    });
  }

  // ── SQUARE nails ──
  List<Offset> _squareNails(Size size) {
    final nails = <Offset>[];
    const padding = 24.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    final perSide = nailCount ~/ 4;
    final extra = nailCount - perSide * 4;

    // Top
    for (int i = 0; i < perSide; i++) {
      nails.add(Offset(padding + w * i / perSide, padding));
    }
    // Right
    for (int i = 0; i < perSide; i++) {
      nails.add(Offset(size.width - padding, padding + h * i / perSide));
    }
    // Bottom
    for (int i = 0; i < perSide; i++) {
      nails.add(Offset(
          size.width - padding - w * i / perSide, size.height - padding));
    }
    // Left
    final leftCount = perSide + extra;
    for (int i = 0; i < leftCount; i++) {
      nails.add(Offset(
          padding, size.height - padding - h * i / max(leftCount - 1, 1)));
    }
    return nails.take(nailCount).toList();
  }

  // ── RECTANGLE nails ──
  List<Offset> _rectangleNails(Size size) {
    final nails = <Offset>[];
    const padding = 24.0;
    final w = size.width - padding * 2;
    final rh = size.height * 0.6; // 60% height
    final offsetY = (size.height - rh) / 2;
    final perimeter = 2 * w + 2 * rh;

    final topCount = (nailCount * w / perimeter).round();
    final sideCount = (nailCount * rh / perimeter).round();

    // Top
    for (int i = 0; i < topCount; i++) {
      nails.add(Offset(padding + w * i / max(topCount - 1, 1), offsetY));
    }
    // Right
    for (int i = 0; i < sideCount; i++) {
      nails.add(Offset(
          size.width - padding, offsetY + rh * i / max(sideCount - 1, 1)));
    }
    // Bottom
    for (int i = 0; i < topCount; i++) {
      nails.add(Offset(
          size.width - padding - w * i / max(topCount - 1, 1),
          offsetY + rh));
    }
    // Left
    final leftCount = nailCount - nails.length;
    for (int i = 0; i < leftCount; i++) {
      nails.add(Offset(
          padding,
          offsetY + rh - rh * i / max(leftCount - 1, 1)));
    }
    return nails.take(nailCount).toList();
  }

  // ── DRAW SHAPE OUTLINE ──
  void _drawShapeOutline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const padding = 24.0;

    switch (shape) {
      case 'Square':
        canvas.drawRect(
          Rect.fromLTWH(
              padding, padding,
              size.width - padding * 2,
              size.height - padding * 2),
          paint,
        );
        break;
      case 'Rectangle':
        final rh = size.height * 0.6;
        final offsetY = (size.height - rh) / 2;
        canvas.drawRect(
          Rect.fromLTWH(padding, offsetY,
              size.width - padding * 2, rh),
          paint,
        );
        break;
      default:
        final center = Offset(size.width / 2, size.height / 2);
        final radius = (min(size.width, size.height) / 2) - padding;
        canvas.drawCircle(center, radius, paint);
    }
  }

  // ── DRAW THREAD LINES ──
  void _drawThreadLines(Canvas canvas, List<Offset> nails) {
    if (completedPath.length < 2) return;

    final colors = [
      AppColors.purple,
      AppColors.pink,
      AppColors.orange,
      AppColors.cyan,
    ];

    for (int i = 0; i < completedPath.length - 1; i++) {
      final from = completedPath[i];
      final to = completedPath[i + 1];
      if (from >= nails.length || to >= nails.length) continue;

      // ── Black thread or colorful ──
      final threadColor = useColorThread
          ? colors[i % colors.length].withOpacity(0.4)
          : (singleThreadColor ?? Colors.white)
          .withOpacity(
        showBackground ? 0.6 : 0.75,
      );

      canvas.drawLine(
        nails[from],
        nails[to],
        Paint()
          ..color = threadColor
          ..strokeWidth = useColorThread ? 0.7 : 0.8,
      );
    }
  }

  // ── DRAW NAIL DOT + NUMBER (FIXED: numbers stay inside) ──
  void _drawNail(Canvas canvas, Offset pos, int index, Size size) {
    // ── Nail dot ──
    canvas.drawCircle(
      pos,
      2.5,
      Paint()..color = showBackground
          ? Colors.white.withOpacity(0.6)
          : Colors.black.withOpacity(0.5),
    );

    // Only show number every 10th nail
    if (index % 10 != 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Direction FROM center TOWARD nail (outward)
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final length = (dx * dx + dy * dy) == 0
        ? 1.0
        : (dx * dx + dy * dy) * 0.5; // sqrt approximation
    final dist = (dx * dx + dy * dy) == 0
        ? 1.0
        : (dx * dx + dy * dy);
    final actualLen = dist == 0 ? 1.0 : sqrt(dist);

    // Normalize direction
    final nx = dx / actualLen;
    final ny = dy / actualLen;

    // Place label 13px OUTSIDE the nail
    final labelX = pos.dx + nx * 13;
    final labelY = pos.dy + ny * 13;

    // Text color: white on dark bg, dark on white bg
    final textColor = showBackground
        ? Colors.white.withOpacity(0.75)
        : Colors.black.withOpacity(0.7);

    final tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',   // ← starts from 1
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Clamp so number never goes outside canvas edges
    final drawX = (labelX - tp.width / 2)
        .clamp(1.0, size.width - tp.width - 1);
    final drawY = (labelY - tp.height / 2)
        .clamp(1.0, size.height - tp.height - 1);

    tp.paint(canvas, Offset(drawX, drawY));
  }

  // ── DRAW HIGHLIGHTED NAIL ──
  void _drawHighlightedNail(
      Canvas canvas, Offset pos, int index, Color color, Size size,
      ) {
    // Glow rings
    canvas.drawCircle(pos, 14,
        Paint()..color = color.withOpacity(0.15));
    canvas.drawCircle(pos, 9,
        Paint()..color = color.withOpacity(0.3));

    // Core dot
    canvas.drawCircle(pos, 5, Paint()..color = color);

    final center = Offset(size.width / 2, size.height / 2);

    // Direction outward from center
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final actualLen = sqrt(dx * dx + dy * dy);
    if (actualLen == 0) return;

    final nx = dx / actualLen;
    final ny = dy / actualLen;

    // Place label 18px OUTSIDE nail (slightly more than regular)
    final labelX = pos.dx + nx * 18;
    final labelY = pos.dy + ny * 18;

    final tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',   // ← starts from 1
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: color.withOpacity(0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Clamp inside canvas
    final drawX = (labelX - tp.width / 2)
        .clamp(1.0, size.width - tp.width - 1);
    final drawY = (labelY - tp.height / 2)
        .clamp(1.0, size.height - tp.height - 1);

    tp.paint(canvas, Offset(drawX, drawY));
  }

  @override
  bool shouldRepaint(NailRingPainter old) =>
      old.currentNail != currentNail ||
          old.nextNail != nextNail ||
          old.completedPath.length != completedPath.length ||
          old.shape != shape ||
          old.showBackground != showBackground ||
          old.useColorThread != useColorThread ||
          old.singleThreadColor != singleThreadColor;

}