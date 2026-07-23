import 'dart:math';
import 'package:image/image.dart' as img;

// ════════════════════════════════════════════
// OUTPUT
// ════════════════════════════════════════════
class RGBPaths {
  final List<int> red;
  final List<int> green;
  final List<int> blue;

  const RGBPaths({
    required this.red,
    required this.green,
    required this.blue,
  });
}

class _Stage {
  final double errW;
  final double chanW;
  const _Stage(this.errW, this.chanW);
}

// ════════════════════════════════════════════
// RGB ALGORITHM — PARTS 1–4 COMPLETE
// ════════════════════════════════════════════
class RGBAlgorithm {

  // ── Canvas resolution ──
  // 400 = quality/speed balance for mobile
  static const int _sz = 400;

  // ── Pass configuration ──
  static const int _linesPerPass = 30;  // per channel per pass
  static const int _recentWindow = 22; // recent nail penalty window

  // ── Zone grid (Part 2) ──
  static const int _zoneCount = 12;
  static const double _zonePenaltyStart = 35.0;
  static const double _zonePenaltyMax = 0.25;
  static const double _pairReusePenalty = 0.40;

  // ── Adaptive opacity stages (Part 3) ──
  // Index 0 = earliest pass, Index 4 = cleanup
  static const List<double> _opacityStages = [
    66.0, 51.0, 40.0, 29.0, 18.0,
  ];

  // ── Part 4: Early stop thresholds ──
  static const double _minImprovementRatio = 0.008; // 0.8%
  static const int _maxStagnantChecks = 4;
  static const int _errorCheckInterval = 5; // every N passes

  // ════════════════════════════════════════════
  // MAIN ENTRY — All improvements active
  // ════════════════════════════════════════════
  static RGBPaths generate({
    required img.Image image,
    required int nailCount,
    required String shape,
    required String density,
  }) {
    final src =
    img.copyResize(image, width: _sz, height: _sz);

    // ── Pre-processing ──
    final target = _buildTarget(src);   // Part 1+4 (highlight preservation)
    final canvas = List<double>.filled(_sz * _sz * 3, 0.0);

    // ── Feature maps (Parts 2+3) ──
    final skinMap = _buildSkinMap(src);
    final importance = _buildImportanceMap(src, skinMap); // Part 3+4 (bg suppression)

    // ── Zone + pair tracking (Part 2) ──
    final zones = List<int>.filled(_zoneCount * _zoneCount, 0);
    final rPairs = <int>{};
    final gPairs = <int>{};
    final bPairs = <int>{};

    // ── Nail positions ──
    final nails = _getNails(nailCount, _sz, shape);

    // ── Part 4: Adaptive thread count ──
    // Scales with image complexity so simple images
    // don't get over-threaded
    final budget =
    _adaptiveThreadCount(src, density, nailCount);
    final totalPasses = (budget / _linesPerPass).ceil();

    // ── Output paths ──
    final rPath = <int>[0];
    final gPath = <int>[0];
    final bPath = <int>[0];

    // ── Recent nail tracking ──
    final rRecent = <int>[];
    final gRecent = <int>[];
    final bRecent = <int>[];

    int rNail = 0, gNail = 0, bNail = 0;

    // ── Part 3: Channel balance ──
    var channelBalance = [1.0, 1.0, 1.0];
    const balanceInterval = 8;

    // ── Part 4: Early stop state ──
    double prevError = double.maxFinite;
    int stagnantCount = 0;
    bool earlyStop = false;

    // ════════════════════════════════════════════
    // MULTI-PASS: R → G → B → R → G → B → …
    // ════════════════════════════════════════════
    for (int pass = 0;
    pass < totalPasses && !earlyStop;
    pass++) {

      final passProgress =
      totalPasses > 0 ? pass / totalPasses : 0.0;
      final stage = _stageFor(pass, totalPasses);

      final batch = min(
          _linesPerPass,
          budget - pass * _linesPerPass);
      if (batch <= 0) break;

      // ── Part 3: Adaptive opacity ──
      final passOpacity = _stageOpacity(passProgress);

      // ── Part 3: Channel balance update ──
      if (pass % balanceInterval == 0 && pass > 0) {
        channelBalance =
            _channelFillRatio(canvas, target);
      }

      // ── Part 4: Early-stop check ──
      if (pass % _errorCheckInterval == 0 &&
          pass > 10) {
        final currentError =
        _sampledTotalError(canvas, target);

        if (prevError < double.maxFinite) {
          final improvement = prevError > 0
              ? (prevError - currentError) / prevError
              : 1.0;

          if (improvement < _minImprovementRatio) {
            stagnantCount++;
            if (stagnantCount >= _maxStagnantChecks) {
              // Generation has plateaued — stop here
              earlyStop = true;
              break;
            }
          } else {
            stagnantCount = 0; // reset if improving
          }
        }
        prevError = currentError;
      }

      // ── Part 4: Dynamic candidate count ──
      final candidateCount =
      _candidatesForStage(passProgress);

      // ── Part 4: Adaptive min-skip ──
      // Later passes prefer longer lines → better structure
      final minSkipFrac = _minSkipFraction(passProgress);

      // ── Red batch ──
      if (rPath.length <= budget) {
        for (int l = 0; l < batch; l++) {
          final n = _bestLine(
            canvas: canvas,
            target: target,
            importance: importance,
            zones: zones,
            usedPairs: rPairs,
            channelBalance: channelBalance,
            nails: nails,
            cur: rNail,
            total: nailCount,
            ch: 0,
            stage: stage,
            recent: rRecent,
            candidateCount: candidateCount,
            minSkipFrac: minSkipFrac,
          );
          if (n == -1) break;
          rPath.add(n);
          _paintAndTrack(
            canvas: canvas,
            zones: zones,
            pairs: rPairs,
            from: nails[rNail],
            to: nails[n],
            fromIdx: rNail,
            toIdx: n,
            ch: 0,
            opacity: passOpacity,
          );
          _addRecent(rRecent, n);
          rNail = n;
        }
      }

      // ── Green batch ──
      if (gPath.length <= budget) {
        for (int l = 0; l < batch; l++) {
          final n = _bestLine(
            canvas: canvas,
            target: target,
            importance: importance,
            zones: zones,
            usedPairs: gPairs,
            channelBalance: channelBalance,
            nails: nails,
            cur: gNail,
            total: nailCount,
            ch: 1,
            stage: stage,
            recent: gRecent,
            candidateCount: candidateCount,
            minSkipFrac: minSkipFrac,
          );
          if (n == -1) break;
          gPath.add(n);
          _paintAndTrack(
            canvas: canvas,
            zones: zones,
            pairs: gPairs,
            from: nails[gNail],
            to: nails[n],
            fromIdx: gNail,
            toIdx: n,
            ch: 1,
            opacity: passOpacity,
          );
          _addRecent(gRecent, n);
          gNail = n;
        }
      }

      // ── Blue batch ──
      if (bPath.length <= budget) {
        for (int l = 0; l < batch; l++) {
          final n = _bestLine(
            canvas: canvas,
            target: target,
            importance: importance,
            zones: zones,
            usedPairs: bPairs,
            channelBalance: channelBalance,
            nails: nails,
            cur: bNail,
            total: nailCount,
            ch: 2,
            stage: stage,
            recent: bRecent,
            candidateCount: candidateCount,
            minSkipFrac: minSkipFrac,
          );
          if (n == -1) break;
          bPath.add(n);
          _paintAndTrack(
            canvas: canvas,
            zones: zones,
            pairs: bPairs,
            from: nails[bNail],
            to: nails[n],
            fromIdx: bNail,
            toIdx: n,
            ch: 2,
            opacity: passOpacity,
          );
          _addRecent(bRecent, n);
          bNail = n;
        }
      }
    }

    return RGBPaths(
        red: rPath, green: gPath, blue: bPath);
  }

  // ── Backward compatibility ──
  static List<int> generateSingleChannel({
    required img.Image image,
    required int nailCount,
    required String shape,
    required String density,
    required String channel,
  }) {
    final src =
    img.copyResize(image, width: _sz, height: _sz);
    final ch =
    channel == 'R' ? 0 : channel == 'G' ? 1 : 2;
    final target = _buildTarget(src);
    final canvas =
    List<double>.filled(_sz * _sz * 3, 0.0);
    final skinMap = _buildSkinMap(src);
    final importance = _buildImportanceMap(src, skinMap);
    final zones =
    List<int>.filled(_zoneCount * _zoneCount, 0);
    final pairs = <int>{};
    final nails = _getNails(nailCount, _sz, shape);
    final budget =
    _adaptiveThreadCount(src, density, nailCount);
    final path = <int>[0];
    final recent = <int>[];
    int cur = 0;
    var balance = [1.0, 1.0, 1.0];

    double prevErr = double.maxFinite;
    int stagnant = 0;

    for (int i = 0; i < budget; i++) {
      if (i % 40 == 0 && i > 0) {
        balance = _channelFillRatio(canvas, target);
      }
      if (i % 25 == 0 && i > 30) {
        final err = _sampledTotalError(canvas, target);
        if (prevErr < double.maxFinite) {
          final imp = prevErr > 0
              ? (prevErr - err) / prevErr
              : 1.0;
          if (imp < _minImprovementRatio) stagnant++;
          else stagnant = 0;
          if (stagnant >= _maxStagnantChecks) break;
        }
        prevErr = err;
      }
      final progress = budget > 0 ? i / budget : 0.0;
      final n = _bestLine(
        canvas: canvas,
        target: target,
        importance: importance,
        zones: zones,
        usedPairs: pairs,
        channelBalance: balance,
        nails: nails,
        cur: cur,
        total: nailCount,
        ch: ch,
        stage: _stageFor(i, budget),
        recent: recent,
        candidateCount: _candidatesForStage(progress),
        minSkipFrac: _minSkipFraction(progress),
      );
      if (n == -1) break;
      path.add(n);
      _paintAndTrack(
        canvas: canvas,
        zones: zones,
        pairs: pairs,
        from: nails[cur],
        to: nails[n],
        fromIdx: cur,
        toIdx: n,
        ch: ch,
        opacity: _stageOpacity(progress),
      );
      _addRecent(recent, n);
      cur = n;
    }
    return path;
  }

  // ════════════════════════════════════════════
  // PART 4: SAMPLED TOTAL ERROR
  //
  // Fast quality check: samples every 8th pixel
  // (~2500 samples from 160,000 pixels = <1ms)
  // Used by early-stop to detect plateau.
  // ════════════════════════════════════════════
  static double _sampledTotalError(
      List<double> canvas, List<double> target) {
    double total = 0;
    const step = 8;

    for (int py = 0; py < _sz; py += step) {
      for (int px = 0; px < _sz; px += step) {
        final i = (py * _sz + px) * 3;
        if (i + 2 >= canvas.length) continue;
        total += _perceptualErr(
          canvas[i], canvas[i + 1], canvas[i + 2],
          target[i], target[i + 1], target[i + 2],
        );
      }
    }
    return total;
  }

  // ════════════════════════════════════════════
  // PART 4: ADAPTIVE THREAD COUNT
  //
  // Scales base budget by image complexity.
  // Simple/flat images → fewer threads (avoid noise).
  // Complex portraits → more threads (capture detail).
  //
  // Complexity = luminance std-dev of sampled pixels.
  // Low std (<30) → 0.70× budget
  // High std (>75) → 1.35× budget
  // ════════════════════════════════════════════
  static int _adaptiveThreadCount(
      img.Image image, String density, int nailCount) {
    final base = _baseBudget(density);

    // Sample luminance variance
    double sum = 0, sumSq = 0;
    int cnt = 0;
    const step = 8;

    for (int y = 0; y < _sz; y += step) {
      for (int x = 0; x < _sz; x += step) {
        final p = image.getPixel(x, y);
        final lum =
            0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        sum += lum;
        sumSq += lum * lum;
        cnt++;
      }
    }

    if (cnt == 0) return base;

    final mean = sum / cnt;
    final variance =
    max(0.0, sumSq / cnt - mean * mean);
    final std = sqrt(variance);

    // Complexity scale: 0.70 → 1.35
    final complexity =
    (std / 52.0).clamp(0.70, 1.35);

    final adapted = (base * complexity).round();

    // Clamp: min 500, max 3500 (mobile safety)
    return adapted.clamp(500, 3500);
  }

  static int _baseBudget(String density) {
    switch (density) {
      case 'Low': return 800;
      case 'High': return 2500;
      default: return 1500;
    }
  }

  // ════════════════════════════════════════════
  // PART 4: DYNAMIC CANDIDATE COUNT
  //
  // Early passes: 45 candidates → fast rough structure
  // Mid passes:   62 candidates → balanced
  // Late passes:  78 candidates → thorough refinement
  //
  // Saves ~20% generation time on early passes.
  // ════════════════════════════════════════════
  static int _candidatesForStage(double passProgress) {
    if (passProgress < 0.20) return 45;
    if (passProgress < 0.60) return 62;
    return 78;
  }

  // ════════════════════════════════════════════
  // PART 4: ADAPTIVE MIN-SKIP FRACTION
  //
  // Minimum angular gap between cur nail and candidate.
  // Early passes: short lines OK (broad coverage)
  // Late passes:  longer lines preferred (better structure)
  // ════════════════════════════════════════════
  static double _minSkipFraction(double passProgress) {
    if (passProgress < 0.30) return 0.08;
    if (passProgress < 0.65) return 0.10;
    return 0.12;
  }

  // ════════════════════════════════════════════
  // PART 3: SKIN TONE MAP
  // ════════════════════════════════════════════
  static List<double> _buildSkinMap(img.Image image) {
    final skin = List<double>.filled(_sz * _sz, 0.0);

    for (int y = 0; y < _sz; y++) {
      for (int x = 0; x < _sz; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        final lum =
            0.299 * r + 0.587 * g + 0.114 * b;

        final isSkin = r > g * 1.05 &&
            g >= b * 0.98 &&
            r - b < 155 &&
            r - g < 105 &&
            lum > 60 &&
            r > 85;

        if (isSkin) {
          final brightness =
          (lum / 255.0).clamp(0.0, 1.0);
          skin[y * _sz + x] =
              0.30 + brightness * 0.40;
        }
      }
    }
    return skin;
  }

  // ════════════════════════════════════════════
  // PART 3+4: IMPORTANCE MAP (skin + bg suppression)
  //
  // Per-pixel weight [0.5 – ~4.5]
  // Part 3: smooth skin = lighter treatment
  // Part 4: background = 50% importance
  // ════════════════════════════════════════════
  static List<double> _buildImportanceMap(
      img.Image image, List<double> skinMap) {
    final edges = _sobelEdgeMap(image);
    final contrast = _localContrastMap(image);
    final map = List<double>.filled(_sz * _sz, 1.0);

    const cx = _sz / 2.0, cy = _sz / 2.0;
    const maxR = _sz * 0.5;

    for (int y = 0; y < _sz; y++) {
      for (int x = 0; x < _sz; x++) {
        final idx = y * _sz + x;

        final eW = edges[idx] / 255.0;
        final cW = contrast[idx] / 255.0;

        final dx = x - cx, dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final centerW =
        (1.0 - (dist / maxR).clamp(0.0, 1.0));

        double imp = 1.0
            + eW * 2.0
            + cW * 0.9
            + centerW * 0.8;

        final skinW = skinMap[idx];

        // ── Part 3: Smooth skin penalty ──
        if (skinW > 0 && eW < 0.20) {
          imp *= (1.0 - skinW * 0.50)
              .clamp(0.50, 1.0);
        }

        // ── Part 4: Background suppression ──
        // Non-skin, far from center, low edge
        // = likely background → reduce importance
        if (centerW < 0.28 &&
            eW < 0.15 &&
            skinW == 0) {
          imp *= 0.50;
        }

        map[idx] = imp;
      }
    }
    return map;
  }

  // ════════════════════════════════════════════
  // PART 1+4: RGB TARGET
  //
  // Additive model: high channel = draw thread there.
  // Part 4 adds:
  //   - Highlight preservation (lum>215 → reduced target)
  //   - Prevents over-threading bright highlights
  // ════════════════════════════════════════════
  static List<double> _buildTarget(img.Image image) {
    final t = List<double>.filled(_sz * _sz * 3, 0.0);
    const cx = _sz / 2.0, cy = _sz / 2.0;
    const maxD = _sz * 0.5;

    for (int y = 0; y < _sz; y++) {
      for (int x = 0; x < _sz; x++) {
        final p = image.getPixel(x, y);
        final idx = (y * _sz + x) * 3;

        double r = _sCurve(p.r.toDouble());
        double g = _sCurve(p.g.toDouble());
        double b = _sCurve(p.b.toDouble());

        // ── Part 4: Highlight preservation ──
        // Very bright pixels = highlights.
        // Threads should barely touch these areas
        // to preserve natural skin glow.
        final lum =
            0.299 * r + 0.587 * g + 0.114 * b;
        if (lum > 215) {
          // Gradually reduce target for highlights
          final factor =
          (1.0 - (lum - 215) / 80.0)
              .clamp(0.28, 1.0);
          r *= factor;
          g *= factor;
          b *= factor;
        }

        // ── Part 1: Center boost ──
        final dx = x - cx, dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final boost =
            1.0 + (1.0 - (dist / maxD).clamp(0.0, 1.0)) *
                0.28;

        t[idx + 0] = (r * boost).clamp(0, 255);
        t[idx + 1] = (g * boost).clamp(0, 255);
        t[idx + 2] = (b * boost).clamp(0, 255);
      }
    }
    return t;
  }

  static double _sCurve(double v) {
    final n = v / 255.0;
    final s = n < 0.5
        ? 2.0 * n * n
        : 1.0 - pow(-2.0 * n + 2.0, 2) / 2.0;
    return (s * 255.0).clamp(0.0, 255.0);
  }

  // ════════════════════════════════════════════
  // PART 3: ADAPTIVE OPACITY PER STAGE
  // ════════════════════════════════════════════
  static double _stageOpacity(double passProgress) {
    if (passProgress < 0.20) return _opacityStages[0];
    if (passProgress < 0.50) return _opacityStages[1];
    if (passProgress < 0.75) return _opacityStages[2];
    if (passProgress < 0.90) return _opacityStages[3];
    return _opacityStages[4];
  }

  // ════════════════════════════════════════════
  // PART 3: CHANNEL FILL RATIO
  // Samples every 10th pixel (~160 samples)
  // ════════════════════════════════════════════
  static List<double> _channelFillRatio(
      List<double> canvas, List<double> target) {
    double rH = 0, gH = 0, bH = 0;
    double rN = 0, gN = 0, bN = 0;
    const step = 10;

    for (int py = 0; py < _sz; py += step) {
      for (int px = 0; px < _sz; px += step) {
        final i = (py * _sz + px) * 3;
        if (i + 2 >= canvas.length) continue;
        rH += canvas[i];
        gH += canvas[i + 1];
        bH += canvas[i + 2];
        rN += target[i];
        gN += target[i + 1];
        bN += target[i + 2];
      }
    }

    return [
      rN > 1 ? (rH / rN).clamp(0.0, 2.5) : 1.0,
      gN > 1 ? (gH / gN).clamp(0.0, 2.5) : 1.0,
      bN > 1 ? (bH / bN).clamp(0.0, 2.5) : 1.0,
    ];
  }

  // ════════════════════════════════════════════
  // PART 2+3: PAINT + TRACK
  // ════════════════════════════════════════════
  static void _paintAndTrack({
    required List<double> canvas,
    required List<int> zones,
    required Set<int> pairs,
    required List<int> from,
    required List<int> to,
    required int fromIdx,
    required int toIdx,
    required int ch,
    required double opacity,
  }) {
    final pts = _bresenham(from[0], from[1], to[0], to[1]);

    // Part 3: zone-density opacity modifier
    int maxZoneDensity = 0;
    for (int pi = 0; pi < pts.length; pi += 6) {
      final x = pts[pi][0], y = pts[pi][1];
      if (x < 0 || x >= _sz || y < 0 || y >= _sz) continue;
      final zx = (x * _zoneCount / _sz)
          .floor().clamp(0, _zoneCount - 1);
      final zy = (y * _zoneCount / _sz)
          .floor().clamp(0, _zoneCount - 1);
      final d = zones[zy * _zoneCount + zx];
      if (d > maxZoneDensity) maxZoneDensity = d;
    }

    final densityFactor =
    (1.0 - maxZoneDensity / 240.0).clamp(0.35, 1.0);
    final finalOpacity =
    (opacity * densityFactor).clamp(10.0, 72.0);

    for (final p in pts) {
      final x = p[0], y = p[1];
      if (x < 0 || x >= _sz || y < 0 || y >= _sz) continue;

      final ci = (y * _sz + x) * 3 + ch;
      canvas[ci] = min(255.0, canvas[ci] + finalOpacity);

      final zx = (x * _zoneCount / _sz)
          .floor().clamp(0, _zoneCount - 1);
      final zy = (y * _zoneCount / _sz)
          .floor().clamp(0, _zoneCount - 1);
      zones[zy * _zoneCount + zx]++;
    }

    pairs.add(_pairKey(fromIdx, toIdx));
  }

  // ════════════════════════════════════════════
  // PART 2+3+4: BEST LINE SELECTION
  //
  // Now uses:
  //   - Part 2: importance, zones, pairs
  //   - Part 3: channel balance
  //   - Part 4: dynamic candidate count + min-skip
  // ════════════════════════════════════════════
  static int _bestLine({
    required List<double> canvas,
    required List<double> target,
    required List<double> importance,
    required List<int> zones,
    required Set<int> usedPairs,
    required List<double> channelBalance,
    required List<List<int>> nails,
    required int cur,
    required int total,
    required int ch,
    required _Stage stage,
    required List<int> recent,
    required int candidateCount,  // Part 4
    required double minSkipFrac,  // Part 4
  }) {
    final minSkip = (total * minSkipFrac).round();

    // Build candidates
    final pool = <int>[];
    for (int i = 0; i < total; i++) {
      final d = (i - cur).abs();
      if (d >= minSkip && d <= total - minSkip) {
        pool.add(i);
      }
    }
    if (pool.isEmpty) return -1;

    // Sample for speed (dynamic count)
    if (pool.length > candidateCount) {
      pool.shuffle(Random(cur));
      pool.removeRange(candidateCount, pool.length);
    }

    // Part 3: channel balance modifier
    final balRatio = channelBalance[ch];
    final balanceMod =
    (1.0 / max(0.3, balRatio)).clamp(0.4, 2.5);

    double best = -double.infinity;
    int bestNail = -1;

    for (final cand in pool) {
      final pts = _bresenham(
        nails[cur][0], nails[cur][1],
        nails[cand][0], nails[cand][1],
      );
      if (pts.isEmpty) continue;

      // ── Per-pixel importance-weighted scoring ──
      double totalScore = 0;
      double totalWeight = 0;

      for (final p in pts) {
        final x = p[0], y = p[1];
        if (x < 0 || x >= _sz || y < 0 || y >= _sz) continue;

        final ci = (y * _sz + x) * 3;
        final cR = canvas[ci];
        final cG = canvas[ci + 1];
        final cB = canvas[ci + 2];
        final tR = target[ci];
        final tG = target[ci + 1];
        final tB = target[ci + 2];

        final eBef =
        _perceptualErr(cR, cG, cB, tR, tG, tB);

        final nR = ch == 0
            ? min(255.0, cR + 60.0) : cR;

        final nG = ch == 1
            ? min(255.0, cG + 60.0) : cG;

        final nB = ch == 2
            ? min(255.0, cB + 60.0) : cB;
        final eAft =
        _perceptualErr(nR, nG, nB, tR, tG, tB);

        final improvement = eBef - eAft;
        final demand = target[ci + ch];
        final raw = improvement * stage.errW
            + demand * stage.chanW * 0.07;

        final imp = importance[y * _sz + x];
        totalScore += raw * imp;
        totalWeight += imp;
      }

      if (totalWeight == 0) continue;

      double s = totalScore / totalWeight;

      // Apply modifiers
      s *= balanceMod;
      s *= _zonePenalty(zones, nails[cur], nails[cand]);

      if (usedPairs.contains(_pairKey(cur, cand))) {
        s *= _pairReusePenalty;
      }

      final ri = recent.indexOf(cand);
      if (ri >= 0) {
        final recency = 1.0 - ri / _recentWindow;
        s *= 1.0 - recency * 0.45;
      }

      if (s > best) {
        best = s;
        bestNail = cand;
      }
    }

    if (best < 0.08) return -1;
    return bestNail;
  }

  // ════════════════════════════════════════════
  // PART 2: ZONE PENALTY
  // ════════════════════════════════════════════
  static double _zonePenalty(
      List<int> zones,
      List<int> from,
      List<int> to) {
    final pts = _bresenham(from[0], from[1], to[0], to[1]);
    double maxD = 0;

    for (int i = 0; i < pts.length; i += 5) {
      final x = pts[i][0], y = pts[i][1];
      if (x < 0 || x >= _sz || y < 0 || y >= _sz) continue;
      final zx = (x * _zoneCount / _sz)
          .floor().clamp(0, _zoneCount - 1);
      final zy = (y * _zoneCount / _sz)
          .floor().clamp(0, _zoneCount - 1);
      final d = zones[zy * _zoneCount + zx].toDouble();
      if (d > maxD) maxD = d;
    }

    if (maxD <= _zonePenaltyStart) return 1.0;
    return max(_zonePenaltyMax,
        1.0 - (maxD - _zonePenaltyStart) / 120.0);
  }

  // ════════════════════════════════════════════
  // PART 2: EDGE + CONTRAST MAPS
  // ════════════════════════════════════════════
  static List<double> _sobelEdgeMap(img.Image image) {
    final gray = List<double>.filled(_sz * _sz, 0.0);
    for (int y = 0; y < _sz; y++) {
      for (int x = 0; x < _sz; x++) {
        final p = image.getPixel(x, y);
        gray[y * _sz + x] =
            0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }

    final edges = List<double>.filled(_sz * _sz, 0.0);
    double maxMag = 1.0;

    for (int y = 1; y < _sz - 1; y++) {
      for (int x = 1; x < _sz - 1; x++) {
        final gx =
            -gray[(y - 1) * _sz + (x - 1)]
                - 2 * gray[y * _sz + (x - 1)]
                - gray[(y + 1) * _sz + (x - 1)]
                + gray[(y - 1) * _sz + (x + 1)]
                + 2 * gray[y * _sz + (x + 1)]
                + gray[(y + 1) * _sz + (x + 1)];

        final gy =
            -gray[(y - 1) * _sz + (x - 1)]
                - 2 * gray[(y - 1) * _sz + x]
                - gray[(y - 1) * _sz + (x + 1)]
                + gray[(y + 1) * _sz + (x - 1)]
                + 2 * gray[(y + 1) * _sz + x]
                + gray[(y + 1) * _sz + (x + 1)];

        final mag = sqrt(gx * gx + gy * gy);
        edges[y * _sz + x] = mag;
        if (mag > maxMag) maxMag = mag;
      }
    }

    for (int i = 0; i < edges.length; i++) {
      edges[i] =
          (edges[i] / maxMag * 255).clamp(0, 255);
    }
    return edges;
  }

  static List<double> _localContrastMap(img.Image image) {
    const r = 3;
    final lum = List<double>.filled(_sz * _sz, 0.0);
    for (int y = 0; y < _sz; y++) {
      for (int x = 0; x < _sz; x++) {
        final p = image.getPixel(x, y);
        lum[y * _sz + x] =
            0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }

    final contrast = List<double>.filled(_sz * _sz, 0.0);
    double maxC = 1.0;

    for (int y = r; y < _sz - r; y++) {
      for (int x = r; x < _sz - r; x++) {
        double sum = 0, sumSq = 0;
        int cnt = 0;
        for (int dy = -r; dy <= r; dy++) {
          for (int dx = -r; dx <= r; dx++) {
            final v = lum[(y + dy) * _sz + (x + dx)];
            sum += v;
            sumSq += v * v;
            cnt++;
          }
        }
        final mean = sum / cnt;
        final variance =
        max(0.0, sumSq / cnt - mean * mean);
        final std = sqrt(variance);
        contrast[y * _sz + x] = std;
        if (std > maxC) maxC = std;
      }
    }

    for (int i = 0; i < contrast.length; i++) {
      contrast[i] =
          (contrast[i] / maxC * 255).clamp(0, 255);
    }
    return contrast;
  }

  // ════════════════════════════════════════════
  // SHARED HELPERS
  // ════════════════════════════════════════════
  static double _perceptualErr(
      double cR, double cG, double cB,
      double tR, double tG, double tB) {
    final dr = (cR - tR) * 0.299;
    final dg = (cG - tG) * 0.587;
    final db = (cB - tB) * 0.114;
    return dr * dr + dg * dg + db * db;
  }

  static _Stage _stageFor(int pass, int total) {
    final t = total == 0 ? 0.0 : pass / total;
    if (t < 0.20) return const _Stage(1.3, 0.7);
    if (t < 0.50) return const _Stage(1.0, 1.0);
    if (t < 0.75) return const _Stage(0.85, 1.3);
    if (t < 0.90) return const _Stage(0.75, 1.5);
    return const _Stage(0.65, 1.8);
  }

  static int _pairKey(int a, int b) {
    final lo = min(a, b);
    final hi = max(a, b);
    return lo * 1000 + hi;
  }

  static void _addRecent(List<int> r, int nail) {
    r.insert(0, nail);
    if (r.length > _recentWindow) r.removeLast();
  }

  static List<List<int>> _getNails(
      int count, int size, String shape) {
    final nails = <List<int>>[];
    final c = size / 2.0;
    const pad = 10;

    switch (shape) {
      case 'Square':
        final w = size - pad * 2.0;
        final ps = count ~/ 4;
        final ex = count - ps * 4;
        for (int i = 0; i < ps; i++) {
          nails.add([(pad + w * i / ps).round(), pad]);
        }
        for (int i = 0; i < ps; i++) {
          nails.add(
              [size - pad, (pad + w * i / ps).round()]);
        }
        for (int i = 0; i < ps; i++) {
          nails.add([
            (size - pad - w * i / ps).round(),
            size - pad
          ]);
        }
        for (int i = 0; i < ps + ex; i++) {
          nails.add([
            pad,
            (size -
                pad -
                w * i / max(ps + ex - 1, 1))
                .round()
          ]);
        }
        break;

      case 'Rectangle':
        final w = size - pad * 2.0;
        final h = w * 0.65;
        final oy = (size - h) / 2;
        final pm = 2 * w + 2 * h;
        final tn = (count * w / pm).round();
        final sn = (count * h / pm).round();
        for (int i = 0; i < tn; i++) {
          nails.add([
            (pad + w * i / max(tn - 1, 1)).round(),
            oy.round()
          ]);
        }
        for (int i = 0; i < sn; i++) {
          nails.add([
            (size - pad).round(),
            (oy + h * i / max(sn - 1, 1)).round()
          ]);
        }
        for (int i = 0; i < tn; i++) {
          nails.add([
            (size - pad - w * i / max(tn - 1, 1))
                .round(),
            (oy + h).round()
          ]);
        }
        final ln = count - nails.length;
        for (int i = 0; i < ln; i++) {
          nails.add([
            pad,
            (oy + h - h * i / max(ln - 1, 1)).round()
          ]);
        }
        break;

      default: // Circle
        final r = c - pad;
        for (int i = 0; i < count; i++) {
          final a = (2 * pi * i / count) - (pi / 2);
          nails.add([
            (c + r * cos(a)).round().clamp(0, size - 1),
            (c + r * sin(a)).round().clamp(0, size - 1),
          ]);
        }
    }
    return nails.take(count).toList();
  }

  static List<List<int>> _bresenham(
      int x0, int y0, int x1, int y1) {
    final pts = <List<int>>[];
    int dx = (x1 - x0).abs(), dy = (y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy, x = x0, y = y0;
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