import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../features/thread_art/canvas/nail_ring_painter.dart';
import '../services/voice_service.dart';
import '../widgets/glow_card.dart';
import 'voice_guide_screen.dart';
import 'package:provider/provider.dart';
import '../services/project_service.dart';
import '../widgets/neon_toggle.dart';
import '../services/settings_service.dart';
class WorkModeScreen extends StatefulWidget {
  final File imageFile;
  final List<int> nailPath;
  final int nailCount;
  final String shape;
  final String? projectId;
  final int startStep;
  final bool showBackground;    // ← NEW
  final bool useColorThread;    // ← NEW
  final Color threadColor;


  const WorkModeScreen({
    super.key,
    required this.imageFile,
    required this.nailPath,
    required this.nailCount,
    required this.shape,
    this.projectId,
    this.startStep = 0,
    this.showBackground = true,    // ← NEW
    this.useColorThread = true,    // ← NEW
    this.threadColor = Colors.white,
  });

  @override
  State<WorkModeScreen> createState() => _WorkModeScreenState();
}
// Auto advance timer
bool _autoAdvance = false;
int _autoDelay = 4;
Timer? _advanceTimer; // ← proper Timer type
bool _autoVoiceSpoken = false; // prevents double speak
class _WorkModeScreenState extends State<WorkModeScreen>
    with SingleTickerProviderStateMixin {

  // ── STATE ──
  int _stepIndex = 0;       // which step user is on
  bool _isPaused = false;
  bool _isLightMode = false;
  double _speed = 1.0;
  late bool _showBackground;
  late bool _useColorThread;  // ← NEW
  ui.Image? _bgImage;       // decoded image for canvas


  // Completed path shown on canvas
  List<int> get _completedPath =>
      widget.nailPath.sublist(0, _stepIndex + 1);

  // Current and next nail numbers
  int get _currentNail => widget.nailPath[_stepIndex];
  int get _nextNail =>
      _stepIndex < widget.nailPath.length - 1
          ? widget.nailPath[_stepIndex + 1]
          : widget.nailPath[_stepIndex];

  // Progress percent
  double get _progress =>
      widget.nailPath.isEmpty ? 0
          : _stepIndex / (widget.nailPath.length - 1);

  @override
  void initState() {
    super.initState();
    _stepIndex = widget.startStep;
    _showBackground = widget.showBackground;
    _useColorThread = widget.useColorThread;
    _useColorThread = false; //hehehe
    // Load auto advance settings from saved prefs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();
      setState(() {
        _autoAdvance = settings.autoAdvance;
        _autoDelay = settings.autoDelay;
      });
      // Start timer if it was enabled
      if (_autoAdvance) _startAutoTimer();
    });

    _loadImage();
  }

// Get voice from provider (shared instance)
  VoiceService get _voice =>
      context.read<VoiceService>();

  // Load the image for the canvas
  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _bgImage = frame.image);
    }
  }

  // ── GO TO NEXT STEP ──
  void _nextStep() {
    if (_stepIndex >= widget.nailPath.length - 2) return;
    HapticFeedback.lightImpact();

    setState(() => _stepIndex++);

    // Speak the step (VoiceService handles overlap prevention)
    context.read<VoiceService>()
        .speakStep(_currentNail, _nextNail);

    _saveProgress();

    // DO NOT cancel timer here —
    // timer restarts itself after each step
  }

  // ── GO BACK ONE STEP ──
  void _prevStep() {
    if (_stepIndex <= 0) return;
    HapticFeedback.lightImpact();
    setState(() => _stepIndex--);
    _saveProgress();
    _cancelAutoTimer();
  }
  // ── SAVE PROGRESS TO PROJECT SERVICE ──
  void _saveProgress() {
    if (widget.projectId == null) return;

    // Save every 10 steps to avoid too many writes
    if (_stepIndex % 10 != 0) return;

    try {
      context
          .read<ProjectService>()
          .updateProgress(widget.projectId!, _stepIndex);
    } catch (e) {
      debugPrint('Auto-save error: $e');
    }
  }
  // ── MANUAL SAVE FROM TOP BAR ──
  Future<void> _saveCurrentProgress() async {
    if (widget.projectId == null) {
      _showSaveSnack('No project ID — try generating again');
      return;
    }

    try {
      await context
          .read<ProjectService>()
          .updateProgress(widget.projectId!, _stepIndex);

      _showSaveSnack(
          'Saved at step ${_stepIndex + 1} ✅');
    } catch (e) {
      _showSaveSnack('Save failed!');
    }
  }

  void _showSaveSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.purple, size: 16),
            const SizedBox(width: 8),
            Text(msg,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
  // ── START AUTO TIMER ──
  // ── START AUTO ADVANCE TIMER ──
  void _startAutoTimer() {
    _cancelAutoTimer(); // always cancel old one first!

    if (!_autoAdvance || _isPaused) return;

    // ONE timer — fires once after delay
    _advanceTimer = Timer(
      Duration(seconds: _autoDelay),
          () {
        // Only advance if still mounted + active
        if (!mounted) return;
        if (!_autoAdvance) return;
        if (_isPaused) return;

        _nextStep();

        // Schedule the NEXT step
        _startAutoTimer();
      },
    );
  }

// ── CANCEL TIMER CLEANLY ──
  void _cancelAutoTimer() {
    _advanceTimer?.cancel(); // safe cancel
    _advanceTimer = null;
  }



  @override
  void dispose() {
    _cancelAutoTimer(); // ← always cancel on exit!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _stepIndex >= widget.nailPath.length - 2;

    return Scaffold(
      backgroundColor: _isLightMode
          ? const Color(0xFFF5F5F5)
          : AppColors.background,

      // ── TOP BAR ──
      appBar: AppBar(
        backgroundColor: _isLightMode
            ? const Color(0xFFF5F5F5)
            : AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context, _stepIndex),
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
          'Work In Progress',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Save button
          GestureDetector(
            onTap: _saveCurrentProgress,
            child: Container(
              margin: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.save_outlined,
                      color: AppColors.purple, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      color: AppColors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Settings
          IconButton(
            icon: const Icon(Icons.tune,
                color: Colors.white),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),

      body: Column(
        children: [

          // ── CANVAS AREA ──
          Expanded(
            child: _buildCanvas(),
          ),

          // ── BOTTOM PANEL ──
          _buildBottomPanel(isFinished),
        ],
      ),
    );
  }

  // ── CANVAS ──
  Widget _buildCanvas() {
    if (widget.nailPath.isEmpty) {
      return const Center(
        child: Text('No path generated',
            style: TextStyle(color: Colors.white)),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          size: Size.infinite,
          painter: NailRingPainter(
            nailCount: widget.nailCount,
            completedPath: _completedPath,
            currentNail: _currentNail,
            nextNail: _nextNail,
            backgroundImage: _bgImage,
            shape: widget.shape,
            showBackground: _showBackground,   // ← NEW
            useColorThread: _useColorThread,   // ← NEW
            singleThreadColor: widget.threadColor,
          ),
        ),
      ),
    );
  }

  // ── BOTTOM PANEL ──
  Widget _buildBottomPanel(bool isFinished) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [

          // ── STEP DISPLAY ──
          _buildStepDisplay(isFinished),

          const SizedBox(height: 16),

          // ── STATS ROW ──
          _buildStatsRow(),

          const SizedBox(height: 20),

          // ── MAIN CONTROLS ──
          _buildMainControls(isFinished),

          const SizedBox(height: 16),

          // ── QUICK CONTROLS ──
          _buildQuickControls(),
        ],
      ),
    );
  }

  // ── STEP DISPLAY — "56 → 89" ──
  Widget _buildStepDisplay(bool isFinished) {
    return Column(
      children: [
        Text(
          'Current Step',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        isFinished
            ? ShaderMask(
          shaderCallback: (b) =>
              AppColors.accentGradient.createShader(b),
          child: Text(
            '🎉 Complete!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Current nail number
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.primaryGradient.createShader(b),
              child: Text(
                '${_currentNail + 1}',   // ← starts from 1
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                .animate(key: ValueKey(_stepIndex))
                .fadeIn(duration: 200.ms)
                .slideX(begin: -0.2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.arrow_forward,
                  color: AppColors.textMuted, size: 28),
            ),

            // Next nail number
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.accentGradient.createShader(b),
              child: Text(
                '${_nextNail + 1}',   // ← starts from 1
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                .animate(key: ValueKey('n$_stepIndex'))
                .fadeIn(duration: 200.ms)
                .slideX(begin: 0.2),
          ],
        ),
      ],
    );
  }

  // ── STATS ROW ──
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Total Steps
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Steps',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                '${widget.nailPath.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Progress bar (middle)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(AppColors.purple),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        // Progress %
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.accentGradient.createShader(b),
                child: Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MAIN CONTROLS (Back / Pause / Next) ──
  Widget _buildMainControls(bool isFinished) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        // BACK button
        _controlButton(
          icon: Icons.arrow_back,
          label: 'Back',
          size: 52,
          onTap: _prevStep,
          enabled: _stepIndex > 0,
        ),

        const SizedBox(width: 20),

        // PAUSE / PLAY big button
        GestureDetector(
          onTap: () {
            setState(() => _isPaused = !_isPaused);

            if (_isPaused) {
              // Paused → stop timer + stop voice
              _cancelAutoTimer();
              context.read<VoiceService>().stop();
            } else {
              // Resumed → restart timer if auto advance on
              if (_autoAdvance) {
                _startAutoTimer();
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleGlow,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),

        const SizedBox(width: 20),

        // NEXT button
        _controlButton(
          icon: Icons.arrow_forward,
          label: 'Next',
          size: 52,
          onTap: _nextStep,
          enabled: !isFinished,
        ),
      ],
    );
  }

  // Reusable round control button
  Widget _controlButton({
    required IconData icon,
    required String label,
    required double size,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.03),
              ),
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.white : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK CONTROLS ROW ──
  Widget _buildQuickControls() {
    final voice = context.read<VoiceService>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [

        // Voice toggle
        _quickControl(
          icon: voice.isEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          label: 'Voice',
          isActive: voice.isEnabled,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VoiceGuideScreen(),
              ),
            );
          },
        ),

        // Repeat — speaks current step again
        _quickControl(
          icon: Icons.repeat_rounded,
          label: 'Repeat',
          onTap: () {
            // Force speak even if off temporarily
            final v = context.read<VoiceService>();
            final wasOff = !v.isEnabled;
            if (wasOff) v.setEnabled(true);
            v.speakStep(_currentNail, _nextNail);
            if (wasOff) {
              Future.delayed(
                const Duration(seconds: 3),
                    () => v.setEnabled(false),
              );
            }
          },
        ),

        // Speed
        _quickControl(
          icon: Icons.speed_rounded,
          label: '${_speed}x',
          onTap: _cycleSpeed,
        ),

        // Light mode toggle
        _quickControl(
          icon: _isLightMode
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          label: 'Light',
          isActive: _isLightMode,
          onTap: () => setState(() => _isLightMode = !_isLightMode),
        ),
      ],
    );
  }

  Widget _quickControl({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.purple.withOpacity(0.2)
                  : AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? AppColors.purple.withOpacity(0.5)
                    : Colors.white.withOpacity(0.08),
              ),
              boxShadow: isActive
                  ? [BoxShadow(
                  color: AppColors.purpleGlow, blurRadius: 10)]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.purple : AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── CYCLE SPEED ──
  void _cycleSpeed() {
    final speeds = [0.5, 1.0, 1.5, 2.0];
    final idx = speeds.indexOf(_speed);
    final next = speeds[(idx + 1) % speeds.length];
    setState(() => _speed = next);
    context.read<VoiceService>().setSpeed(next);
  }

  // ── SETTINGS BOTTOM SHEET ──
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
        builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Project Info',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GlowCard(
              child: Column(
                children: [
                  _infoRow('Total Nails', '${widget.nailCount}'),
                  _infoRow('Shape', widget.shape),
                  _infoRow('Total Steps', '${widget.nailPath.length}'),
                  _infoRow('Completed', '$_stepIndex'),
                  _infoRow(
                    'Progress',
                    '${(_progress * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),


            const SizedBox(height: 16),

// ── CANVAS OPTIONS ──
                    // ── CANVAS OPTIONS ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Canvas Options',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Show/Hide background toggle
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.image_outlined,
                                      color: AppColors.cyan, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Show Photo Background',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              NeonToggle(
                                value: _showBackground,
                                activeColor: AppColors.cyan,
                                onChanged: (val) {
                                  // Update canvas immediately — no sheet close
                                  setState(() => _showBackground = val);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Color thread toggle
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.palette_outlined,
                                      color: AppColors.pink, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Colorful Thread',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              NeonToggle(
                                value: _useColorThread,
                                activeColor: AppColors.pink,
                                onChanged: (val) {
                                  // Update canvas immediately — no sheet close
                                  setState(() => _useColorThread = val);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Status hint
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _useColorThread
                                      ? Icons.auto_awesome
                                      : Icons.circle,
                                  color: _useColorThread
                                      ? AppColors.purple
                                      : AppColors.textMuted,
                                  size: 13,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _useColorThread
                                        ? 'Colorful threads'
                                        : 'Black thread',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _showBackground
                                      ? Icons.image
                                      : Icons.image_not_supported_outlined,
                                  color: _showBackground
                                      ? AppColors.cyan
                                      : AppColors.textMuted,
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _showBackground
                                        ? 'Photo visible'
                                        : 'Clean canvas',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}