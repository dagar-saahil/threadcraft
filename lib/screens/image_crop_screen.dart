import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'generating_screen.dart';

class ImageCropScreen extends StatefulWidget {
  final File imageFile;
  final int nailCount;
  final String shape;
  final String density;
  final String artType;
  final Color threadColor;
  const ImageCropScreen({
    super.key,
    required this.imageFile,
    required this.nailCount,
    required this.shape,
    required this.density,
    this.artType = 'Thread Art',
    this.threadColor = Colors.white,
  });

  @override
  State<ImageCropScreen> createState() =>
      _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen>
    with SingleTickerProviderStateMixin {

  // ── Transform values ──
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _rotation = 0.0;

  // ── Saved at START of each gesture ──
  Offset _savedOffset = Offset.zero;
  double _savedScale = 1.0;
  double _savedRotation = 0.0;
  Offset _savedFocalPoint = Offset.zero;

  // ── Rotation slider value ──
  double _sliderRotation = 0.0;

  // ── For capturing screenshot ──
  final GlobalKey _repaintKey = GlobalKey();

  bool _isProcessing = false;

  // ── Border pulse animation ──
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════
  // GESTURE HANDLERS — THE KEY FIX!
  // ════════════════════════════════════

  void _onScaleStart(ScaleStartDetails details) {
    // Save current state at the START of gesture
    _savedOffset = _offset;
    _savedScale = _scale;
    _savedRotation = _rotation;
    _savedFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // ── PAN: move by how much focal point moved ──
      final focalDelta =
          details.focalPoint - _savedFocalPoint;
      _offset = _savedOffset + focalDelta;

      // ── ZOOM: multiply saved scale by gesture scale ──
      _scale = (_savedScale * details.scale)
          .clamp(0.3, 6.0);

      // ── ROTATE: add gesture rotation to saved ──
      if (details.pointerCount >= 2) {
        final newRotation =
            _savedRotation + details.rotation;
        // Keep between -45 and +45 degrees
        _rotation =
            newRotation.clamp(-pi / 4, pi / 4);
        // Sync slider to match gesture rotation
        _sliderRotation = _rotation;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // Nothing needed — state is already saved
  }

  // ════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════

  void _resetAll() {
    setState(() {
      _offset = Offset.zero;
      _scale = 1.0;
      _rotation = 0.0;
      _sliderRotation = 0.0;
    });
  }

  // Crop rect — where the frame sits on screen
  Rect _getCropRect(Size screen) {
    const topH = 90.0;
    const bottomH = 200.0;
    final avail = screen.height - topH - bottomH;
    const pad = 24.0;

    switch (widget.shape) {
      case 'Square':
        final sz =
        min(screen.width - pad * 2, avail);
        return Rect.fromLTWH(
          (screen.width - sz) / 2,
          topH + (avail - sz) / 2,
          sz,
          sz,
        );
      case 'Rectangle':
        final w = screen.width - pad * 2;
        final h = w * 0.65;
        return Rect.fromLTWH(
          pad,
          topH + (avail - h) / 2,
          w,
          h,
        );
      default: // Circle
        final sz =
        min(screen.width - pad * 2, avail);
        return Rect.fromLTWH(
          (screen.width - sz) / 2,
          topH + (avail - sz) / 2,
          sz,
          sz,
        );
    }
  }

  // ════════════════════════════════════
  // BUILD
  // ════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final cropRect = _getCropRect(screen);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ── LAYER 1: IMAGE (gesture controlled) ──
          // GestureDetector wraps everything
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: SizedBox(
              width: screen.width,
              height: screen.height,

              // RepaintBoundary for screenshot
              child: RepaintBoundary(
                key: _repaintKey,
                child: Stack(
                  children: [
                    // Black background
                    Container(color: Colors.black),

                    // The image with transforms
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(
                            _offset.dx, _offset.dy)
                        ..scale(_scale)
                        ..rotateZ(_rotation),
                      child: SizedBox(
                        width: screen.width,
                        height: screen.height,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── LAYER 2: DARK OVERLAY + SHAPE HOLE ──
          IgnorePointer(
            child: CustomPaint(
              size: Size(screen.width, screen.height),
              painter: _OverlayPainter(
                cropRect: cropRect,
                shape: widget.shape,
              ),
            ),
          ),

          // ── LAYER 3: GLOWING BORDER ──
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => CustomPaint(
                size:
                Size(screen.width, screen.height),
                painter: _BorderPainter(
                  cropRect: cropRect,
                  shape: widget.shape,
                  pulse: _pulseController.value,
                ),
              ),
            ),
          ),

          // ── LAYER 4: TOP BAR ──
          SafeArea(child: _buildTopBar()),

          // ── LAYER 5: BOTTOM CONTROLS ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(cropRect, screen),
          ),

          // ── LAYER 6: LOADING OVERLAY ──
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.purple,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cropping image...',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  // TOP BAR
  // ════════════════════════════════════

  Widget _buildTopBar() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [

          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white
                        .withOpacity(0.15)),
              ),
              child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16),
            ),
          ),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius:
              BorderRadius.circular(20),
              border: Border.all(
                  color:
                  Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              'Position Your Image',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Reset button
          GestureDetector(
            onTap: _resetAll,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white
                        .withOpacity(0.15)),
              ),
              child: const Icon(Icons.refresh,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ════════════════════════════════════
  // BOTTOM BAR
  // ════════════════════════════════════

  Widget _buildBottomBar(
      Rect cropRect, Size screen) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          20, 16, 20, 36),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.88),
        border: Border(
          top: BorderSide(
              color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── HINT CHIPS ──
          Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              _hintChip(
                  Icons.pinch_outlined,
                  'Pinch to zoom'),
              const SizedBox(width: 12),
              _hintChip(
                  Icons.pan_tool_alt_outlined,
                  'Drag to move'),
            ],
          ),

          const SizedBox(height: 14),

          // ── ROTATION SLIDER ──
          Row(
            children: [
              const Icon(Icons.rotate_left,
                  color: AppColors.textMuted,
                  size: 18),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape:
                    const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    activeTrackColor: AppColors.purple,
                    thumbColor: AppColors.pink,
                    inactiveTrackColor:
                    Colors.white.withOpacity(0.1),
                    overlayShape:
                    SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _sliderRotation,
                    min: -pi / 4, // -45 degrees
                    max: pi / 4,  // +45 degrees
                    onChanged: (val) {
                      setState(() {
                        _sliderRotation = val;
                        _rotation = val;
                      });
                    },
                  ),
                ),
              ),
              const Icon(Icons.rotate_right,
                  color: AppColors.textMuted,
                  size: 18),
            ],
          ),

          // Degree label
          Center(
            child: Text(
              '${(_rotation * 180 / pi).toStringAsFixed(1)}°',
              style: GoogleFonts.poppins(
                color: AppColors.purple,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── CONFIRM BUTTON ──
          GradientButton(
            text: _isProcessing
                ? 'Preparing...'
                : '✦  Confirm & Generate',
            gradient: AppColors.accentGradient,
            isLoading: _isProcessing,
            onTap: () =>
                _confirm(cropRect, screen),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 400.ms);
  }

  Widget _hintChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: AppColors.textSecondary,
              size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 10)),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  // CONFIRM & CROP
  // ════════════════════════════════════

  Future<void> _confirm(
      Rect cropRect, Size screen) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Capture full screen via RepaintBoundary
      final boundary = _repaintKey.currentContext!
          .findRenderObject()
      as RenderRepaintBoundary;

      final fullImage =
      await boundary.toImage(pixelRatio: 2.5);

      // Crop to crop rect area
      final cropped = await _doCrop(
          fullImage, cropRect, screen);

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/tc_crop_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(cropped);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GeneratingScreen(
              imageFile: file,
              nailCount: widget.nailCount,
              shape: widget.shape,
              density: widget.density,
              artType: widget.artType,
              threadColor: widget.threadColor,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(12)),
            content: Text('Failed. Please retry!',
                style: GoogleFonts.poppins(
                    color: Colors.white)),
          ),
        );
      }
    }
  }

  Future<Uint8List> _doCrop(
      ui.Image fullImage,
      Rect cropRect,
      Size screen,
      ) async {
    final pixelRatio = 2.5;
    final scaleX =
        fullImage.width / (screen.width * pixelRatio)
            * pixelRatio;
    final scaleY =
        fullImage.height / (screen.height * pixelRatio)
            * pixelRatio;

    final srcRect = Rect.fromLTWH(
      cropRect.left * scaleX,
      cropRect.top * scaleY,
      cropRect.width * scaleX,
      cropRect.height * scaleY,
    );

    final outSize = 800.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, outSize, outSize),
      Paint()..color = Colors.white,
    );

    // Clip to shape
    if (widget.shape == 'Circle') {
      canvas.clipPath(Path()
        ..addOval(
            Rect.fromLTWH(0, 0, outSize, outSize)));
    }

    // Draw cropped image
    canvas.drawImageRect(
      fullImage,
      srcRect,
      Rect.fromLTWH(0, 0, outSize, outSize),
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final result = await picture.toImage(
        outSize.toInt(), outSize.toInt());
    final data = await result.toByteData(
        format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}

// ════════════════════════════════════
// DARK OVERLAY PAINTER
// ════════════════════════════════════

class _OverlayPainter extends CustomPainter {
  final Rect cropRect;
  final String shape;

  const _OverlayPainter({
    required this.cropRect,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.68);

    final full = Path()
      ..addRect(
          Rect.fromLTWH(0, 0, size.width, size.height));

    final hole = Path();
    if (shape == 'Circle') {
      hole.addOval(cropRect);
    } else {
      hole.addRRect(
        RRect.fromRectAndRadius(
            cropRect, const Radius.circular(8)),
      );
    }

    canvas.drawPath(
      Path.combine(
          PathOperation.difference, full, hole),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.shape != shape;
}

// ════════════════════════════════════
// GLOWING BORDER PAINTER
// ════════════════════════════════════

class _BorderPainter extends CustomPainter {
  final Rect cropRect;
  final String shape;
  final double pulse;

  const _BorderPainter({
    required this.cropRect,
    required this.shape,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeW = 1.5 + pulse * 0.8;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.purple,
          AppColors.pink,
          AppColors.orange,
          AppColors.purple,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(cropRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, 2 + pulse * 2);

    if (shape == 'Circle') {
      canvas.drawOval(cropRect, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            cropRect, const Radius.circular(8)),
        paint,
      );
    }

    // Rule of thirds grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(
            cropRect.left + cropRect.width * i / 3,
            cropRect.top),
        Offset(
            cropRect.left + cropRect.width * i / 3,
            cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left,
            cropRect.top + cropRect.height * i / 3),
        Offset(cropRect.right,
            cropRect.top + cropRect.height * i / 3),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BorderPainter old) =>
      old.pulse != pulse;
}