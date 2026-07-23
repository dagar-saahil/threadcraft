import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../features/rgb_art/rgb_ring_painter.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import '../services/project_service.dart';
class RGBWorkModeScreen extends StatefulWidget {
  final File imageFile;
  final List<int> redPath;
  final List<int> greenPath;
  final List<int> bluePath;
  final int nailCount;
  final String shape;
  final String? projectId;
  final int startPhase;
  final int startStep;

  const RGBWorkModeScreen({
    super.key,
    required this.imageFile,
    required this.redPath,
    required this.greenPath,
    required this.bluePath,
    required this.nailCount,
    required this.shape,
    this.projectId,
    this.startPhase = 0,
    this.startStep = 0,
  });

  @override
  State<RGBWorkModeScreen> createState() =>
      _RGBWorkModeScreenState();
}

class _RGBWorkModeScreenState
    extends State<RGBWorkModeScreen>
    with TickerProviderStateMixin {

  // ── Phase: 0=Blue, 1=Red, 2=Green ──
  int _phase = 0;
  int _stepInPhase = 0;
  bool _isPaused = false;

  // ── Voice ──
  bool _voiceOn = false;
  double _voiceSpeed = 1.0;
  String _voiceGender = 'Female';

  // ── Auto advance ──
  bool _autoAdvance = false;
  int _autoDelay = 4;
  Timer? _autoTimer;

  // ── Preview progress ──
  double _previewProgress = 1.0;
  bool _isPreviewingCustom = false; // true when slider moved away from real step

  // ── Canvas options ──
  bool _showBackground = true;

  // ── Loaded image ──
  ui.Image? _bgImage;

  // ── Animation controllers ──
  late AnimationController _phaseGlow;
  late AnimationController _switchAnim;
  bool _showSwitchAlert = false;

  // Phase info
  static const List<String> _phaseNames = [
    'Blue', 'Red', 'Green'
  ];
  static const List<Color> _phaseColors = [
    Colors.blue, Colors.red, Colors.green
  ];
  static const List<String> _phaseEmojis = [
    '🔵', '🔴', '🟢'
  ];

  List<int> get _currentPath {
    switch (_phase) {
      case 0: return widget.bluePath;
      case 1: return widget.redPath;
      default: return widget.greenPath;
    }
  }

  Color get _activeColor => _phaseColors[_phase];
  String get _activeName => _phaseNames[_phase];
  String get _activeEmoji => _phaseEmojis[_phase];

  int get _currentNail =>
      _currentPath.isEmpty ||
          _stepInPhase >= _currentPath.length
          ? 0
          : _currentPath[_stepInPhase];

  int get _nextNail =>
      _stepInPhase + 1 < _currentPath.length
          ? _currentPath[_stepInPhase + 1]
          : _currentNail;

  bool get _isPhaseFinished =>
      _stepInPhase >= _currentPath.length - 2;

  bool get _allDone =>
      _phase >= 2 && _isPhaseFinished;

  double get _phaseProgress =>
      _currentPath.isEmpty
          ? 0
          : (_stepInPhase /
          (_currentPath.length - 1))
          .clamp(0.0, 1.0);
  // Total steps across all 3 phases
  int get _totalSteps =>
      widget.bluePath.length +
          widget.redPath.length +
          widget.greenPath.length;

// Real overall progress (actual position, not preview)
  double get _actualOverallProgress {
    final total = _totalSteps;
    if (total == 0) return 0;
    int done = 0;
    if (_phase > 0) done += widget.bluePath.length;
    if (_phase > 1) done += widget.redPath.length;
    done += _stepInPhase;
    return (done / total).clamp(0.0, 1.0);
  }

  double get _overallProgress {
    final total = widget.bluePath.length +
        widget.redPath.length +
        widget.greenPath.length;
    if (total == 0) return 0;
    int done = 0;
    if (_phase > 0) done += widget.bluePath.length;
    if (_phase > 1) done += widget.redPath.length;
    done += _stepInPhase;
    return (done / total).clamp(0.0, 1.0);
  }

  // Preview paths for completion slider
  // ── FIXED: Preview all 3 phases based on combined progress ──

// How many total steps to show at current _previewProgress
  int get _previewTotalSteps =>
      (_previewProgress * _totalSteps).round()
          .clamp(0, _totalSteps);

// Blue preview — shows first N blue steps
  List<int> get _previewBlue {
    if (widget.bluePath.isEmpty) return [];
    final show = _previewTotalSteps
        .clamp(0, widget.bluePath.length);
    if (show <= 0) return [];
    return widget.bluePath.sublist(0, show);
  }

// Red preview — shows after blue is complete
  List<int> get _previewRed {
    if (widget.redPath.isEmpty) return [];
    final afterBlue =
        _previewTotalSteps - widget.bluePath.length;
    if (afterBlue <= 0) return [];
    final show =
    afterBlue.clamp(0, widget.redPath.length);
    return widget.redPath.sublist(0, show);
  }

// Green preview — shows after blue + red are complete
  List<int> get _previewGreen {
    if (widget.greenPath.isEmpty) return [];
    final afterBlueRed = _previewTotalSteps -
        widget.bluePath.length -
        widget.redPath.length;
    if (afterBlueRed <= 0) return [];
    final show =
    afterBlueRed.clamp(0, widget.greenPath.length);
    return widget.greenPath.sublist(0, show);
  }

  @override
  void initState() {
    super.initState();
    _phase = widget.startPhase;
    _stepInPhase = widget.startStep;
// Start preview at real current progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _previewProgress = _actualOverallProgress);
      }
    });
    _phaseGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _switchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();
      final voice = context.read<VoiceService>();
      setState(() {
        _autoAdvance = settings.autoAdvance;
        _autoDelay = settings.autoDelay;
        _voiceOn = voice.isEnabled;
        _voiceSpeed = voice.speed;
        _voiceGender = voice.voice;
      });
      if (_autoAdvance && !_isPaused) {
        _startTimer();
      }
    });
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec =
    await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _bgImage = frame.image);
  }

  @override
  void dispose() {
    _cancelTimer();
    _phaseGlow.dispose();
    _switchAnim.dispose();
    super.dispose();
  }

  // ════════════════
  // NAVIGATION
  // ════════════════

  void _nextStep() {
    if (_allDone) return;
    HapticFeedback.lightImpact();

    if (_isPhaseFinished && _phase < 2) {
      _advancePhase();
      return;
    }

    setState(() => _stepInPhase++);
    _speakStep();
  }

  void _prevStep() {
    if (_stepInPhase > 0) {
      HapticFeedback.lightImpact();
      setState(() => _stepInPhase--);
    } else if (_phase > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _phase--;
        _stepInPhase = _currentPath.length - 1;
      });
    }
  }

  void _advancePhase() {
    setState(() {
      _phase++;
      _stepInPhase = 0;
      _showSwitchAlert = true;
    });

    // Flash switch alert
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSwitchAlert = false);
    });

    _speakPhaseChange();
    _switchAnim.forward(from: 0);
  }

  // ════════════════
  // VOICE
  // ════════════════

  void _speakStep() {
    if (!_voiceOn) return;
    context.read<VoiceService>().speak(
        '$_activeName thread. '
            'Nail ${_currentNail + 1} to ${_nextNail + 1}');
  }

  void _speakPhaseChange() {
    if (!_voiceOn) return;
    context.read<VoiceService>().speak(
        'Phase complete. Switch to $_activeName thread now.');
  }

  // ════════════════
  // AUTO ADVANCE
  // ════════════════

  void _startTimer() {
    _cancelTimer();
    if (!_autoAdvance || _isPaused) return;
    _autoTimer = Timer(
      Duration(seconds: _autoDelay),
          () {
        if (mounted && _autoAdvance && !_isPaused) {
          _nextStep();
          _startTimer();
        }
      },
    );
  }

  void _cancelTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  // ════════════════
  // BUILD
  // ════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildPhaseTimeline(),
                Expanded(child: _buildCanvas()),
                _buildBottomPanel(),
              ],
            ),
          ),

          // Thread switch alert
          if (_showSwitchAlert)
            _buildSwitchAlert(),
        ],
      ),
    );
  }

  // ── APP BAR ──
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          12, 8, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {

              // Save RGB progress before leaving
              if (widget.projectId != null && mounted) {
                await context
                    .read<ProjectService>()
                    .updateRGBProgress(
                  widget.projectId!,
                  _phase,
                  _stepInPhase,
                );
              }

              // Return phase + step to preview screen
              if (mounted) {
                Navigator.pop(context, {
                  'phase': _phase,
                  'step': _stepInPhase,
                });
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                  BorderRadius.circular(10)),
              child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _phaseGlow,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _activeColor,
                boxShadow: [
                  BoxShadow(
                    color: _activeColor.withOpacity(
                        0.4 +
                            _phaseGlow.value * 0.4),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'RGB Thread Art',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          // Settings button
          GestureDetector(
            onTap: _showSettingsSheet,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                  BorderRadius.circular(10)),
              child: const Icon(Icons.tune,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── PHASE TIMELINE ──
  Widget _buildPhaseTimeline() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          12, 10, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _activeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _phase;
          final isDone = i < _phase;
          final c = _phaseColors[i];

          return Expanded(
            child: GestureDetector(
              onTap: isDone
                  ? () {
                setState(() {
                  _phase = i;
                  _stepInPhase =
                      _currentPath.length - 1;
                });
              }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(
                    milliseconds: 250),
                margin: EdgeInsets.only(
                    right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(
                    vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? c.withOpacity(0.2)
                      : isDone
                      ? c.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius:
                  BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? c
                        : isDone
                        ? c.withOpacity(0.3)
                        : Colors.white
                        .withOpacity(0.06),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(_phaseEmojis[i],
                        style: TextStyle(
                            fontSize:
                            isActive ? 18 : 15)),
                    const SizedBox(height: 2),
                    Text(
                      _phaseNames[i],
                      style: GoogleFonts.poppins(
                        color: isActive
                            ? c
                            : isDone
                            ? c.withOpacity(0.7)
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isDone)
                      Text('✓',
                          style: TextStyle(
                              color: c, fontSize: 9)),
                    if (isActive)
                      Text(
                        '${(_phaseProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: c,
                            fontSize: 8,
                            fontWeight:
                            FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── CANVAS ──
  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _activeColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _activeColor.withOpacity(0.1),
            blurRadius: 12,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          size: Size.infinite,
          painter: RGBRingPainter(
            nailCount: widget.nailCount,
            shape: widget.shape,
            backgroundImage:
            _showBackground ? _bgImage : null,
            completedRed: _previewRed,
            completedGreen: _previewGreen,
            completedBlue: _previewBlue,
            currentNail: _currentNail,
            nextNail: _nextNail,
            activeColor: _activeName,
          ),
        ),
      ),
    );
  }

  // ── BOTTOM PANEL ──
  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: _activeColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thread badge
          _buildThreadBadge(),

          const SizedBox(height: 10),

          // Step display
          _buildStepDisplay(),

          const SizedBox(height: 10),

          // Progress bars
          _buildProgressBars(),

          const SizedBox(height: 10),

          // Completion preview slider
          _buildPreviewSlider(),

          const SizedBox(height: 12),

          // Controls
          _buildControls(),

          const SizedBox(height: 10),

          // Quick controls row
          _buildQuickControls(),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: 400.ms);
  }

  Widget _buildThreadBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _activeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _activeColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: _activeColor.withOpacity(0.2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _phaseGlow,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _activeColor,
                boxShadow: [
                  BoxShadow(
                    color: _activeColor.withOpacity(
                        0.5 +
                            _phaseGlow.value * 0.3),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Using $_activeEmoji $_activeName Thread',
            style: GoogleFonts.poppins(
              color: _activeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDisplay() {
    if (_allDone) {
      return ShaderMask(
        shaderCallback: (b) =>
            AppColors.primaryGradient.createShader(b),
        child: Text(
          '🎉 RGB Art Complete!',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_currentNail + 1}',
          style: GoogleFonts.poppins(
            color: _activeColor,
            fontSize: 38,
            fontWeight: FontWeight.bold,
          ),
        )
            .animate(key: ValueKey('${_phase}_$_stepInPhase'))
            .fadeIn(duration: 200.ms)
            .slideX(begin: -0.2),
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward,
              color: AppColors.textMuted, size: 22),
        ),
        Text(
          '${_nextNail + 1}',
          style: GoogleFonts.poppins(
            color: _activeColor.withOpacity(0.7),
            fontSize: 38,
            fontWeight: FontWeight.bold,
          ),
        )
            .animate(
            key: ValueKey(
                'n${_phase}_$_stepInPhase'))
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.2),
      ],
    );
  }

  Widget _buildProgressBars() {
    return Column(
      children: [
        // Phase progress
        Row(
          children: [
            Text(
              '$_activeName phase',
              style: GoogleFonts.poppins(
                  color: _activeColor, fontSize: 10),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _phaseProgress,
                  backgroundColor:
                  Colors.white.withOpacity(0.08),
                  valueColor:
                  AlwaysStoppedAnimation(_activeColor),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(_phaseProgress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                  color: _activeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Overall progress
        Row(
          children: [
            Text(
              'Overall',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 10),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _overallProgress,
                  backgroundColor:
                  Colors.white.withOpacity(0.08),
                  valueColor:
                  const AlwaysStoppedAnimation(
                      AppColors.purple),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(_overallProgress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                  color: AppColors.purple,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewSlider() {
    final actual = _actualOverallProgress;
    final isCustom =
        (_previewProgress - actual).abs() > 0.01;

    // Phase boundary positions (for markers)
    final total = _totalSteps;
    final blueEnd = total == 0
        ? 0.33
        : widget.bluePath.length / total;
    final redEnd = total == 0
        ? 0.66
        : (widget.bluePath.length +
        widget.redPath.length) /
        total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── HEADER ROW ──
        Row(
          children: [
            Text(
              'Preview at ${(_previewProgress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: isCustom
                    ? AppColors.orange
                    : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const Spacer(),

            // Return to real step button
            if (isCustom)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _previewProgress = actual;
                    _isPreviewingCustom = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange
                        .withOpacity(0.12),
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.orange
                            .withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.undo_rounded,
                          color: AppColors.orange,
                          size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'Return ${(actual * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: AppColors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // ── THE SLIDER ──
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8),
            activeTrackColor:
            isCustom ? AppColors.orange : _activeColor,
            thumbColor:
            isCustom ? AppColors.orange : _activeColor,
            inactiveTrackColor:
            Colors.white.withOpacity(0.1),
            overlayColor: (isCustom
                ? AppColors.orange
                : _activeColor)
                .withOpacity(0.2),
          ),
          child: Slider(
            value: _previewProgress,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              setState(() {
                _previewProgress = val;
                _isPreviewingCustom =
                    (val - actual).abs() > 0.01;
              });
            },
          ),
        ),

        // ── PHASE BOUNDARY MARKERS ──
        Stack(
          children: [
            // Base row: 0% and 100%
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text('0%',
                    style: GoogleFonts.poppins(
                        color: AppColors.textMuted,
                        fontSize: 9)),
                Text('100%',
                    style: GoogleFonts.poppins(
                        color: AppColors.textMuted,
                        fontSize: 9)),
              ],
            ),

            // Blue end marker
            Positioned(
              left: blueEnd *
                  (MediaQuery.of(context).size.width -
                      72),
              child: Column(
                children: [
                  Container(
                    width: 1.5,
                    height: 8,
                    color: Colors.blue.withOpacity(0.7),
                  ),
                  Text('B',
                      style: TextStyle(
                          color: Colors.blue
                              .withOpacity(0.7),
                          fontSize: 7)),
                ],
              ),
            ),

            // Red end marker
            Positioned(
              left: redEnd *
                  (MediaQuery.of(context).size.width -
                      72),
              child: Column(
                children: [
                  Container(
                    width: 1.5,
                    height: 8,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  Text('R',
                      style: TextStyle(
                          color:
                          Colors.red.withOpacity(0.7),
                          fontSize: 7)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── PHASE LABELS ROW ──
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,
          children: [
            _phasePill('🔵', 'Blue',
                Colors.blue,
                _previewTotalSteps >=
                    widget.bluePath.length),
            _phasePill('🔴', 'Red',
                Colors.red,
                _previewTotalSteps >=
                    widget.bluePath.length +
                        widget.redPath.length),
            _phasePill('🟢', 'Green',
                Colors.green,
                _previewTotalSteps >= _totalSteps),
          ],
        ),

        // ── WARNING when previewing different ──
        if (isCustom)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.orange
                        .withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.orange, size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Preview only — real progress at '
                          '${(actual * 100).toStringAsFixed(0)}%. '
                          'Voice reads from real step.',
                      style: GoogleFonts.poppins(
                        color: AppColors.orange
                            .withOpacity(0.85),
                        fontSize: 9,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

// Helper — phase completion pill
  Widget _phasePill(
      String emoji, String label, Color color, bool done) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: done ? color : AppColors.textMuted,
            fontSize: 9,
            fontWeight:
            done ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 3),
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? color : AppColors.textMuted,
          size: 10,
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ctrlBtn(Icons.arrow_back, 'Back',
            _stepInPhase > 0 || _phase > 0, _prevStep),
        const SizedBox(width: 16),

        // Pause/Play
        GestureDetector(
          onTap: () {
            setState(() => _isPaused = !_isPaused);
            if (_isPaused) {
              _cancelTimer();
              context.read<VoiceService>().stop();
            } else if (_autoAdvance) {
              _startTimer();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _activeColor,
              boxShadow: [
                BoxShadow(
                  color: _activeColor.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(
              _isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),

        const SizedBox(width: 16),
        _ctrlBtn(Icons.arrow_forward, 'Next',
            !_allDone, _nextStep),
      ],
    );
  }

  Widget _buildQuickControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Voice toggle
        _quickBtn(
          icon: _voiceOn
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          label: 'Voice',
          isActive: _voiceOn,
          activeColor: _activeColor,
          onTap: () {
            setState(() => _voiceOn = !_voiceOn);
            context
                .read<VoiceService>()
                .setEnabled(_voiceOn);
          },
        ),

        // Repeat
        _quickBtn(
          icon: Icons.repeat_rounded,
          label: 'Repeat',
          isActive: false,
          activeColor: _activeColor,
          onTap: () {
            final v = context.read<VoiceService>();
            final was = v.isEnabled;
            if (!was) v.setEnabled(true);
            v.speak(
                '$_activeName. Nail ${_currentNail + 1} to ${_nextNail + 1}');
            if (!was) {
              Future.delayed(
                const Duration(seconds: 3),
                    () => v.setEnabled(false),
              );
            }
          },
        ),

        // Auto advance
        _quickBtn(
          icon: _autoAdvance
              ? Icons.fast_forward_rounded
              : Icons.play_circle_outline,
          label: 'Auto',
          isActive: _autoAdvance,
          activeColor: _activeColor,
          onTap: () {
            setState(() => _autoAdvance = !_autoAdvance);
            if (_autoAdvance) {
              if (!_voiceOn) {
                setState(() => _voiceOn = true);
                context.read<VoiceService>().setEnabled(true);
              }
              _startTimer();
            } else {
              _cancelTimer();
            }
          },
        ),

        // Background
        _quickBtn(
          icon: _showBackground
              ? Icons.image_rounded
              : Icons.image_not_supported_outlined,
          label: 'Photo',
          isActive: _showBackground,
          activeColor: _activeColor,
          onTap: () =>
              setState(() => _showBackground = !_showBackground),
        ),
      ],
    );
  }

  Widget _ctrlBtn(
      IconData icon,
      String label,
      bool enabled,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
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
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 9)),
        ],
      ),
    );
  }

  Widget _quickBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.2)
                  : AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? activeColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.07),
              ),
              boxShadow: isActive
                  ? [
                BoxShadow(
                    color:
                    activeColor.withOpacity(0.3),
                    blurRadius: 8)
              ]
                  : [],
            ),
            child: Icon(icon,
                color: isActive
                    ? activeColor
                    : AppColors.textSecondary,
                size: 17),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 9)),
        ],
      ),
    );
  }

  // ── Thread switch alert ──
  Widget _buildSwitchAlert() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: AnimationConfiguration.staggeredList(
        position: 0,
        child: SlideAnimation(
          verticalOffset: -40,
          child: FadeInAnimation(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _activeColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _activeColor.withOpacity(0.5),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Row(
                children: [
                  Text(_activeEmoji,
                      style: const TextStyle(
                          fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Switch Thread!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Now using $_activeName thread',
                          style: GoogleFonts.poppins(
                            color: Colors.white
                                .withOpacity(0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(
                            () => _showSwitchAlert = false),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Settings sheet ──
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('RGB Settings',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                // Project info
                _settingCard(children: [
                  _infoRow('Total Nails',
                      '${widget.nailCount}'),
                  _infoRow('Shape', widget.shape),
                  _infoRow('Blue Steps',
                      '${widget.bluePath.length}'),
                  _infoRow('Red Steps',
                      '${widget.redPath.length}'),
                  _infoRow('Green Steps',
                      '${widget.greenPath.length}'),
                  _infoRow('Overall',
                      '${(_overallProgress * 100).toStringAsFixed(1)}%'),
                ]),

                const SizedBox(height: 16),

                // Voice settings
                _settingCard(children: [
                  _toggleRow('Voice Guide', _voiceOn,
                      _activeColor, (val) {
                        setSheetState(
                                () => _voiceOn = val);
                        setState(() => _voiceOn = val);
                        context
                            .read<VoiceService>()
                            .setEnabled(val);
                      }),

                  if (_voiceOn) ...[
                    const Divider(
                        color: Color(0x10FFFFFF)),
                    // Speed chips
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Row(
                        children: [
                          Text('Speed',
                              style: GoogleFonts.poppins(
                                  color: AppColors
                                      .textSecondary,
                                  fontSize: 13)),
                          const Spacer(),
                          ...([0.5, 1.0, 1.5, 2.0]
                              .map((s) {
                            final sel =
                                _voiceSpeed == s;
                            return GestureDetector(
                              onTap: () async {
                                setSheetState(() =>
                                _voiceSpeed = s);
                                setState(() =>
                                _voiceSpeed = s);
                                await context
                                    .read<VoiceService>()
                                    .setSpeed(s);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                margin: const EdgeInsets
                                    .only(left: 6),
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _activeColor
                                      : AppColors.surface,
                                  borderRadius:
                                  BorderRadius.circular(
                                      8),
                                ),
                                child: Text('${s}x',
                                    style:
                                    GoogleFonts.poppins(
                                        color:
                                        Colors.white,
                                        fontSize: 11)),
                              ),
                            );
                          })),
                        ],
                      ),
                    ),
                    const Divider(
                        color: Color(0x10FFFFFF)),
                    // Gender
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Row(
                        children: [
                          Text('Voice',
                              style: GoogleFonts.poppins(
                                  color: AppColors
                                      .textSecondary,
                                  fontSize: 13)),
                          const Spacer(),
                          ...(['Female', 'Male']
                              .map((g) {
                            final sel =
                                _voiceGender == g;
                            return GestureDetector(
                              onTap: () async {
                                setSheetState(() =>
                                _voiceGender = g);
                                setState(() =>
                                _voiceGender = g);
                                await context
                                    .read<VoiceService>()
                                    .setVoice(g);
                                await context
                                    .read<VoiceService>()
                                    .testSpeak();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                margin: const EdgeInsets
                                    .only(left: 8),
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _activeColor
                                      : AppColors.surface,
                                  borderRadius:
                                  BorderRadius.circular(
                                      10),
                                ),
                                child: Text(g,
                                    style:
                                    GoogleFonts.poppins(
                                        color:
                                        Colors.white,
                                        fontSize: 12)),
                              ),
                            );
                          })),
                        ],
                      ),
                    ),
                  ],
                ]),

                const SizedBox(height: 16),

                // Auto advance
                _settingCard(children: [
                  _toggleRow(
                      'Auto Advance',
                      _autoAdvance,
                      _activeColor, (val) {
                    setSheetState(
                            () => _autoAdvance = val);
                    setState(() => _autoAdvance = val);
                    if (val) {
                      _startTimer();
                    } else {
                      _cancelTimer();
                    }
                  }),

                  if (_autoAdvance) ...[
                    const Divider(
                        color: Color(0x10FFFFFF)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Column(children: [
                        Row(children: [
                          Text('Delay',
                              style: GoogleFonts.poppins(
                                  color: AppColors
                                      .textSecondary,
                                  fontSize: 13)),
                          const Spacer(),
                          Text('${_autoDelay}s',
                              style: GoogleFonts.poppins(
                                  color: _activeColor,
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold)),
                        ]),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape:
                            const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                            activeTrackColor: _activeColor,
                            thumbColor: _activeColor,
                            inactiveTrackColor:
                            Colors.white.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: _autoDelay.toDouble(),
                            min: 4,
                            max: 20,
                            divisions: 16,
                            onChangeEnd: (v) {
                              final d = v.round();
                              setState(
                                      () => _autoDelay = d);
                              _startTimer();
                            },
                            onChanged: (v) {
                              setSheetState(() =>
                              _autoDelay = v.round());
                            },
                          ),
                        ),
                      ]),
                    ),
                  ],
                ]),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _settingCard(
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _toggleRow(String label, bool value,
      Color activeColor, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 14)),
          const Spacer(),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: value
                    ? activeColor
                    : AppColors.textMuted
                    .withOpacity(0.3),
                boxShadow: value
                    ? [
                  BoxShadow(
                      color:
                      activeColor.withOpacity(
                          0.4),
                      blurRadius: 8)
                ]
                    : [],
              ),
              child: AnimatedAlign(
                duration:
                const Duration(milliseconds: 200),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 13)),
          const Spacer(),
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

// ── Required import for animation ──
class AnimationConfiguration {
  static Widget staggeredList(
      {required int position,
        required Widget child}) =>
      child;
}

class SlideAnimation extends StatelessWidget {
  final double verticalOffset;
  final Widget child;
  const SlideAnimation(
      {required this.verticalOffset,
        required this.child,
        super.key});

  @override
  Widget build(BuildContext context) => child
      .animate()
      .slideY(
      begin: verticalOffset / 100,
      duration: 400.ms)
      .fadeIn();
}

class FadeInAnimation extends StatelessWidget {
  final Widget child;
  const FadeInAnimation(
      {required this.child, super.key});

  @override
  Widget build(BuildContext context) => child;
}