import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart' show BuildContext, Offset;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class NailTemplatePdfService {
  static const double _a4W = 210.0;
  static const double _a4H = 297.0;
  static const double _margin = 12.0;
  static const double _overlap = 8.0;
  static const double _printW = _a4W - _margin * 2;
  static const double _printH = _a4H - _margin * 2;
  static const double _tileW = _printW - _overlap;
  static const double _tileH = _printH - _overlap;
  static const double _mmPt = PdfPageFormat.mm;

  static Future<void> generate({
    required BuildContext context,
    required int nailCount,
    required String shape,
    required int boardSizeCm,
    required String threadSize,
    required String density,
    required List<int> nailPath,
  }) async {
    final boardMm = boardSizeCm * 10.0;
    final cols = (boardMm / _tileW).ceil();
    final rows = (boardMm / _tileH).ceil();
    final totalTiles = cols * rows;
    final nails = _nailPositionsMm(nailCount, shape, boardMm);
    final pdf = pw.Document();

    // Page 1: Info
    pdf.addPage(_buildInfoPage(
      nailCount: nailCount,
      shape: shape,
      boardSizeCm: boardSizeCm,
      threadSize: threadSize,
      density: density,
      cols: cols,
      rows: rows,
      totalTiles: totalTiles,
      nails: nails,
      boardMm: boardMm,
    ));

    // Tile pages
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        pdf.addPage(_buildTilePage(
          col: col,
          row: row,
          totalCols: cols,
          totalRows: rows,
          boardMm: boardMm,
          nailCount: nailCount,
          shape: shape,
          nails: nails,
          pageNum: row * cols + col + 2,
          totalPages: totalTiles + 1,
          boardSizeCm: boardSizeCm,
        ));
      }
    }

    // Step list pages
    if (nailPath.isNotEmpty) {
      _addStepListPages(pdf, nailPath, boardSizeCm, shape);
    }

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/ThreadCRAFT_${shape}_${boardSizeCm}cm_${nailCount}nails.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'ThreadCRAFT Nail Template',
      text: 'ThreadCRAFT nail template — ${boardSizeCm}cm $shape, $nailCount nails',
    );
  }

  // ════════════════════════════
  // PAGE 1 — INFO
  // ════════════════════════════
  static pw.Page _buildInfoPage({
    required int nailCount,
    required String shape,
    required int boardSizeCm,
    required String threadSize,
    required String density,
    required int cols,
    required int rows,
    required int totalTiles,
    required List<Offset> nails,
    required double boardMm,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(_margin * _mmPt),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.deepPurple900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ThreadCRAFT',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('Professional Nail Placement Template',
                        style: const pw.TextStyle(
                            color: PdfColors.purple200, fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('${boardSizeCm}cm $shape',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('$nailCount nails  •  $density density',
                        style: const pw.TextStyle(
                            color: PdfColors.purple200, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // Specs
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _specBox('Board', '${boardSizeCm}cm'),
              _specBox('Nails', '$nailCount'),
              _specBox('Shape', shape),
              _specBox('Thread', threadSize),
              _specBox('Pages', '$totalTiles'),
            ],
          ),

          pw.SizedBox(height: 14),

          // Instructions
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.amber700, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('How to Use This Template',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 8),
                _instStep('1', 'Print ALL ${totalTiles + 1} pages at 100% scale (never "Fit to page").'),
                _instStep('2', 'Cut along the dashed lines at page edges.'),
                _instStep('3', 'Align pages using the corner cross marks (✚).'),
                _instStep('4', 'Tape pages together to form the complete template.'),
                _instStep('5', 'Place on ${boardSizeCm}cm wooden board.'),
                _instStep('6', 'Hammer nail at every numbered circle, starting from Nail 1.'),
                _instStep('7', 'Remove paper. Begin winding thread!'),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // Page grid
          pw.Text('Page Assembly Map:',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          _buildPageGrid(cols, rows),

          pw.SizedBox(height: 14),

          // Overview
          pw.Text('Nail Map Overview (scaled):',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.SizedBox(
              width: 200,
              height: 200,
              child: pw.CustomPaint(
                painter: (canvas, size) =>
                    _drawOverview(canvas, size, nails, shape, boardMm),
              ),
            ),
          ),

          pw.Spacer(),
          pw.Center(
            child: pw.Text(
              'Generated by ThreadCRAFT  •  Print at 100% scale only',
              style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _specBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.deepPurple50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.deepPurple200, width: 0.5),
      ),
      child: pw.Column(children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: PdfColors.deepPurple900)),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ]),
    );
  }

  static pw.Widget _instStep(String num, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 16,
            height: 16,
            margin: const pw.EdgeInsets.only(right: 6, top: 1),
            decoration: const pw.BoxDecoration(
                color: PdfColors.deepPurple900, shape: pw.BoxShape.circle),
            child: pw.Center(
                child: pw.Text(num,
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 8))),
          ),
          pw.Expanded(
              child:
              pw.Text(text, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  static pw.Widget _buildPageGrid(int cols, int rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: List.generate(
        rows,
            (row) => pw.TableRow(
          children: List.generate(cols, (col) {
            final pn = row * cols + col + 2;
            return pw.Container(
              padding: const pw.EdgeInsets.all(6),
              color: PdfColors.deepPurple50,
              child: pw.Center(
                child: pw.Text(
                  'P$pn\n${String.fromCharCode(65 + col)}${row + 1}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ════════════════════════════
  // TILE PAGES
  // ════════════════════════════
  static pw.Page _buildTilePage({
    required int col,
    required int row,
    required int totalCols,
    required int totalRows,
    required double boardMm,
    required int nailCount,
    required String shape,
    required List<Offset> nails,
    required int pageNum,
    required int totalPages,
    required int boardSizeCm,
  }) {
    final winX0 = col * _tileW;
    final winY0 = row * _tileH;

    // ── Pre-calculate nail labels as pw widget data ──
    // This avoids the PdfFont error completely!
    final nailSpacingMm =
        (pi * boardMm * 0.95) / max(nailCount, 1);
    final fontSize =
    (nailSpacingMm * 0.55 * _mmPt).clamp(3.5, 6.5);
    final labelDist = 2.8 * _mmPt; // pts outside nail

    final labelItems = <Map<String, dynamic>>[];
    final cx = boardMm / 2;
    final cy = boardMm / 2;

    for (int i = 0; i < nails.length; i++) {
      final nail = nails[i];
      if (nail.dx < winX0 - 6 ||
          nail.dx > winX0 + _printW + 6 ||
          nail.dy < winY0 - 6 ||
          nail.dy > winY0 + _printH + 6) continue;

      final px = (nail.dx - winX0 + _margin) * _mmPt;
      final py = (nail.dy - winY0 + _margin) * _mmPt;

      final dx = nail.dx - cx;
      final dy = nail.dy - cy;
      final dist = sqrt(dx * dx + dy * dy);
      double lx = px, ly = py;

      if (dist > 0) {
        lx = px + (dx / dist) * labelDist;
        ly = py + (dy / dist) * labelDist;
      }

      labelItems.add({
        'x': lx - (fontSize * 0.3 * ('${i+1}'.length)),
        'y': ly - fontSize * 0.5,
        'label': '${i + 1}',
      });
    }

    final nextRight = col + 1 < totalCols
        ? '${String.fromCharCode(65 + col + 1)}${row + 1}'
        : '—';
    final nextDown = row + 1 < totalRows
        ? '${String.fromCharCode(65 + col)}${row + 2}'
        : '—';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Stack(
        children: [
          // White background
          pw.Container(
              color: PdfColors.white,
              width: double.infinity,
              height: double.infinity),

          // Shapes + nail dots (CustomPaint — no text here)
          pw.CustomPaint(
            size: PdfPoint(_a4W * _mmPt, _a4H * _mmPt),
            painter: (canvas, size) => _drawTileShapes(
              canvas: canvas,
              pageSize: size,
              nails: nails,
              shape: shape,
              boardMm: boardMm,
              winX0: winX0,
              winY0: winY0,
            ),
          ),

          // ── Nail numbers as pw.Text (fixes PdfFont error!) ──
          ...labelItems.map((item) => pw.Positioned(
            left: (item['x'] as double).clamp(0.0, _a4W * _mmPt - 20),
            top: (item['y'] as double).clamp(8 * _mmPt, (_a4H - 8) * _mmPt),
            child: pw.Text(
              item['label'] as String,
              style: pw.TextStyle(
                fontSize: fontSize,
                color: PdfColors.deepPurple900,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          )),

          // Alignment marks
          pw.CustomPaint(
            size: PdfPoint(_a4W * _mmPt, _a4H * _mmPt),
            painter: (canvas, size) =>
                _drawAlignmentMarks(canvas, size),
          ),

          // Dashed overlap lines
          pw.CustomPaint(
            size: PdfPoint(_a4W * _mmPt, _a4H * _mmPt),
            painter: (canvas, size) => _drawOverlapGuides(
                canvas, size, col, row, totalCols, totalRows),
          ),

          // Top label
          pw.Positioned(
            top: 4 * _mmPt,
            left: _margin * _mmPt,
            right: _margin * _mmPt,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ThreadCRAFT  ${boardSizeCm}cm $shape  $nailCount Nails',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page $pageNum/$totalPages  |  Tile ${String.fromCharCode(65 + col)}${row + 1}',
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700),
                ),
              ],
            ),
          ),

          // Bottom label
          pw.Positioned(
            bottom: 4 * _mmPt,
            left: _margin * _mmPt,
            right: _margin * _mmPt,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '⚠ Print at 100% — Do NOT scale to fit',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.red),
                ),
                pw.Text(
                  'Join →  $nextRight  ↓  $nextDown',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shapes + dots only — NO text drawing
  static void _drawTileShapes({
    required PdfGraphics canvas,
    required PdfPoint pageSize,
    required List<Offset> nails,
    required String shape,
    required double boardMm,
    required double winX0,
    required double winY0,
  }) {
    final ph = pageSize.y;

    // Shape outline
    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(0.5);

    if (shape == 'Circle') {
      const steps = 720;
      bool started = false;
      final cx = boardMm / 2;
      final cy = boardMm / 2;
      final r = boardMm * 0.475;

      for (int i = 0; i <= steps; i++) {
        final a = (2 * pi * i / steps) - (pi / 2);
        final bx = cx + r * cos(a);
        final by = cy + r * sin(a);
        final px = (bx - winX0 + _margin) * _mmPt;
        final py = ph - (by - winY0 + _margin) * _mmPt;

        if (!started) {
          canvas.moveTo(px, py);
          started = true;
        } else {
          canvas.lineTo(px, py);
        }
      }
      canvas.strokePath();
    } else {
      final pts = _getShapeOutlinePts(shape, boardMm);
      for (int i = 0; i < pts.length; i++) {
        final px = (pts[i].dx - winX0 + _margin) * _mmPt;
        final py = ph - (pts[i].dy - winY0 + _margin) * _mmPt;
        i == 0 ? canvas.moveTo(px, py) : canvas.lineTo(px, py);
      }
      canvas.closePath();
      canvas.strokePath();
    }

    // Center crosshair
    final ccx = (boardMm / 2 - winX0 + _margin) * _mmPt;
    final ccy = ph - (boardMm / 2 - winY0 + _margin) * _mmPt;
    if (ccx > 0 && ccx < pageSize.x && ccy > 0 && ccy < ph) {
      canvas.setStrokeColor(PdfColors.grey300);
      canvas.setLineWidth(0.3);
      canvas.moveTo(ccx - 8, ccy);
      canvas.lineTo(ccx + 8, ccy);
      canvas.strokePath();
      canvas.moveTo(ccx, ccy - 8);
      canvas.lineTo(ccx, ccy + 8);
      canvas.strokePath();
    }

    // Nail dots (circles only — numbers handled by pw.Positioned)
    canvas.setFillColor(PdfColors.black);
    for (int i = 0; i < nails.length; i++) {
      final nail = nails[i];
      if (nail.dx < winX0 - 6 ||
          nail.dx > winX0 + _printW + 6 ||
          nail.dy < winY0 - 6 ||
          nail.dy > winY0 + _printH + 6) continue;

      final px = (nail.dx - winX0 + _margin) * _mmPt;
      final py = ph - (nail.dy - winY0 + _margin) * _mmPt;
      canvas.drawEllipse(px, py, 1.2, 1.2);
      canvas.fillPath();
    }
  }

  static void _drawAlignmentMarks(
      PdfGraphics canvas, PdfPoint size) {
    final corners = [
      const Offset(8, 8),
      Offset(_a4W - 8, 8),
      Offset(8, _a4H - 8),
      Offset(_a4W - 8, _a4H - 8),
    ];
    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(0.4);
    for (final c in corners) {
      final px = c.dx * _mmPt;
      final py = size.y - c.dy * _mmPt;
      const cs = 5.0;
      canvas.moveTo(px - cs, py);
      canvas.lineTo(px + cs, py);
      canvas.strokePath();
      canvas.moveTo(px, py - cs);
      canvas.lineTo(px, py + cs);
      canvas.strokePath();
      canvas.drawEllipse(px, py, 1.5, 1.5);
      canvas.strokePath();
    }
  }

  static void _drawOverlapGuides(
      PdfGraphics canvas,
      PdfPoint size,
      int col,
      int row,
      int totalCols,
      int totalRows,
      ) {
    canvas.setStrokeColor(PdfColors.blue200);
    canvas.setLineWidth(0.3);

    if (col < totalCols - 1) {
      final x = (_a4W - _margin) * _mmPt;
      _dashedLine(canvas, x, 0, x, size.y);
    }
    if (row < totalRows - 1) {
      final y = size.y - (_a4H - _margin) * _mmPt;
      _dashedLine(canvas, 0, y, size.x, y);
    }
  }

  static void _dashedLine(PdfGraphics canvas,
      double x0, double y0, double x1, double y1) {
    const dash = 4.0, gap = 3.0;
    final len = sqrt(pow(x1 - x0, 2) + pow(y1 - y0, 2));
    final steps = (len / (dash + gap)).floor();
    final nx = (x1 - x0) / len;
    final ny = (y1 - y0) / len;
    for (int i = 0; i < steps; i++) {
      final s = i * (dash + gap);
      canvas.moveTo(x0 + nx * s, y0 + ny * s);
      canvas.lineTo(
          x0 + nx * (s + dash), y0 + ny * (s + dash));
      canvas.strokePath();
    }
  }

  static void _drawOverview(PdfGraphics canvas,
      PdfPoint size, List<Offset> nails, String shape, double boardMm) {
    final scale = min(size.x / boardMm, size.y / boardMm);
    final offX = (size.x - boardMm * scale) / 2;
    final offY = (size.y - boardMm * scale) / 2;

    canvas.setStrokeColor(PdfColors.deepPurple900);
    canvas.setLineWidth(1.0);

    if (shape == 'Circle') {
      final cx = offX + boardMm / 2 * scale;
      final cy = offY + boardMm / 2 * scale;
      final r = boardMm * 0.475 * scale;
      canvas.drawEllipse(cx, cy, r, r);
      canvas.strokePath();
    } else {
      final pts = _getShapeOutlinePts(shape, boardMm);
      for (int i = 0; i < pts.length; i++) {
        final px = offX + pts[i].dx * scale;
        final py = offY + pts[i].dy * scale;
        i == 0 ? canvas.moveTo(px, py) : canvas.lineTo(px, py);
      }
      canvas.closePath();
      canvas.strokePath();
    }

    canvas.setFillColor(PdfColors.deepPurple700);
    for (final n in nails) {
      canvas.drawEllipse(
          offX + n.dx * scale, offY + n.dy * scale, 1.5, 1.5);
      canvas.fillPath();
    }

    if (nails.isNotEmpty) {
      canvas.setFillColor(PdfColors.red);
      canvas.drawEllipse(
          offX + nails[0].dx * scale, offY + nails[0].dy * scale, 3, 3);
      canvas.fillPath();
    }
  }

  static List<Offset> _getShapeOutlinePts(
      String shape, double boardMm) {
    const pad = 0.05;
    final inner = boardMm * (1 - pad * 2);
    final offset = boardMm * pad;
    if (shape == 'Rectangle') {
      final h = inner * 0.65;
      final oY = (boardMm - h) / 2;
      return [
        Offset(offset, oY),
        Offset(offset + inner, oY),
        Offset(offset + inner, oY + h),
        Offset(offset, oY + h),
        Offset(offset, oY),
      ];
    }
    return [
      Offset(offset, offset),
      Offset(offset + inner, offset),
      Offset(offset + inner, offset + inner),
      Offset(offset, offset + inner),
      Offset(offset, offset),
    ];
  }

  static List<Offset> _nailPositionsMm(
      int count, String shape, double boardMm) {
    final nails = <Offset>[];
    final cx = boardMm / 2;
    final cy = boardMm / 2;

    switch (shape) {
      case 'Square':
        final side = boardMm * 0.95;
        final off = (boardMm - side) / 2;
        final perSide = count ~/ 4;
        final extra = count - perSide * 4;
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(off + side * i / max(perSide, 1), off));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(
              Offset(off + side, off + side * i / max(perSide, 1)));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              off + side - side * i / max(perSide, 1), off + side));
        }
        for (int i = 0; i < perSide + extra; i++) {
          nails.add(Offset(off,
              off + side - side * i / max(perSide + extra - 1, 1)));
        }
        break;
      case 'Rectangle':
        final w = boardMm * 0.95;
        final h = boardMm * 0.95 * 0.65;
        final ox = (boardMm - w) / 2;
        final oy = (boardMm - h) / 2;
        final perim = 2 * w + 2 * h;
        final topN = (count * w / perim).round();
        final sideN = (count * h / perim).round();
        for (int i = 0; i < topN; i++) {
          nails.add(Offset(ox + w * i / max(topN - 1, 1), oy));
        }
        for (int i = 0; i < sideN; i++) {
          nails.add(Offset(ox + w, oy + h * i / max(sideN - 1, 1)));
        }
        for (int i = 0; i < topN; i++) {
          nails.add(Offset(
              ox + w - w * i / max(topN - 1, 1), oy + h));
        }
        final leftN = count - nails.length;
        for (int i = 0; i < leftN; i++) {
          nails.add(
              Offset(ox, oy + h - h * i / max(leftN - 1, 1)));
        }
        break;
      default:
        final r = boardMm * 0.475;
        for (int i = 0; i < count; i++) {
          final a = (2 * pi * i / count) - (pi / 2);
          nails.add(Offset(cx + r * cos(a), cy + r * sin(a)));
        }
    }
    return nails.take(count).toList();
  }

  static void _addStepListPages(pw.Document pdf,
      List<int> nailPath, int boardSizeCm, String shape) {
    const stepsPerPage = 54;
    final total = ((nailPath.length - 1) / stepsPerPage).ceil();

    for (int p = 0; p < total; p++) {
      final start = p * stepsPerPage;
      final end = min(start + stepsPerPage, nailPath.length - 1);

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('ThreadCRAFT — Thread Guide',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        color: PdfColors.deepPurple900)),
                pw.Text('Steps ${start + 1}–$end of ${nailPath.length}',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Container(
                height: 1.5,
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                color: PdfColors.deepPurple900),
            pw.Wrap(
              spacing: 6,
              runSpacing: 5,
              children: List.generate(end - start, (i) {
                final sn = start + i + 1;
                final from = nailPath[start + i] + 1;
                final to = nailPath[start + i + 1] + 1;
                return pw.Container(
                  width: 160,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 7, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: sn % 2 == 0
                        ? PdfColors.deepPurple50
                        : PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(3),
                    border: pw.Border.all(
                        color: PdfColors.deepPurple100, width: 0.5),
                  ),
                  child: pw.Row(children: [
                    pw.SizedBox(
                        width: 26,
                        child: pw.Text('$sn.',
                            style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey500))),
                    pw.Text('$from',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.deepPurple900)),
                    pw.SizedBox(width: 4),
                    pw.Text('→',
                        style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey500)),
                    pw.SizedBox(width: 4),
                    pw.Text('$to',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.pink700)),
                  ]),
                );
              }),
            ),
          ],
        ),
      ));
    }
  }
}