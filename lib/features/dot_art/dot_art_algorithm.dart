import 'dart:math';
import 'package:image/image.dart' as img;

class DotPoint {
  final int x;      // position on canvas
  final int y;
  final int number; // dot number shown to user
  final int darkness; // how dark this area is

  const DotPoint({
    required this.x,
    required this.y,
    required this.number,
    required this.darkness,
  });
}

class DotArtAlgorithm {
  // Returns list of dot points in connection order
  static List<DotPoint> generate({
    required img.Image image,
    required int dotCount,
    required String shape,
  }) {
    final resized = img.copyResize(image, width: 500, height: 500);
    final gray = img.grayscale(resized);
    final size = 500;

    // ── Step 1: Build pixel grid ──
    final pixels = List.generate(size, (y) =>
        List.generate(size, (x) =>
        255 - gray.getPixel(x, y).r.toInt()
        )
    );

    // ── Step 2: Find key dark points using grid ──
    final rawDots = _findKeyPoints(pixels, size, dotCount, shape);

    // ── Step 3: Sort by darkness (darkest first) ──
    rawDots.sort((a, b) => b.darkness.compareTo(a.darkness));

    // ── Step 4: Create travel sequence (nearest-neighbor) ──
    final ordered = _orderByNearestNeighbor(rawDots);

    // ── Step 5: Number them in travel order ──
    return List.generate(ordered.length, (i) =>
        DotPoint(
          x: ordered[i].x,
          y: ordered[i].y,
          number: i + 1,
          darkness: ordered[i].darkness,
        )
    );
  }

  // ── FIND DARK POINTS IN GRID CELLS ──
  static List<DotPoint> _findKeyPoints(
      List<List<int>> pixels,
      int size,
      int count,
      String shape,
      ) {
    final dots = <DotPoint>[];
    final gridSize = sqrt(count).ceil();
    final cellW = size / gridSize;
    final cellH = size / gridSize;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (dots.length >= count) break;

        final startX = (col * cellW).round();
        final startY = (row * cellH).round();
        final endX = min(startX + cellW.round(), size - 1);
        final endY = min(startY + cellH.round(), size - 1);

        // Find darkest pixel in this cell
        int darkestX = startX;
        int darkestY = startY;
        int maxDark = 0;

        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            final d = pixels[y][x];
            if (d > maxDark) {
              maxDark = d;
              darkestX = x;
              darkestY = y;
            }
          }
        }

        // Only add if dark enough (ignore white areas)
        if (maxDark > 30) {
          dots.add(DotPoint(
            x: darkestX,
            y: darkestY,
            number: dots.length + 1,
            darkness: maxDark,
          ));
        }
      }
    }

    return dots;
  }

  // ── NEAREST NEIGHBOR ORDERING ──
  // Makes the connect-the-dots path flow smoothly
  static List<DotPoint> _orderByNearestNeighbor(
      List<DotPoint> dots) {
    if (dots.isEmpty) return [];

    final remaining = List<DotPoint>.from(dots);
    final ordered = <DotPoint>[];
    var current = remaining.removeAt(0);
    ordered.add(current);

    while (remaining.isNotEmpty) {
      double minDist = double.infinity;
      int nearestIdx = 0;

      for (int i = 0; i < remaining.length; i++) {
        final dx = remaining[i].x - current.x;
        final dy = remaining[i].y - current.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < minDist) {
          minDist = dist;
          nearestIdx = i;
        }
      }

      current = remaining.removeAt(nearestIdx);
      ordered.add(current);
    }

    return ordered;
  }
}