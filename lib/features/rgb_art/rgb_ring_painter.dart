import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RGBRingPainter extends CustomPainter {
  final int nailCount;
  final String shape;
  final ui.Image? backgroundImage;
  final List<int> completedRed;
  final List<int> completedGreen;
  final List<int> completedBlue;
  final int currentNail;
  final int nextNail;
  final String activeColor;
  final bool showBackground;

  const RGBRingPainter({
    required this.nailCount,
    required this.shape,
    required this.completedRed,
    required this.completedGreen,
    required this.completedBlue,
    required this.currentNail,
    required this.nextNail,
    required this.activeColor,
    this.backgroundImage,
    this.showBackground = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ══════════════════════════════════════════
    // FIX 1: PURE BLACK BACKGROUND
    // This is the critical fix.
    // BlendMode.plus on white = white.
    // BlendMode.plus on BLACK = correct RGB color.
    // ══════════════════════════════════════════
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF080808),
    );

    // ── Optional: photo at 8% opacity (reference only) ──
    // Low enough that it doesn't affect thread colors
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
        backgroundImage!,
        src,
        dst,
        Paint()
          ..color = Colors.white.withOpacity(0.10),
      );
    }

    // ── Compute nail positions ──
    final nails = _getNailPositions(size);

    // ── Draw shape outline ──
    _drawOutline(canvas, size, nails);

    // ══════════════════════════════════════════
    // FIX 2: INTERLEAVED RENDERING
    // Competitor: 50 Red → 50 Blue → 50 Green → repeat
    // NOT: all Blue → all Red → all Green
    //
    // With normal blend mode:
    //   - ORDER matters (last = on top)
    //   - Interleaving = no color dominates
    //   - Natural visual color mixing
    //
    // FIX 3: CORRECT OPACITY
    //   - Each thread: 0.22 opacity
    //   - Matches algorithm _threadAdd ≈ 54
    //   - Takes ~5 threads to saturate (not 2!)
    //   - Fine portrait detail preserved
    // ══════════════════════════════════════════
    _drawInterleavedBatches(canvas, nails);

    // ── Nail dots ──
    for (int i = 0; i < nails.length; i++) {
      _drawNailDot(canvas, nails[i], i, size);
    }

    // ── Highlight current + next ──
    final activeCol = _colorFor(activeColor);
    if (currentNail < nails.length) {
      _drawHighlight(
          canvas, nails[currentNail],
          currentNail, activeCol, size);
    }
    if (nextNail < nails.length &&
        nextNail != currentNail) {
      _drawHighlight(
          canvas, nails[nextNail],
          nextNail, activeCol.withOpacity(0.5), size);
    }
  }

  // ══════════════════════════════════════════
  // INTERLEAVED BATCH RENDERING
  // Draws: Red[0:50] → Blue[0:50] → Green[0:50]
  //      → Red[50:100] → Blue[50:100] → Green[50:100]
  //      → ... until all paths exhausted
  // ══════════════════════════════════════════
  void _drawInterleavedBatches(
      Canvas canvas, List<Offset> nails) {
    const batchSize = 50;

    final rLen = (completedRed.length - 1)
        .clamp(0, completedRed.length);
    final gLen = (completedGreen.length - 1)
        .clamp(0, completedGreen.length);
    final bLen = (completedBlue.length - 1)
        .clamp(0, completedBlue.length);

    final maxBatches =
    ((max(max(rLen, gLen), bLen)) / batchSize)
        .ceil();

    // Pre-create paints (avoid creating inside loop)
    final redPaint = Paint()
      ..color = Colors.red.withOpacity(0.38)
      ..strokeWidth = 0.70
      ..strokeCap = StrokeCap.round;

    final greenPaint = Paint()
      ..color = Colors.green.withOpacity(0.38)
      ..strokeWidth = 0.70
      ..strokeCap = StrokeCap.round;

    final bluePaint = Paint()
      ..color = Colors.blue.withOpacity(0.38)
      ..strokeWidth = 0.70
      ..strokeCap = StrokeCap.round;

    for (int batch = 0;
    batch < maxBatches;
    batch++) {
      final start = batch * batchSize;
      final end = start + batchSize;

      // ── Red batch ──
      _drawSegment(canvas, nails, completedRed,
          start, end, rLen, redPaint);

      // ── Blue batch ──
      _drawSegment(canvas, nails, completedBlue,
          start, end, bLen, bluePaint);

      // ── Green batch ──
      _drawSegment(canvas, nails, completedGreen,
          start, end, gLen, greenPaint);
    }
  }

  void _drawSegment(
      Canvas canvas,
      List<Offset> nails,
      List<int> path,
      int start,
      int end,
      int pathLen,
      Paint paint,
      ) {
    final from = start;
    final to = min(end, pathLen);
    for (int i = from; i < to; i++) {
      if (path[i] < nails.length &&
          path[i + 1] < nails.length) {
        canvas.drawLine(
            nails[path[i]], nails[path[i + 1]], paint);
      }
    }
  }

  Color _colorFor(String name) {
    switch (name) {
      case 'Red': return Colors.red;
      case 'Green': return Colors.green;
      default: return Colors.blue;
    }
  }

  // ── Shape outline ──
  void _drawOutline(Canvas canvas, Size size,
      List<Offset> nails) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const pad = 22.0;

    switch (shape) {
      case 'Square':
        canvas.drawRect(
          Rect.fromLTWH(pad, pad,
              size.width - pad * 2,
              size.height - pad * 2),
          paint,
        );
        break;
      case 'Rectangle':
        final h =
            (size.height - pad * 2) * 0.65;
        final oY = (size.height - h) / 2;
        canvas.drawRect(
          Rect.fromLTWH(pad, oY,
              size.width - pad * 2, h),
          paint,
        );
        break;
      default:
        canvas.drawCircle(
          Offset(
              size.width / 2, size.height / 2),
          min(size.width, size.height) / 2 - pad,
          paint,
        );
    }
  }

  void _drawNailDot(Canvas canvas, Offset pos,
      int index, Size size) {
    canvas.drawCircle(
        pos,
        2.0,
        Paint()
          ..color = Colors.white.withOpacity(0.35));

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
            color: Colors.white38, fontSize: 7),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        (lx - tp.width / 2)
            .clamp(1.0, size.width - tp.width - 1),
        (ly - tp.height / 2)
            .clamp(1.0,
            size.height - tp.height - 1),
      ),
    );
  }

  void _drawHighlight(
      Canvas canvas,
      Offset pos,
      int index,
      Color color,
      Size size,
      ) {
    canvas.drawCircle(pos, 14,
        Paint()..color = color.withOpacity(0.15));
    canvas.drawCircle(pos, 9,
        Paint()..color = color.withOpacity(0.35));
    canvas.drawCircle(pos, 5,
        Paint()..color = color);

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
            .clamp(1.0,
            size.height - tp.height - 1),
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
              size.width -
                  pad -
                  w * i / perSide,
              size.height - pad));
        }
        for (int i = 0;
        i < perSide + extra;
        i++) {
          nails.add(Offset(
              pad,
              size.height -
                  pad -
                  h *
                      i /
                      max(perSide + extra - 1,
                          1)));
        }
        break;

      case 'Rectangle':
        final w = size.width - pad * 2;
        final h = (size.height - pad * 2) * 0.65;
        final oY = (size.height - h) / 2;
        final perim = 2 * w + 2 * h;
        final topN =
        (nailCount * w / perim).round();
        final sideN =
        (nailCount * h / perim).round();
        for (int i = 0; i < topN; i++) {
          nails.add(Offset(
              pad + w * i / max(topN - 1, 1),
              oY));
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
          nails.add(Offset(
              pad,
              oY +
                  h -
                  h * i / max(leftN - 1, 1)));
        }
        break;

      default:
        final r = min(cx, cy) - pad;
        for (int i = 0; i < nailCount; i++) {
          final a =
              (2 * pi * i / nailCount) - (pi / 2);
          nails.add(Offset(
              cx + r * cos(a),
              cy + r * sin(a)));
        }
    }
    return nails.take(nailCount).toList();
  }

  @override
  bool shouldRepaint(RGBRingPainter old) =>
      old.currentNail != currentNail ||
          old.nextNail != nextNail ||
          old.showBackground != showBackground ||
          old.completedRed.length !=
              completedRed.length ||
          old.completedGreen.length !=
              completedGreen.length ||
          old.completedBlue.length !=
              completedBlue.length;
}