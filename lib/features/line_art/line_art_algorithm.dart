import 'dart:math';
import 'package:image/image.dart' as img;

class LineArtAlgorithm {
  static List<int> generate({
    required img.Image image,
    required int nailCount,
    required String shape,
  }) {
    // Resize to working size
    final resized = img.copyResize(image, width: 500, height: 500);
    final grayImage = img.grayscale(resized);
    final int size = 500;

    // ── Step 1: Build pixel grid ──
    final pixels = List.generate(size, (y) =>
        List.generate(size, (x) {
          final p = grayImage.getPixel(x, y);
          return p.r.toInt();
        })
    );

    // ── Step 2: Edge detection (find outlines) ──
    final edges = _detectEdges(pixels, size);

    // ── Step 3: Invert edges (bright = draw here) ──
    final edgeMap = List.generate(size, (y) =>
        List.generate(size, (x) =>
        255 - edges[y][x]
        )
    );

    // ── Step 4: Generate nail positions ──
    final nails = _getNails(nailCount, size, shape);

    // ── Step 5: Greedy path on edge map ──
    // Line art uses fewer threads = cleaner look
    final threadCount = (nailCount * 2.5).round().clamp(300, 800);
    final path = _greedyPath(
      pixels: edgeMap,
      nails: nails,
      threadCount: threadCount,
      size: size,
    );

    return path;
  }

  // ── EDGE DETECTION (Sobel) ──
  static List<List<int>> _detectEdges(
      List<List<int>> pixels, int size) {
    final edges = List.generate(
        size, (_) => List.filled(size, 0));

    for (int y = 1; y < size - 1; y++) {
      for (int x = 1; x < size - 1; x++) {
        // Horizontal gradient
        final gx =
            -pixels[y - 1][x - 1] - 2 * pixels[y][x - 1] -
                pixels[y + 1][x - 1] +
                pixels[y - 1][x + 1] + 2 * pixels[y][x + 1] +
                pixels[y + 1][x + 1];

        // Vertical gradient
        final gy =
            -pixels[y - 1][x - 1] - 2 * pixels[y - 1][x] -
                pixels[y - 1][x + 1] +
                pixels[y + 1][x - 1] + 2 * pixels[y + 1][x] +
                pixels[y + 1][x + 1];

        final magnitude = sqrt(gx * gx + gy * gy).toInt();
        edges[y][x] = magnitude.clamp(0, 255);
      }
    }

    return edges;
  }

  // ── NAIL POSITIONS ──
  static List<List<int>> _getNails(
      int count, int size, String shape) {
    final nails = <List<int>>[];
    final center = size / 2;
    final padding = 12;

    switch (shape) {
      case 'Square':
        final w = size - padding * 2.0;
        final perSide = count ~/ 4;
        for (int i = 0; i < perSide; i++) {
          nails.add([(padding + w * i / perSide).round(), padding]);
        }
        for (int i = 0; i < perSide; i++) {
          nails.add([size - padding, (padding + w * i / perSide).round()]);
        }
        for (int i = 0; i < perSide; i++) {
          nails.add([(size - padding - w * i / perSide).round(), size - padding]);
        }
        final left = count - nails.length;
        for (int i = 0; i < left; i++) {
          nails.add([padding, (size - padding - w * i / max(left - 1, 1)).round()]);
        }
        break;

      case 'Rectangle':
        final w = size - padding * 2.0;
        final h = w * 0.65;
        final offsetY = (size - h) / 2;
        final perim = 2 * w + 2 * h;
        final topN = (count * w / perim).round();
        final sideN = (count * h / perim).round();

        for (int i = 0; i < topN; i++) {
          nails.add([(padding + w * i / max(topN - 1, 1)).round(), offsetY.round()]);
        }
        for (int i = 0; i < sideN; i++) {
          nails.add([(size - padding).round(), (offsetY + h * i / max(sideN - 1, 1)).round()]);
        }
        for (int i = 0; i < topN; i++) {
          nails.add([(size - padding - w * i / max(topN - 1, 1)).round(), (offsetY + h).round()]);
        }
        final leftN = count - nails.length;
        for (int i = 0; i < leftN; i++) {
          nails.add([padding, (offsetY + h - h * i / max(leftN - 1, 1)).round()]);
        }
        break;

      default: // Circle
        final radius = center - padding;
        for (int i = 0; i < count; i++) {
          final angle = (2 * pi * i / count) - (pi / 2);
          nails.add([
            (center + radius * cos(angle)).round(),
            (center + radius * sin(angle)).round(),
          ]);
        }
    }

    return nails.take(count).toList();
  }

  // ── GREEDY PATH ──
  static List<int> _greedyPath({
    required List<List<int>> pixels,
    required List<List<int>> nails,
    required int threadCount,
    required int size,
  }) {
    final path = <int>[0];
    int current = 0;
    final count = nails.length;

    for (int step = 0; step < threadCount; step++) {
      double best = -1;
      int bestNail = -1;
      final skip = (count * 0.08).round();

      for (int c = 0; c < count; c++) {
        final diff = (c - current).abs();
        if (diff < skip || diff > count - skip) continue;

        final linePixels = _linePixels(
          nails[current][0], nails[current][1],
          nails[c][0], nails[c][1],
          pixels, size,
        );
        if (linePixels.isEmpty) continue;

        final score = linePixels.reduce((a, b) => a + b) /
            linePixels.length;
        if (score > best) {
          best = score;
          bestNail = c;
        }
      }

      if (bestNail == -1) break;
      path.add(bestNail);
      _erasePixels(
        nails[current][0], nails[current][1],
        nails[bestNail][0], nails[bestNail][1],
        pixels, size,
      );
      current = bestNail;
    }

    return path;
  }

  static List<int> _linePixels(
      int x0, int y0, int x1, int y1,
      List<List<int>> pixels, int size) {
    final result = <int>[];
    for (final p in _bresenham(x0, y0, x1, y1)) {
      if (p[0] >= 0 && p[0] < size &&
          p[1] >= 0 && p[1] < size) {
        result.add(pixels[p[1]][p[0]]);
      }
    }
    return result;
  }

  static void _erasePixels(
      int x0, int y0, int x1, int y1,
      List<List<int>> pixels, int size) {
    for (final p in _bresenham(x0, y0, x1, y1)) {
      if (p[0] >= 0 && p[0] < size &&
          p[1] >= 0 && p[1] < size) {
        pixels[p[1]][p[0]] = max(0, pixels[p[1]][p[0]] - 60);
      }
    }
  }

  static List<List<int>> _bresenham(
      int x0, int y0, int x1, int y1) {
    final points = <List<int>>[];
    int dx = (x1 - x0).abs();
    int dy = (y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;
    int x = x0, y = y0;
    while (true) {
      points.add([x, y]);
      if (x == x1 && y == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) { err -= dy; x += sx; }
      if (e2 < dx) { err += dx; y += sy; }
    }
    return points;
  }
}