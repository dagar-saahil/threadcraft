import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../features/dot_art/dot_art_algorithm.dart';

class DotArtScreen extends StatefulWidget {
  final File imageFile;
  final List<DotPoint> dots;
  final String shape;

  const DotArtScreen({
    super.key,
    required this.imageFile,
    required this.dots,
    required this.shape,
  });

  @override
  State<DotArtScreen> createState() => _DotArtScreenState();
}

class _DotArtScreenState extends State<DotArtScreen> {
  int _currentDotIndex = 0;
  ui.Image? _bgImage;

  DotPoint get _current =>
      widget.dots[_currentDotIndex];
  DotPoint? get _next =>
      _currentDotIndex < widget.dots.length - 1
          ? widget.dots[_currentDotIndex + 1]
          : null;

  double get _progress => widget.dots.isEmpty
      ? 0
      : _currentDotIndex / (widget.dots.length - 1);

  bool get _isFinished =>
      _currentDotIndex >= widget.dots.length - 1;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _bgImage = frame.image);
  }

  void _nextDot() {
    if (_isFinished) return;
    HapticFeedback.lightImpact();
    setState(() => _currentDotIndex++);
  }

  void _prevDot() {
    if (_currentDotIndex <= 0) return;
    HapticFeedback.lightImpact();
    setState(() => _currentDotIndex--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
        ),
        title: Text(
          'Dot Art Guide',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── CANVAS ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.06)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DotArtPainter(
                    dots: widget.dots,
                    currentIndex: _currentDotIndex,
                    backgroundImage: _bgImage,
                  ),
                ),
              ),
            ),
          ),

          // ── BOTTOM PANEL ──
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          // Current dot info
          Text('Current Dot',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12)),

          const SizedBox(height: 6),

          _isFinished
              ? ShaderMask(
            shaderCallback: (b) =>
                AppColors.accentGradient.createShader(b),
            child: Text('🎉 Complete!',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
          )
              : Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.primaryGradient
                        .createShader(b),
                child: Text(
                  'Dot ${_current.number}',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (_next != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12),
                  child: Icon(Icons.arrow_forward,
                      color: AppColors.textMuted,
                      size: 24),
                ),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.accentGradient
                          .createShader(b),
                  child: Text(
                    'Dot ${_next!.number}',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Progress row
          Row(
            children: [
              Text('${widget.dots.length} dots',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 11)),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor:
                  Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation(
                      AppColors.orange),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Controls
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
            children: [
              // Back
              GestureDetector(
                onTap: _prevDot,
                child: _controlBtn(
                    Icons.arrow_back, 'Back',
                    _currentDotIndex > 0),
              ),

              // Big next button
              GestureDetector(
                onTap: _nextDot,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.orangeGlow,
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                  child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 30),
                ),
              ),

              // Placeholder for symmetry
              const SizedBox(width: 52),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 400.ms);
  }

  Widget _controlBtn(
      IconData icon, String label, bool enabled) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
            ),
          ),
          child: Icon(icon,
              color: enabled
                  ? Colors.white
                  : AppColors.textMuted,
              size: 20),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.poppins(
                color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ── DOT ART PAINTER ──
class _DotArtPainter extends CustomPainter {
  final List<DotPoint> dots;
  final int currentIndex;
  final ui.Image? backgroundImage;

  _DotArtPainter({
    required this.dots,
    required this.currentIndex,
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background image
    if (backgroundImage != null) {
      final src = Rect.fromLTWH(
        0, 0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      );
      canvas.drawImageRect(
          backgroundImage!,
          src,
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint());
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withOpacity(0.5),
      );
    }

    if (dots.isEmpty) return;

    final scaleX = size.width / 500;
    final scaleY = size.height / 500;

    // Draw connection lines up to current
    if (currentIndex > 0) {
      for (int i = 0; i < currentIndex; i++) {
        final from = dots[i];
        final to = dots[i + 1];
        canvas.drawLine(
          Offset(from.x * scaleX, from.y * scaleY),
          Offset(to.x * scaleX, to.y * scaleY),
          Paint()
            ..color = AppColors.orange.withOpacity(0.5)
            ..strokeWidth = 0.8,
        );
      }
    }

    // Draw all dots
    for (int i = 0; i <= min(currentIndex + 5, dots.length - 1); i++) {
      final dot = dots[i];
      final x = dot.x * scaleX;
      final y = dot.y * scaleY;
      final isCurrent = i == currentIndex;
      final isDone = i < currentIndex;

      // Dot
      canvas.drawCircle(
        Offset(x, y),
        isCurrent ? 8 : (isDone ? 4 : 5),
        Paint()
          ..color = isCurrent
              ? AppColors.orange
              : isDone
              ? AppColors.purple.withOpacity(0.7)
              : Colors.white.withOpacity(0.4),
      );

      // Number
      final tp = TextPainter(
        text: TextSpan(
          text: '${dot.number}',
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.white60,
            fontSize: isCurrent ? 9 : 7,
            fontWeight: isCurrent
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(x - tp.width / 2, y - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_DotArtPainter old) =>
      old.currentIndex != currentIndex;
}