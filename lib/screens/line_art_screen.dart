import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../features/line_art/line_art_painter.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';

class LineArtScreen extends StatefulWidget {
  final File imageFile;
  final List<int> nailPath;
  final int nailCount;
  final String shape;
  final String? projectId;
  final int startStep;

  const LineArtScreen({
    super.key,
    required this.imageFile,
    required this.nailPath,
    required this.nailCount,
    required this.shape,
    this.projectId,
    this.startStep = 0,
  });

  @override
  State<LineArtScreen> createState() =>
      _LineArtScreenState();
}

class _LineArtScreenState extends State<LineArtScreen> {
  int _stepIndex = 0;
  bool _isPaused = false;
  bool _showBackground = true;
  ui.Image? _bgImage;

  // Auto advance
  Timer? _autoTimer;
  bool _autoAdvance = false;
  int _autoDelay = 4;

  int get _currentNail =>
      widget.nailPath.isEmpty ||
          _stepIndex >= widget.nailPath.length
          ? 0
          : widget.nailPath[_stepIndex];

  int get _nextNail =>
      widget.nailPath.isEmpty ||
          _stepIndex + 1 >= widget.nailPath.length
          ? _currentNail
          : widget.nailPath[_stepIndex + 1];

  double get _progress =>
      widget.nailPath.isEmpty
          ? 0
          : _stepIndex / (widget.nailPath.length - 1);

  bool get _isFinished =>
      _stepIndex >= widget.nailPath.length - 2;

  List<int> get _completedPath =>
      widget.nailPath.sublist(
          0, (_stepIndex + 1)
          .clamp(0, widget.nailPath.length));

  @override
  void initState() {
    super.initState();
    _stepIndex = widget.startStep;
    _loadImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();
      setState(() {
        _autoAdvance = settings.autoAdvance;
        _autoDelay = settings.autoDelay;
      });
      if (_autoAdvance) _startTimer();
    });
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec =
    await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _bgImage = frame.image);
  }

  void _nextStep() {
    if (_isFinished) return;
    HapticFeedback.lightImpact();
    setState(() => _stepIndex++);
    context
        .read<VoiceService>()
        .speakStep(_currentNail, _nextNail);
  }

  void _prevStep() {
    if (_stepIndex <= 0) return;
    HapticFeedback.lightImpact();
    setState(() => _stepIndex--);
  }

  void _startTimer() {
    _cancelTimer();
    if (!_autoAdvance || _isPaused) return;
    _autoTimer = Timer(Duration(seconds: _autoDelay),
            () {
          if (mounted && _autoAdvance && !_isPaused) {
            _nextStep();
            _startTimer();
          }
        });
  }

  void _cancelTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () =>
              Navigator.pop(context, _stepIndex),
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
          'Line Art Guide',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Background toggle button
          GestureDetector(
            onTap: () => setState(
                    () => _showBackground = !_showBackground),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showBackground
                    ? AppColors.cyan.withOpacity(0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _showBackground
                      ? AppColors.cyan.withOpacity(0.4)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Icon(
                _showBackground
                    ? Icons.image_rounded
                    : Icons.image_not_supported_outlined,
                color: _showBackground
                    ? AppColors.cyan
                    : AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── CANVAS ──
          Expanded(child: _buildCanvas()),

          // ── BOTTOM PANEL ──
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          size: Size.infinite,
          painter: LineArtPainter(
            nailCount: widget.nailCount,
            shape: widget.shape,
            completedPath: _completedPath,
            currentNail: _currentNail,
            nextNail: _nextNail,
            backgroundImage: _bgImage,
            showBackground: _showBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding:
      const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        children: [
          // Art type label
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                  AppColors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.show_chart,
                    color: AppColors.cyan, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Line Art Mode',
                  style: GoogleFonts.poppins(
                      color: AppColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Step display
          Text('Current Line',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 11)),

          const SizedBox(height: 4),

          _isFinished
              ? ShaderMask(
            shaderCallback: (b) =>
                AppColors.coolGradient
                    .createShader(b),
            child: Text('✓ Complete!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                )),
          )
              : Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.coolGradient
                        .createShader(b),
                child: Text(
                  '${_currentNail + 1}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  .animate(
                  key: ValueKey(_stepIndex))
                  .fadeIn(duration: 200.ms),
              Padding(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 12),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.textMuted,
                    size: 24),
              ),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.coolGradient
                        .createShader(b),
                child: Text(
                  '${_nextNail + 1}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  .animate(
                  key: ValueKey(
                      'n$_stepIndex'))
                  .fadeIn(duration: 200.ms),
            ],
          ),

          const SizedBox(height: 12),

          // Progress
          Row(
            children: [
              Text(
                '${widget.nailPath.length} lines total',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 11),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor:
                  Colors.white.withOpacity(0.08),
                  valueColor:
                  const AlwaysStoppedAnimation(
                      AppColors.cyan),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Controls
          Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              _ctrlBtn(Icons.arrow_back, 'Back',
                  _stepIndex > 0, _prevStep),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  setState(
                          () => _isPaused = !_isPaused);
                  if (_isPaused) {
                    _cancelTimer();
                  } else if (_autoAdvance) {
                    _startTimer();
                  }
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyan,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan
                            .withOpacity(0.4),
                        blurRadius: 18,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(
                    _isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _ctrlBtn(Icons.arrow_forward, 'Next',
                  !_isFinished, _nextStep),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 400.ms);
  }

  Widget _ctrlBtn(IconData icon, String label,
      bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
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
                  color: AppColors.textMuted,
                  fontSize: 10)),
        ],
      ),
    );
  }
}