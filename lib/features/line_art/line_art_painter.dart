import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LineArtPainter extends CustomPainter {
  final int nailCount;
  final String shape;
  final List<int> completedPath;
  final int currentNail;
  final int nextNail;
  final ui.Image? backgroundImage;
  final bool showBackground;

  const LineArtPainter({
    required this.nailCount,
    required this.shape,
    required this.completedPath,
    required this.currentNail,
    required this.nextNail,
    this.backgroundImage,
    this.showBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    if (showBackground && backgroundImage != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      );
      final dst =
      Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(
          backgroundImage!, src, dst, Paint());
      // Lighter overlay for line art — keeps image visible
      canvas.drawRect(
        dst,
        Paint()..color = Colors.black.withOpacity(0.35),
      );
    } else {
      // Clean white canvas when no background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFF8F8F8),
      );
    }

    final nails = _getNailPositions(size);

    // Draw shape outline
    _drawOutline(canvas, size);

    // Draw completed LINE ART lines
    // Line art looks clean — no heavy overlapping
    _drawLines(canvas, nails, completedPath,
        showBackground);

    // Draw nail dots
    for (int i = 0; i < nails.length; i++) {
      _drawNail(canvas, nails[i], i, size);
    }

    // Highlight current nail
    if (currentNail < nails.length) {
      _drawHighlight(canvas, nails[currentNail],
          currentNail, Colors.orange, size);
    }

    // Highlight next nail
    if (nextNail < nails.length &&
        nextNail != currentNail) {
      _drawHighlight(canvas, nails[nextNail],
          nextNail, Colors.purple, size);
    }
  }

  // ── Draw clean artistic lines ──
  void _drawLines(Canvas canvas, List<Offset> nails,
      List<int> path, bool darkBg) {
    if (path.length < 2) return;

    for (int i = 0; i < path.length - 1; i++) {
      final from = path[i];
      final to = path[i + 1];
      if (from >= nails.length ||
          to >= nails.length) continue;

      // Line art: each line is distinct and visible
      final paint = Paint()
        ..color = darkBg
            ? Colors.white.withOpacity(0.7)
            : Colors.black.withOpacity(0.6)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(nails[from], nails[to], paint);
    }
  }

  void _drawOutline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const pad = 22.0;

    switch (shape) {
      case 'Square':
        canvas.drawRect(
          Rect.fromLTWH(pad, pad,
              size.width - pad * 2, size.height - pad * 2),
          paint,
        );
        break;
      case 'Rectangle':
        final h = (size.height - pad * 2) * 0.65;
        final oY = (size.height - h) / 2;
        canvas.drawRect(
          Rect.fromLTWH(
              pad, oY, size.width - pad * 2, h),
          paint,
        );
        break;
      default:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          min(size.width, size.height) / 2 - pad,
          paint,
        );
    }
  }

  void _drawNail(Canvas canvas, Offset pos,
      int index, Size size) {
    canvas.drawCircle(
        pos, 2.5,
        Paint()..color = Colors.white.withOpacity(0.5));

    if (index % 10 != 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final lx = pos.dx + (dx / dist) * 13;
    final ly = pos.dy + (dy / dist) * 13;

    final tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: const TextStyle(
            color: Colors.white54, fontSize: 7),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        (lx - tp.width / 2)
            .clamp(1.0, size.width - tp.width - 1),
        (ly - tp.height / 2)
            .clamp(1.0, size.height - tp.height - 1),
      ),
    );
  }

  void _drawHighlight(Canvas canvas, Offset pos,
      int index, Color color, Size size) {
    canvas.drawCircle(
        pos, 12, Paint()..color = color.withOpacity(0.2));
    canvas.drawCircle(
        pos, 7, Paint()..color = color.withOpacity(0.4));
    canvas.drawCircle(pos, 4.5, Paint()..color = color);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final lx = pos.dx + (dx / dist) * 18;
    final ly = pos.dy + (dy / dist) * 18;

    final tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        (lx - tp.width / 2)
            .clamp(1.0, size.width - tp.width - 1),
        (ly - tp.height / 2)
            .clamp(1.0, size.height - tp.height - 1),
      ),
    );
  }

  List<Offset> _getNailPositions(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final nails = <Offset>[];
    const pad = 22.0;

    switch (shape) {
      case 'Square':
        final w = size.width - pad * 2;
        final h = size.height - pad * 2;
        final perSide = nailCount ~/ 4;
        final extra = nailCount - perSide * 4;
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              pad + w * i / perSide, pad));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(size.width - pad,
              pad + h * i / perSide));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              size.width - pad - w * i / perSide,
              size.height - pad));
        }
        for (int i = 0; i < perSide + extra; i++) {
          nails.add(Offset(pad,
              size.height - pad -
                  h * i / max(perSide + extra - 1, 1)));
        }
        break;

      case 'Rectangle':
        final w = size.width - pad * 2;
        final h = (size.height - pad * 2) * 0.65;
        final oY = (size.height - h) / 2;
        final perim = 2 * w + 2 * h;
        final topN = (nailCount * w / perim).round();
        final sideN = (nailCount * h / perim).round();
        for (int i = 0; i < topN; i++) {
          nails.add(Offset(
              pad + w * i / max(topN - 1, 1), oY));
        }
        for (int i = 0; i < sideN; i++) {
          nails.add(Offset(size.width - pad,
              oY + h * i / max(sideN - 1, 1)));
        }
        for (int i = 0; i < topN; i++) {
          nails.add(Offset(
              size.width -
                  pad -
                  w * i / max(topN - 1, 1),
              oY + h));
        }
        final leftN = nailCount - nails.length;
        for (int i = 0; i < leftN; i++) {
          nails.add(Offset(pad,
              oY + h - h * i / max(leftN - 1, 1)));
        }
        break;

      default:
        final r = min(cx, cy) - pad;
        for (int i = 0; i < nailCount; i++) {
          final a =
              (2 * pi * i / nailCount) - (pi / 2);
          nails.add(Offset(
              cx + r * cos(a), cy + r * sin(a)));
        }
    }

    return nails.take(nailCount).toList();
  }

  @override
  bool shouldRepaint(LineArtPainter old) =>
      old.currentNail != currentNail ||
          old.nextNail != nextNail ||
          old.completedPath.length !=
              completedPath.length;
}