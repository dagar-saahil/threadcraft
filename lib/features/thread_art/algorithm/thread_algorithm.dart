import 'dart:math';
import 'package:image/image.dart' as img;

class ThreadAlgorithm {
  // ── How many candidate nails to check per step ──
  static const int _candidates = 120;

  // ── How many recent nails to penalize ──
  static const int _penaltyWindow = 25;

  static List<int> generate({
    required img.Image image,
    required int nailCount,
    required String shape,
    required String density,
  }) {
    const size = 500;
    final resized =
    img.copyResize(image, width: size, height: size);

    // ── STEP 1: Advanced preprocessing ──
    final pixels = _advancedPreprocess(resized, size);

    // ── STEP 2: Nail positions ──
    final nails = _getNails(nailCount, size, shape);

    // ── STEP 3: Thread count based on density ──
    final threadCount = _getThreadCount(density);

    // ── STEP 4: Professional greedy algorithm ──
    return _professionalGreedy(
      pixels: pixels,
      nails: nails,
      threadCount: threadCount,
      nailCount: nailCount,
      size: size,
    );
  }

  // ════════════════════════════════════
  // ADVANCED PREPROCESSING
  // ════════════════════════════════════

  static List<List<double>> _advancedPreprocess(
      img.Image image, int size) {
    // Step 1: Proper luminance grayscale
    var gray = List.generate(size, (y) =>
        List.generate(size, (x) {
          final p = image.getPixel(x, y);
          // ITU-R BT.601 luminance formula
          return 0.299 * p.r.toDouble() +
              0.587 * p.g.toDouble() +
              0.114 * p.b.toDouble();
        })
    );

    // Step 2: Histogram equalization for contrast
    gray = _histogramEqualize(gray, size);

    // Step 3: Unsharp masking (sharpens details)
    gray = _unsharpMask(gray, size);

    // Step 4: Sobel edge detection
    final edges = _sobelEdges(gray, size);

    // Step 5: Blend: 60% grayscale + 40% edges
    var blended = List.generate(size, (y) =>
        List.generate(size, (x) =>
            (gray[y][x] * 0.60 + edges[y][x] * 0.40)
                .clamp(0.0, 255.0)
        )
    );

    // Step 6: Invert (dark = draw here)
    blended = List.generate(size, (y) =>
        List.generate(size, (x) =>
        255.0 - blended[y][x]
        )
    );

    // Step 7: Center boost (helps portrait faces)
    blended = _addCenterBoost(blended, size);

    return blended;
  }

  // ── Histogram equalization ──
  static List<List<double>> _histogramEqualize(
      List<List<double>> pixels, int size) {
    // Build histogram
    final hist = List.filled(256, 0);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final bin =
        pixels[y][x].round().clamp(0, 255);
        hist[bin]++;
      }
    }

    // Cumulative distribution
    final cdf = List.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + hist[i];
    }

    final cdfMin = cdf.firstWhere(
            (v) => v > 0, orElse: () => 1);
    final total = size * size;

    // Build LUT
    final lut = List.generate(256, (i) =>
        ((cdf[i] - cdfMin) /
            (total - cdfMin) * 255)
            .round()
            .clamp(0, 255)
            .toDouble()
    );

    return List.generate(size, (y) =>
        List.generate(size, (x) =>
        lut[pixels[y][x].round().clamp(0, 255)]
        )
    );
  }

  // ── Unsharp masking (sharpens edges) ──
  static List<List<double>> _unsharpMask(
      List<List<double>> pixels, int size) {
    // Create blurred version (box blur)
    final blurred = List.generate(size, (y) =>
        List.generate(size, (x) {
          double sum = 0;
          int count = 0;
          for (int dy = -2; dy <= 2; dy++) {
            for (int dx = -2; dx <= 2; dx++) {
              final ny = (y + dy).clamp(0, size - 1);
              final nx = (x + dx).clamp(0, size - 1);
              sum += pixels[ny][nx];
              count++;
            }
          }
          return sum / count;
        })
    );

    // Unsharp: original + amount * (original - blurred)
    return List.generate(size, (y) =>
        List.generate(size, (x) {
          final sharpened =
              pixels[y][x] + 0.5 * (pixels[y][x] - blurred[y][x]);
          return sharpened.clamp(0.0, 255.0);
        })
    );
  }

  // ── Sobel edge detection ──
  static List<List<double>> _sobelEdges(
      List<List<double>> pixels, int size) {
    final edges = List.generate(
        size, (_) => List.filled(size, 0.0));

    for (int y = 1; y < size - 1; y++) {
      for (int x = 1; x < size - 1; x++) {
        final gx =
            -pixels[y - 1][x - 1] -
                2 * pixels[y][x - 1] -
                pixels[y + 1][x - 1] +
                pixels[y - 1][x + 1] +
                2 * pixels[y][x + 1] +
                pixels[y + 1][x + 1];

        final gy =
            -pixels[y - 1][x - 1] -
                2 * pixels[y - 1][x] -
                pixels[y - 1][x + 1] +
                pixels[y + 1][x - 1] +
                2 * pixels[y + 1][x] +
                pixels[y + 1][x + 1];

        edges[y][x] =
            sqrt(gx * gx + gy * gy)
                .clamp(0.0, 255.0);
      }
    }

    return edges;
  }

  // ── Center boost for portrait faces ──
  static List<List<double>> _addCenterBoost(
      List<List<double>> pixels, int size) {
    final cx = size / 2.0;
    final cy = size / 2.0;
    final maxDist = sqrt(cx * cx + cy * cy);

    return List.generate(size, (y) =>
        List.generate(size, (x) {
          final dx = x - cx;
          final dy = y - cy;
          final dist = sqrt(dx * dx + dy * dy);
          // Up to 25% boost for center pixels
          final boost = 1.0 +
              (1.0 - (dist / maxDist)) * 0.25;
          return (pixels[y][x] * boost)
              .clamp(0.0, 255.0);
        })
    );
  }

  // ════════════════════════════════════
  // PROFESSIONAL GREEDY ALGORITHM
  // ════════════════════════════════════

  static List<int> _professionalGreedy({
    required List<List<double>> pixels,
    required List<List<int>> nails,
    required int threadCount,
    required int nailCount,
    required int size,
  }) {
    final path = <int>[0];
    int current = 0;

    // Recent nails — used for penalty
    final recentNails = <int>[];

    // Min/max skip distance
    final minSkip = (nailCount * 0.08).round();
    final maxSkip = nailCount - minSkip;

    for (int step = 0; step < threadCount; step++) {
      // ── Get valid candidate nails ──
      final allValid = <int>[];
      for (int i = 0; i < nailCount; i++) {
        final diff = (i - current).abs();
        if (diff >= minSkip && diff <= maxSkip) {
          allValid.add(i);
        }
      }

      if (allValid.isEmpty) break;

      // ── Sample for speed (don't check all) ──
      final candidates = <int>[];
      if (allValid.length <= _candidates) {
        candidates.addAll(allValid);
      } else {
        // Shuffle and take top N
        final shuffled = List<int>.from(allValid)
          ..shuffle(Random(step));
        candidates.addAll(
            shuffled.sublist(0, _candidates));
      }

      // ── Score each candidate ──
      double bestScore = -1;
      int bestNail = -1;

      for (final candidate in candidates) {
        final lineVals = _getLineValues(
          nails[current][0],
          nails[current][1],
          nails[candidate][0],
          nails[candidate][1],
          pixels,
          size,
        );

        if (lineVals.isEmpty) continue;

        // ── Advanced scoring ──
        double score = _scoreLineAdvanced(lineVals);

        // Penalty for recently used nails
        final recentIdx =
        recentNails.indexOf(candidate);
        if (recentIdx >= 0) {
          // More recent = higher penalty
          final recency = 1.0 -
              recentIdx / _penaltyWindow.toDouble();
          score *= (1.0 - recency * 0.5);
        }

        if (score > bestScore) {
          bestScore = score;
          bestNail = candidate;
        }
      }

      // Stop if no good lines left
      if (bestNail == -1 || bestScore < 8.0) break;

      path.add(bestNail);

      // Update recent nails list
      recentNails.insert(0, bestNail);
      if (recentNails.length > _penaltyWindow) {
        recentNails.removeLast();
      }

      // ── Adaptive erasure ──
      _adaptiveErase(
        nails[current][0],
        nails[current][1],
        nails[bestNail][0],
        nails[bestNail][1],
        pixels,
        size,
      );

      current = bestNail;
    }

    return path;
  }

  // ── Advanced line scoring ──
  static double _scoreLineAdvanced(
      List<double> values) {
    if (values.isEmpty) return 0;

    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;

    // Mean
    final mean =
        sorted.reduce((a, b) => a + b) / n;

    // 70th percentile (upper portion matters more)
    final p70 =
    sorted[(n * 0.70).floor().clamp(0, n - 1)];

    // 90th percentile (bright highlights on the line)
    final p90 =
    sorted[(n * 0.90).floor().clamp(0, n - 1)];

    // Weighted: mean + upper percentiles
    return mean * 0.35 + p70 * 0.35 + p90 * 0.30;
  }

  // ── Get double pixel values along line ──
  static List<double> _getLineValues(
      int x0, int y0, int x1, int y1,
      List<List<double>> pixels,
      int size,
      ) {
    final result = <double>[];
    for (final p in _bresenham(x0, y0, x1, y1)) {
      if (p[0] >= 0 &&
          p[0] < size &&
          p[1] >= 0 &&
          p[1] < size) {
        result.add(pixels[p[1]][p[0]]);
      }
    }
    return result;
  }

  // ── Adaptive erasure ──
  static void _adaptiveErase(
      int x0, int y0, int x1, int y1,
      List<List<double>> pixels,
      int size,
      ) {
    for (final p in _bresenham(x0, y0, x1, y1)) {
      final x = p[0];
      final y = p[1];
      if (x < 0 || x >= size || y < 0 || y >= size) {
        continue;
      }

      final current = pixels[y][x];

      // Dark areas: erase more (fill quickly)
      // Light areas: erase less (avoid overdraw)
      final eraseAmt = 50.0 +
          (current / 255.0) * 40.0;

      pixels[y][x] =
          max(0.0, current - eraseAmt);
    }
  }

  // ── Nail positions ──
  static List<List<int>> _getNails(
      int count, int size, String shape) {
    final nails = <List<int>>[];
    final center = size / 2.0;
    const padding = 10;

    switch (shape) {
      case 'Square':
        final w = size - padding * 2.0;
        final perSide = count ~/ 4;
        final extra = count - perSide * 4;
        for (int i = 0; i < perSide; i++) {
          nails.add([
            (padding + w * i / perSide).round(),
            padding
          ]);
        }
        for (int i = 0; i < perSide; i++) {
          nails.add([
            size - padding,
            (padding + w * i / perSide).round()
          ]);
        }
        for (int i = 0; i < perSide; i++) {
          nails.add([
            (size - padding - w * i / perSide).round(),
            size - padding
          ]);
        }
        for (int i = 0; i < perSide + extra; i++) {
          nails.add([
            padding,
            (size -
                padding -
                w *
                    i /
                    max(perSide + extra - 1, 1))
                .round()
          ]);
        }
        break;

      case 'Rectangle':
        final w = size - padding * 2.0;
        final h = w * 0.65;
        final oY = (size - h) / 2;
        final perim = 2 * w + 2 * h;
        final topN = (count * w / perim).round();
        final sideN = (count * h / perim).round();
        for (int i = 0; i < topN; i++) {
          nails.add([
            (padding + w * i / max(topN - 1, 1)).round(),
            oY.round()
          ]);
        }
        for (int i = 0; i < sideN; i++) {
          nails.add([
            (size - padding).round(),
            (oY + h * i / max(sideN - 1, 1)).round()
          ]);
        }
        for (int i = 0; i < topN; i++) {
          nails.add([
            (size - padding -
                w * i / max(topN - 1, 1))
                .round(),
            (oY + h).round()
          ]);
        }
        final leftN = count - nails.length;
        for (int i = 0; i < leftN; i++) {
          nails.add([
            padding,
            (oY + h -
                h * i / max(leftN - 1, 1))
                .round()
          ]);
        }
        break;

      default: // Circle
        final radius = center - padding;
        for (int i = 0; i < count; i++) {
          final angle =
              (2 * pi * i / count) - (pi / 2);
          nails.add([
            (center + radius * cos(angle))
                .round()
                .clamp(0, size - 1),
            (center + radius * sin(angle))
                .round()
                .clamp(0, size - 1),
          ]);
        }
    }

    return nails.take(count).toList();
  }

  static int _getThreadCount(String density) {
    switch (density) {
      case 'Low': return 700;
      case 'High': return 3000;
      default: return 1500;
    }
  }

  static List<List<int>> _bresenham(
      int x0, int y0, int x1, int y1) {
    final pts = <List<int>>[];
    int dx = (x1 - x0).abs();
    int dy = (y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;
    int x = x0, y = y0;

    while (true) {
      pts.add([x, y]);
      if (x == x1 && y == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) { err -= dy; x += sx; }
      if (e2 < dx) { err += dx; y += sy; }
    }

    return pts;
  }
}