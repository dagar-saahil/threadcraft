import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  static Future<void> exportNailMap({
    required BuildContext context,
    required int nailCount,
    required String shape,
    required List<int> nailPath,
    required String density,
  }) async {
    try {
      final pdf = pw.Document();

      // ── PAGE 1: NAIL MAP ──
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.center,
              children: [
                _buildHeader(nailCount, shape, density),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: _buildNailMapWidget(
                      nailCount, shape),
                ),
                pw.SizedBox(height: 20),
                _buildInfoRow(
                    nailCount, nailPath.length, shape),
                pw.SizedBox(height: 14),
                _buildTips(shape),
              ],
            );
          },
        ),
      );

      // ── PAGE 2+: STEP LIST ──
      final stepsPerPage = 54;
      final totalStepPages =
      ((nailPath.length - 1) / stepsPerPage).ceil();

      for (int page = 0; page < totalStepPages; page++) {
        final start = page * stepsPerPage;
        final end = min(
            start + stepsPerPage, nailPath.length - 1);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context ctx) {
              return pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment.start,
                children: [
                  // Page header
                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'ThreadCRAFT — Step List',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepPurple900,
                        ),
                      ),
                      pw.Text(
                        'Page ${page + 2} of ${totalStepPages + 1}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),

                  pw.Container(
                    height: 2,
                    margin: const pw.EdgeInsets.symmetric(
                        vertical: 8),
                    decoration: pw.BoxDecoration(
                      gradient: const pw.LinearGradient(
                        colors: [
                          PdfColors.deepPurple700,
                          PdfColors.pink300,
                        ],
                      ),
                    ),
                  ),

                  pw.Text(
                    'Steps ${start + 1} to $end',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Steps in 3-column grid
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: List.generate(
                      end - start,
                          (i) {
                        final stepNum = start + i + 1;
                        final from = nailPath[start + i] + 1;
                        final to =
                            nailPath[start + i + 1] + 1;
                        final isEven = stepNum % 2 == 0;

                        return pw.Container(
                          width: 158,
                          padding:
                          const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: isEven
                                ? PdfColors.deepPurple50
                                : PdfColors.white,
                            borderRadius:
                            pw.BorderRadius.circular(4),
                            border: pw.Border.all(
                              color: PdfColors.deepPurple100,
                              width: 0.5,
                            ),
                          ),
                          child: pw.Row(
                            children: [
                              // Step number
                              pw.Container(
                                width: 30,
                                child: pw.Text(
                                  '$stepNum.',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey500,
                                  ),
                                ),
                              ),
                              // From nail
                              pw.Text(
                                '$from',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                  pw.FontWeight.bold,
                                  color: PdfColors
                                      .deepPurple900,
                                ),
                              ),
                              pw.SizedBox(width: 4),
                              pw.Text(
                                '→',
                                style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey500,
                                ),
                              ),
                              pw.SizedBox(width: 4),
                              // To nail
                              pw.Text(
                                '$to',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                  pw.FontWeight.bold,
                                  color: PdfColors.pink700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save and share
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/ThreadCRAFT_${shape}_${nailCount}nails.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ThreadCRAFT Nail Map',
        text:
        'My ThreadCRAFT nail map — $nailCount nails, $shape frame',
      );
    } catch (e) {
      debugPrint('PDF error: $e');
      rethrow;
    }
  }

  // ── NAIL MAP AS WIDGETS (no low-level canvas) ──
  static pw.Widget _buildNailMapWidget(
      int nailCount, String shape) {
    const mapSize = 380.0;
    const padding = 30.0;

    return pw.Container(
      width: mapSize,
      height: mapSize,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey200,
          width: 0.5,
        ),
      ),
      child: pw.Stack(
        children: [
          // Shape outline
          pw.Center(
            child: _buildShapeOutline(
                shape, mapSize, padding),
          ),

          // Nail dots + numbers
          ..._buildNailWidgets(
              nailCount, shape, mapSize, padding),

          // Center dot
          pw.Center(
            child: pw.Container(
              width: 4,
              height: 4,
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey400,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SHAPE OUTLINE ──
  static pw.Widget _buildShapeOutline(
      String shape, double size, double padding) {
    final inner = size - padding * 2;

    if (shape == 'Circle') {
      return pw.Container(
        width: inner,
        height: inner,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(
            color: PdfColors.deepPurple900,
            width: 1.5,
          ),
        ),
      );
    } else if (shape == 'Rectangle') {
      return pw.Container(
        width: inner,
        height: inner * 0.65,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.deepPurple900,
            width: 1.5,
          ),
        ),
      );
    } else {
      // Square
      return pw.Container(
        width: inner,
        height: inner,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.deepPurple900,
            width: 1.5,
          ),
        ),
      );
    }
  }

  // ── NAIL DOTS + NUMBERS ──
  static List<pw.Widget> _buildNailWidgets(
      int nailCount,
      String shape,
      double size,
      double padding,
      ) {
    final widgets = <pw.Widget>[];
    final nails =
    _getNailPositions(nailCount, shape, size, padding);

    for (int i = 0; i < nails.length; i++) {
      final pos = nails[i];

      // Nail dot
      widgets.add(
        pw.Positioned(
          left: pos.dx - 2.5,
          top: pos.dy - 2.5,
          child: pw.Container(
            width: 5,
            height: 5,
            decoration: const pw.BoxDecoration(
              color: PdfColors.deepPurple900,
              shape: pw.BoxShape.circle,
            ),
          ),
        ),
      );

      // Number label (every 5th nail)
      if (i % 5 == 0) {
        final cx = size / 2;
        final cy = size / 2;
        final dx = pos.dx - cx;
        final dy = pos.dy - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final nx = dist > 0 ? dx / dist : 0.0;
        final ny = dist > 0 ? dy / dist : 0.0;

        // Place number 12px outside nail
        final lx = pos.dx + nx * 12;
        final ly = pos.dy + ny * 12;

        // Clamp to stay in bounds
        final clampedX =
        lx.clamp(2.0, size - 14).toDouble();
        final clampedY =
        ly.clamp(2.0, size - 10).toDouble();

        widgets.add(
          pw.Positioned(
            left: clampedX,
            top: clampedY,
            child: pw.Text(
              '${i + 1}',
              style: const pw.TextStyle(
                fontSize: 6,
                color: PdfColors.deepPurple700,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // ── NAIL POSITIONS CALCULATOR ──
  static List<Offset> _getNailPositions(
      int nailCount,
      String shape,
      double size,
      double padding,
      ) {
    final cx = size / 2;
    final cy = size / 2;
    final nails = <Offset>[];

    switch (shape) {
      case 'Square':
        final w = size - padding * 2;
        final h = size - padding * 2;
        final perSide = nailCount ~/ 4;
        final extra = nailCount - perSide * 4;

        for (int i = 0; i < perSide; i++) {
          nails.add(
              Offset(padding + w * i / perSide, padding));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              size - padding, padding + h * i / perSide));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              size - padding - w * i / perSide,
              size - padding));
        }
        for (int i = 0; i < perSide + extra; i++) {
          nails.add(Offset(padding,
              size - padding - h * i / (perSide + extra)));
        }
        break;

      case 'Rectangle':
        final w = size - padding * 2;
        final h = (size - padding * 2) * 0.65;
        final offsetY = (size - h) / 2;
        final perimeter = 2 * w + 2 * h;
        final topCount =
        (nailCount * w / perimeter).round();
        final sideCount =
        (nailCount * h / perimeter).round();

        for (int i = 0; i < topCount; i++) {
          nails.add(Offset(
              padding + w * i / max(topCount - 1, 1),
              offsetY));
        }
        for (int i = 0; i < sideCount; i++) {
          nails.add(Offset(size - padding,
              offsetY + h * i / max(sideCount - 1, 1)));
        }
        for (int i = 0; i < topCount; i++) {
          nails.add(Offset(
              size - padding -
                  w * i / max(topCount - 1, 1),
              offsetY + h));
        }
        final leftCount = nailCount - nails.length;
        for (int i = 0; i < leftCount; i++) {
          nails.add(Offset(
              padding,
              offsetY +
                  h -
                  h * i / max(leftCount - 1, 1)));
        }
        break;

      default: // Circle
        final radius = min(cx, cy) - padding;
        for (int i = 0; i < nailCount; i++) {
          final angle =
              (2 * pi * i / nailCount) - (pi / 2);
          nails.add(Offset(
            cx + radius * cos(angle),
            cy + radius * sin(angle),
          ));
        }
    }

    return nails.take(nailCount).toList();
  }

  // ── HEADER ──
  static pw.Widget _buildHeader(
      int nailCount, String shape, String density) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.deepPurple900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ThreadCRAFT',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Professional Thread Art Guide',
                style: const pw.TextStyle(
                  color: PdfColors.purple200,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '$nailCount Nails',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '$shape • $density',
                style: const pw.TextStyle(
                  color: PdfColors.purple200,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── INFO ROW ──
  static pw.Widget _buildInfoRow(
      int nailCount, int steps, String shape) {
    return pw.Row(
      mainAxisAlignment:
      pw.MainAxisAlignment.spaceAround,
      children: [
        _infoBox('Shape', shape),
        _infoBox('Total Nails', '$nailCount'),
        _infoBox('Total Steps', '$steps'),
        _infoBox('Start From', 'Nail 1'),
      ],
    );
  }

  static pw.Widget _infoBox(
      String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.deepPurple50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: PdfColors.deepPurple200,
          width: 0.5,
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.deepPurple900,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // ── TIPS ──
  static pw.Widget _buildTips(String shape) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: PdfColors.amber300,
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💡 How to Use This PDF',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '• Print at 100% scale (no "fit to page")',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '• Use nail map page as template for your board',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '• Start winding thread from Nail 1',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '• Nails go ${shape == "Circle" ? "clockwise from top" : "top-left, clockwise"}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '• Follow the step list pages in order',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}