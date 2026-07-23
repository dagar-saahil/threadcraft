import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_colors.dart';
import '../features/thread_art/canvas/nail_ring_painter.dart';
import '../services/pdf_export_service.dart';
import '../services/project_service.dart';
import '../widgets/gradient_button.dart';
import 'work_mode_screen.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import 'package:flutter/foundation.dart';
import '../services/nail_template_pdf_service.dart';
import 'dart:math';
class PreviewScreen extends StatefulWidget {
  final File imageFile;
  final List<int> nailPath;
  final int nailCount;
  final String shape;
  final String density;
  final Color threadColor;
  final String? projectId;
  final int startStep;

  const PreviewScreen({
    super.key,
    required this.imageFile,
    required this.nailPath,
    required this.nailCount,
    required this.shape,
    required this.density,
    this.projectId,
    this.startStep = 0,
    this.threadColor = Colors.white,
  });

  @override
  State<PreviewScreen> createState() =>
      _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  // Which tab is active
  bool _showNailMap = false;

  // Completion preview: 0.25 / 0.50 / 0.75 / 1.0
  double _previewProgress = 1.0;
  bool _isPreviewingCustom = false; // ← NEW — true when user moved slider
  // Canvas options
  bool _showBackground = true;
  bool _useColorThread = true;

  // Resume step tracking
  late int _currentStartStep;
  late Color _activeThreadColor;

  // For zoom/pan
  final TransformationController _transformController =
  TransformationController();

  // For screenshot export
  final GlobalKey _canvasKey = GlobalKey();

  // Loaded image for canvas
  ui.Image? _uiImage;

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _currentStartStep = widget.startStep;
    _activeThreadColor = widget.threadColor;
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec =
    await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _uiImage = frame.image);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ── 1. PREVIEW / NAIL MAP TOGGLE ──
          _buildViewToggle(),

          const SizedBox(height: 10),

          // ── 2. COMPLETION PREVIEW BUTTONS ──
          // Only shows on Preview tab, not Nail Map
          if (!_showNailMap)
            _buildCompletionSelector(),

          if (!_showNailMap)
            const SizedBox(height: 10),

          // ── 3. CANVAS (takes remaining space) ──
          Expanded(
            child: _buildCanvas(),
          ),

          // ── 4. BOTTOM ACTIONS ──
          _buildBottomSection(),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  // APP BAR
  // ════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        'Preview',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _shareImage,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.ios_share,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════
  // VIEW TOGGLE (Preview / Nail Map)
  // ════════════════════════════════════

  Widget _buildViewToggle() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            _toggleOption('Preview', !_showNailMap),
            _toggleOption('Nail Map', _showNailMap),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _toggleOption(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(
                () => _showNailMap = label == 'Nail Map'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding:
          const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppColors.primaryGradient
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: AppColors.purpleGlow,
                  blurRadius: 12)
            ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════
  // COMPLETION PREVIEW SELECTOR
  // Very visible — 4 big buttons
  // ════════════════════════════════════

  Widget _buildCompletionSelector() {
    final actualProgress = widget.nailPath.isEmpty
        ? 0.0
        : (_currentStartStep /
        (widget.nailPath.length - 1)
            .clamp(1, 999999))
        .clamp(0.0, 1.0);

    final isPreviewingDifferent =
        (_previewProgress - actualProgress).abs() > 0.01;

    final options = [
      {'label': '25%', 'value': 0.25,
        'color': AppColors.cyan},
      {'label': '50%', 'value': 0.50,
        'color': AppColors.blue},
      {'label': '75%', 'value': 0.75,
        'color': AppColors.purple},
      {'label': '100%', 'value': 1.0,
        'color': AppColors.pink},
    ];

    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── HEADER with Return button ──
          Row(
            children: [
              const Icon(Icons.preview_rounded,
                  color: AppColors.textMuted, size: 13),
              const SizedBox(width: 6),
              Text(
                'Completion Preview',
                style: GoogleFonts.poppins(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),

              // Return to real step button
              if (isPreviewingDifferent)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _previewProgress = actualProgress;
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
                          'Return ${(actualProgress * 100).toStringAsFixed(0)}%',
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

          const SizedBox(height: 8),

          // ── 4 QUICK BUTTONS ──
          Row(
            children: options.map((opt) {
              final val = opt['value'] as double;
              final color = opt['color'] as Color;
              final isSelected =
                  (_previewProgress - val).abs() < 0.01;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                          () => _previewProgress = val),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 200),
                    margin:
                    const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : AppColors.card,
                      borderRadius:
                      BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Colors.white
                            .withOpacity(0.07),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                            color: color
                                .withOpacity(0.3),
                            blurRadius: 10)
                      ]
                          : [],
                    ),
                    child: Text(
                      opt['label'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? color
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // ── SMOOTH SLIDER ──
          Container(
            padding: const EdgeInsets.fromLTRB(
                14, 12, 14, 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPreviewingDifferent
                    ? AppColors.orange.withOpacity(0.3)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [

                // Label row
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: isPreviewingDifferent
                          ? AppColors.orange
                          : AppColors.textMuted,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Smooth Preview',
                      style: GoogleFonts.poppins(
                        color: isPreviewingDifferent
                            ? AppColors.orange
                            : AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    // Current %
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3),
                      decoration: BoxDecoration(
                        color: (isPreviewingDifferent
                            ? AppColors.orange
                            : AppColors.purple)
                            .withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(_previewProgress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: isPreviewingDifferent
                              ? AppColors.orange
                              : AppColors.purple,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                    const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                    activeTrackColor:
                    isPreviewingDifferent
                        ? AppColors.orange
                        : AppColors.purple,
                    thumbColor: isPreviewingDifferent
                        ? AppColors.orange
                        : AppColors.pink,
                    inactiveTrackColor:
                    Colors.white.withOpacity(0.1),
                    overlayColor:
                    (isPreviewingDifferent
                        ? AppColors.orange
                        : AppColors.purple)
                        .withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _previewProgress,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() =>
                      _previewProgress = val);
                    },
                  ),
                ),

                // Bottom labels
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 9)),

                    // Your real progress marker
                    if (actualProgress > 0.03 &&
                        actualProgress < 0.97)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 2,
                            height: 8,
                            color: AppColors.cyan
                                .withOpacity(0.8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Your progress: ${(actualProgress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                                color: AppColors.cyan,
                                fontSize: 8),
                          ),
                        ],
                      ),

                    Text('100%',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),

          // ── PREVIEW WARNING (shows when different) ──
          if (isPreviewingDifferent)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange
                      .withOpacity(0.08),
                  borderRadius:
                  BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.orange
                          .withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.orange,
                        size: 13),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Preview only — real progress saved at '
                            '${(actualProgress * 100).toStringAsFixed(0)}%. '
                            '"Start Creating" resumes from there.',
                        style: GoogleFonts.poppins(
                          color: AppColors.orange
                              .withOpacity(0.85),
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
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
  // CANVAS
  // ════════════════════════════════════

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: RepaintBoundary(
          key: _canvasKey,
          child: InteractiveViewer(
            transformationController:
            _transformController,
            minScale: 0.5,
            maxScale: 5.0,
            child: _showNailMap
                ? _buildNailMapView()
                : _buildPreviewView(),
          ),
        ),
      ),
    );
  }

  // Preview view — shows thread art at selected %
  Widget _buildPreviewView() {
    // How many steps to show
    final endIndex = widget.nailPath.isEmpty
        ? 0
        : (widget.nailPath.length * _previewProgress)
        .round()
        .clamp(1, widget.nailPath.length);

    final visiblePath = widget.nailPath.isEmpty
        ? <int>[]
        : widget.nailPath.sublist(0, endIndex);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: NailRingPainter(
          nailCount: widget.nailCount,
          completedPath: visiblePath,
          currentNail: visiblePath.isEmpty
              ? 0
              : visiblePath.last,
          nextNail: widget.nailPath.isEmpty
              ? 0
              : widget.nailPath.last,
          backgroundImage: _uiImage,
          shape: widget.shape,
          showBackground: _showBackground,
          useColorThread: _useColorThread,
          singleThreadColor: _activeThreadColor,
        ),
      ),
    );
  }

  // Nail map view — just dots and connections
  Widget _buildNailMapView() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: _NailMapPainter(
          nailCount: widget.nailCount,
          nailPath: widget.nailPath,
          shape: widget.shape,
        ),
      ),
    );
  }

  // ════════════════════════════════════
  // BOTTOM SECTION
  // ════════════════════════════════════

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          16, 14, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── START / CONTINUE BUTTON ──
          _buildStartButton(),

          const SizedBox(height: 10),

          // ── CANVAS OPTIONS ROW ──
          _buildCanvasToggles(),

          const SizedBox(height: 10),

          // ── EXPORT BUTTONS ROW ──
          _buildExportButtons(),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 400.ms);
  }

  // Start / Continue button
  Widget _buildStartButton() {
    final hasProgress = _currentStartStep > 0;
    final progressPct = widget.nailPath.isEmpty
        ? 0.0
        : _currentStartStep /
        (widget.nailPath.length - 1) *
        100;

    return GestureDetector(
      onTap: _goToWorkMode,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.purpleGlow,
                blurRadius: 16)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    hasProgress
                        ? 'Continue'
                        : 'Start Creating',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    hasProgress
                        ? 'Resume from ${progressPct.toStringAsFixed(0)}% progress'
                        : 'Step by step guide',
                    style: GoogleFonts.poppins(
                      color: Colors.white
                          .withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasProgress
                    ? Icons.play_arrow_rounded
                    : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Canvas option toggles
  Widget _buildCanvasToggles() {
    return Row(
      children: [
        // Background toggle
        Expanded(
          child: GestureDetector(
            onTap: () => setState(
                    () => _showBackground =
                !_showBackground),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  vertical: 9),
              decoration: BoxDecoration(
                color: _showBackground
                    ? AppColors.cyan.withOpacity(0.15)
                    : AppColors.card,
                borderRadius:
                BorderRadius.circular(10),
                border: Border.all(
                  color: _showBackground
                      ? AppColors.cyan
                      .withOpacity(0.4)
                      : Colors.white.withOpacity(0.07),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _showBackground
                        ? Icons.image_rounded
                        : Icons
                        .image_not_supported_outlined,
                    color: _showBackground
                        ? AppColors.cyan
                        : AppColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _showBackground
                        ? 'Photo ON'
                        : 'Photo OFF',
                    style: GoogleFonts.poppins(
                      color: _showBackground
                          ? AppColors.cyan
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Thread color toggle
        Expanded(
          child: GestureDetector(
            onTap: () => setState(
                    () => _useColorThread =
                !_useColorThread),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  vertical: 9),
              decoration: BoxDecoration(
                color: _useColorThread
                    ? AppColors.pink.withOpacity(0.15)
                    : AppColors.card,
                borderRadius:
                BorderRadius.circular(10),
                border: Border.all(
                  color: _useColorThread
                      ? AppColors.pink
                      .withOpacity(0.4)
                      : Colors.white.withOpacity(0.07),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _useColorThread
                        ? Icons.palette_rounded
                        : Icons.circle,
                    color: _useColorThread
                        ? AppColors.pink
                        : AppColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _useColorThread
                        ? 'Color Thread'
                        : 'Black Thread',
                    style: GoogleFonts.poppins(
                      color: _useColorThread
                          ? AppColors.pink
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Export buttons row
  Widget _buildExportButtons() {
    return Row(
      children: [
        _exportBtn(
          icon: Icons.save_outlined,
          label: 'Save',
          color: AppColors.purple,
          onTap: _saveProject,
        ),
        const SizedBox(width: 8),
        _exportBtn(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Export PDF',
          color: AppColors.orange,
          onTap: _exportPdf,
        ),
        const SizedBox(width: 8),
        _exportBtn(
          icon: Icons.grain,
          label: 'Nail Map',
          color: AppColors.cyan,
          onTap: () =>
              setState(() => _showNailMap = true),
        ),
      ],
    );
  }

  Widget _exportBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════

  Future<void> _goToWorkMode() async {
    final returnedStep = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkModeScreen(
          imageFile: widget.imageFile,
          nailPath: widget.nailPath,
          nailCount: widget.nailCount,
          shape: widget.shape,
          projectId: widget.projectId,
          startStep: _currentStartStep,
          showBackground: _showBackground,
          useColorThread: _useColorThread,
          threadColor: _activeThreadColor,
        ),
      ),
    );

    if (returnedStep != null && mounted) {
      setState(() => _currentStartStep = returnedStep);
    }
  }

  Future<void> _shareImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final boundary = _canvasKey.currentContext
          ?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image =
      await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
          format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/threadcraft_preview.png');
      await file
          .writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My ThreadCRAFT artwork! 🧵',
      );
    } catch (e) {
      _showSnack('Export failed!', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveProject() async {
    try {
      _showSnack('Saving...');

      final projectService =
      context.read<ProjectService>();

      // If project already exists → update it
      if (widget.projectId != null) {
        await projectService.updateProgress(
          widget.projectId!,
          _currentStartStep,
        );
        _showSnack('Project updated! ✅');
        return;
      }

      // New project → create and save
      final newId =
      DateTime.now().millisecondsSinceEpoch
          .toString();

      final project = ProjectModel(
        id: newId,
        name:
        'ThreadCRAFT ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        imagePath: widget.imageFile.path,
        nailCount: widget.nailCount,
        shape: widget.shape,
        density: widget.density,
        nailPath: widget.nailPath,
        currentStep: _currentStartStep,
        createdAt: DateTime.now(),
      );

      await projectService.saveProject(project);
      _showSnack('Saved to My Projects! ✅');
    } catch (e) {
      debugPrint('Save error: $e');
      _showSnack('Save failed. Try again!',
          isError: true);
    }
  }
  Future<void> _exportPdf() async {
    // Show options sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
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
            const SizedBox(height: 16),
            Text('Export PDF',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 16),

            // Option 1: Nail Template
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _exportNailTemplate();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 12)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grid_on_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Nail Template PDF',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              )),
                          Text(
                            'Real-scale printable template '
                                'for hammering nails on board',
                            style: GoogleFonts.poppins(
                              color: Colors.white
                                  .withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Option 2: Step list
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _exportStepList();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.orange
                          .withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_rounded,
                        color: AppColors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Step List PDF',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              )),
                          Text(
                            'Printable thread winding '
                                'step-by-step sequence',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: AppColors.textMuted,
                        size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

// ── Export nail template ──
  Future<void> _exportNailTemplate() async {
    setState(() => _isExporting = true);
    _showSnack('Generating nail template PDF...');

    try {
      await NailTemplatePdfService.generate(
        context: context,
        nailCount: widget.nailCount,
        shape: widget.shape,
        boardSizeCm: 50, // default — user can change
        threadSize: '0.19 mm',
        density: widget.density,
        nailPath: widget.nailPath,
      );
    } catch (e) {
      _showSnack('PDF failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

// ── Export step list ──
  Future<void> _exportStepList() async {
    setState(() => _isExporting = true);
    _showSnack('Generating step list PDF...');

    try {
      await PdfExportService.exportNailMap(
        context: context,
        nailCount: widget.nailCount,
        shape: widget.shape,
        nailPath: widget.nailPath,
        density: widget.density,
      );
    } catch (e) {
      _showSnack('PDF failed!', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnack(String msg,
      {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? Colors.red.shade800
            : AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: isError
                  ? Colors.red.shade200
                  : AppColors.purple,
            ),
            const SizedBox(width: 10),
            Text(msg,
                style: GoogleFonts.poppins(
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════
// NAIL MAP PAINTER
// Fixed for all shapes!
// ════════════════════════════════════

class _NailMapPainter extends CustomPainter {
  final int nailCount;
  final List<int> nailPath;
  final String shape;

  _NailMapPainter({
    required this.nailCount,
    required this.nailPath,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );

    final center =
    Offset(size.width / 2, size.height / 2);
    const padding = 28.0;

    // Get nail positions based on shape
    final nails = _getNails(size, padding);

    // Draw shape outline
    _drawOutline(canvas, size, padding);

    // Draw thread lines
    final colors = [
      AppColors.purple,
      AppColors.pink,
      AppColors.orange,
      AppColors.cyan,
    ];
    for (int i = 0; i < nailPath.length - 1; i++) {
      final from = nailPath[i];
      final to = nailPath[i + 1];
      if (from >= nails.length ||
          to >= nails.length) continue;
      canvas.drawLine(
        nails[from],
        nails[to],
        Paint()
          ..color =
          colors[i % colors.length].withOpacity(0.2)
          ..strokeWidth = 0.5,
      );
    }

    // Draw nail dots + numbers
    for (int i = 0; i < nails.length; i++) {
      final pos = nails[i];

      // Dot
      canvas.drawCircle(
        pos,
        3,
        Paint()
          ..color = Colors.white.withOpacity(0.7),
      );

      // Number — every 10th nail
      if (i % 10 == 0) {
        // Direction outward
        final dx = pos.dx - center.dx;
        final dy = pos.dy - center.dy;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist == 0) continue;

        final lx = pos.dx + (dx / dist) * 14;
        final ly = pos.dy + (dy / dist) * 14;

        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}', // starts from 1!
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(
            (lx - tp.width / 2)
                .clamp(1.0, size.width - tp.width - 1),
            (ly - tp.height / 2).clamp(
                1.0, size.height - tp.height - 1),
          ),
        );
      }
    }
  }

  void _drawOutline(
      Canvas canvas, Size size, double padding) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    switch (shape) {
      case 'Square':
        canvas.drawRect(
          Rect.fromLTWH(
              padding,
              padding,
              size.width - padding * 2,
              size.height - padding * 2),
          paint,
        );
        break;
      case 'Rectangle':
        final h = (size.height - padding * 2) * 0.65;
        final oY = (size.height - h) / 2;
        canvas.drawRect(
          Rect.fromLTWH(
              padding, oY, size.width - padding * 2, h),
          paint,
        );
        break;
      default: // Circle
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          (min(size.width, size.height) / 2) - padding,
          paint,
        );
    }
  }

  List<Offset> _getNails(Size size, double padding) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final nails = <Offset>[];

    switch (shape) {
      case 'Square':
        final w = size.width - padding * 2;
        final h = size.height - padding * 2;
        final perSide = nailCount ~/ 4;
        final extra = nailCount - perSide * 4;
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              padding + w * i / perSide, padding));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(size.width - padding,
              padding + h * i / perSide));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              size.width - padding - w * i / perSide,
              size.height - padding));
        }
        for (int i = 0; i < perSide + extra; i++) {
          nails.add(Offset(padding,
              size.height - padding - h * i /
                  max(perSide + extra - 1, 1)));
        }
        break;

      case 'Rectangle':
        final w = size.width - padding * 2;
        final h = (size.height - padding * 2) * 0.65;
        final oY = (size.height - h) / 2;
        final perim = 2 * w + 2 * h;
        final topN =
        (nailCount * w / perim).round();
        final sideN =
        (nailCount * h / perim).round();
        for (int i = 0; i < topN; i++) {
          nails.add(Offset(
              padding + w * i / max(topN - 1, 1),
              oY));
        }
        for (int i = 0; i < sideN; i++) {
          nails.add(Offset(size.width - padding,
              oY + h * i / max(sideN - 1, 1)));
        }
        for (int i = 0; i < topN; i++) {
          nails.add(Offset(
              size.width - padding -
                  w * i / max(topN - 1, 1),
              oY + h));
        }
        final leftN = nailCount - nails.length;
        for (int i = 0; i < leftN; i++) {
          nails.add(Offset(padding,
              oY + h - h * i / max(leftN - 1, 1)));
        }
        break;

      default: // Circle
        final r =
        (min(cx, cy) - padding);
        for (int i = 0; i < nailCount; i++) {
          final angle =
              (2 * pi * i / nailCount) - (pi / 2);
          nails.add(Offset(
            cx + r * cos(angle),
            cy + r * sin(angle),
          ));
        }
    }

    return nails.take(nailCount).toList();
  }

  @override
  bool shouldRepaint(_NailMapPainter old) =>

      old.nailPath.length != nailPath.length ||

          old.shape != shape;

}