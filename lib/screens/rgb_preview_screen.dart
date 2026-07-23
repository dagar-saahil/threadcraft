import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_colors.dart';
import '../features/rgb_art/rgb_ring_painter.dart';
import '../models/project_model.dart';
import '../services/pdf_export_service.dart';
import '../services/project_service.dart';
import '../widgets/gradient_button.dart';
import 'rgb_work_mode_screen.dart';

class RGBPreviewScreen extends StatefulWidget {
  final File imageFile;
  final List<int> redPath;
  final List<int> greenPath;
  final List<int> bluePath;
  final int nailCount;
  final String shape;
  final String density;
  final String? projectId;
  final int startPhase;
  final int startStep;

  const RGBPreviewScreen({
    super.key,
    required this.imageFile,
    required this.redPath,
    required this.greenPath,
    required this.bluePath,
    required this.nailCount,
    required this.shape,
    required this.density,
    this.projectId,
    this.startPhase = 0,
    this.startStep = 0,
  });

  @override
  State<RGBPreviewScreen> createState() =>
      _RGBPreviewScreenState();
}

class _RGBPreviewScreenState
    extends State<RGBPreviewScreen> {
  bool _showNailMap = false;
  double _previewProgress = 1.0;
  bool _showBackground = true;
  bool _isExporting = false;

  // Real saved progress
  late int _currentStartPhase;
  late int _currentStartStep;

  ui.Image? _bgImage;
  final TransformationController _transformController =
  TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  // ── Phase data ──
  int get _totalSteps =>
      widget.bluePath.length +
          widget.redPath.length +
          widget.greenPath.length;

  int get _previewTotalSteps =>
      (_previewProgress * _totalSteps)
          .round()
          .clamp(0, _totalSteps);

  double get _actualOverallProgress {
    final total = _totalSteps;
    if (total == 0) return 0;
    int done = 0;
    if (_currentStartPhase > 0) {
      done += widget.bluePath.length;
    }
    if (_currentStartPhase > 1) {
      done += widget.redPath.length;
    }
    done += _currentStartStep;
    return (done / total).clamp(0.0, 1.0);
  }

  List<int> get _previewBlue {
    if (widget.bluePath.isEmpty) return [];
    final show = (widget.bluePath.length * _previewProgress)
        .round()
        .clamp(0, widget.bluePath.length);
    if (show <= 0) return [];
    return widget.bluePath.sublist(0, show);
  }

  List<int> get _previewRed {
    if (widget.redPath.isEmpty) return [];
    final show = (widget.redPath.length * _previewProgress)
        .round()
        .clamp(0, widget.redPath.length);
    if (show <= 0) return [];
    return widget.redPath.sublist(0, show);
  }

  List<int> get _previewGreen {
    if (widget.greenPath.isEmpty) return [];
    final show = (widget.greenPath.length * _previewProgress)
        .round()
        .clamp(0, widget.greenPath.length);
    if (show <= 0) return [];
    return widget.greenPath.sublist(0, show);
  }

  @override
  void initState() {
    super.initState();
    _currentStartPhase = widget.startPhase;
    _currentStartStep = widget.startStep;
    _loadImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() =>
        _previewProgress = _actualOverallProgress > 0
            ? _actualOverallProgress
            : 1.0);
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

          // ── View toggle ──
          _buildViewToggle(),

          const SizedBox(height: 10),

          // ── RGB Preview slider ──
          if (!_showNailMap) _buildRGBSlider(),

          if (!_showNailMap) const SizedBox(height: 10),

          // ── Canvas ──
          Expanded(child: _buildCanvas()),

          // ── Bottom section ──
          _buildBottomSection(),
        ],
      ),
    );
  }

  // ── APP BAR ──
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌈',
              style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('RGB Preview',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _shareImage,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.ios_share,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // ── VIEW TOGGLE ──
  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
        onTap: () =>
            setState(() => _showNailMap = label == 'Nail Map'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                colors: [Colors.red, Colors.blue])
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
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

  // ── RGB SLIDER ──
  Widget _buildRGBSlider() {
    final actual = _actualOverallProgress;
    final isCustom =
        (_previewProgress - actual).abs() > 0.01;

    final total = _totalSteps;
    final blueEnd =
    total == 0 ? 0.33 : widget.bluePath.length / total;
    final redEnd = total == 0
        ? 0.66
        : (widget.bluePath.length + widget.redPath.length) /
        total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(
            children: [
              const Icon(Icons.preview_rounded,
                  color: AppColors.textMuted, size: 12),
              const SizedBox(width: 5),
              Text(
                'RGB Completion Preview',
                style: GoogleFonts.poppins(
                    color: AppColors.textMuted,
                    fontSize: 11),
              ),
              const Spacer(),
              if (isCustom)
                GestureDetector(
                  onTap: () => setState(
                          () => _previewProgress = actual),
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

          // Quick % buttons
          Row(
            children: [
              {'label': '25%', 'val': 0.25, 'color': Colors.blue},
              {'label': '50%', 'val': 0.50, 'color': Colors.purple},
              {'label': '75%', 'val': 0.75, 'color': Colors.red},
              {'label': '100%', 'val': 1.0, 'color': Colors.green},
            ].map((opt) {
              final val = opt['val'] as double;
              final color = opt['color'] as Color;
              final isSel =
                  (_previewProgress - val).abs() < 0.01;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _previewProgress = val),
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? color.withOpacity(0.2)
                          : AppColors.card,
                      borderRadius:
                      BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? color
                            : Colors.white.withOpacity(0.07),
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(opt['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: isSel
                              ? color
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Smooth slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8),
              activeTrackColor: isCustom
                  ? AppColors.orange
                  : Colors.blue,
              thumbColor:
              isCustom ? AppColors.orange : Colors.blue,
              inactiveTrackColor:
              Colors.white.withOpacity(0.1),
            ),
            child: Slider(
              value: _previewProgress,
              min: 0.0,
              max: 1.0,
              onChanged: (val) =>
                  setState(() => _previewProgress = val),
            ),
          ),

          // Phase labels
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
            children: [
              _phaseLabel('🔵', 'Blue',
                  Colors.blue,
                  _previewTotalSteps >=
                      widget.bluePath.length),
              _phaseLabel('🔴', 'Red',
                  Colors.red,
                  _previewTotalSteps >=
                      widget.bluePath.length +
                          widget.redPath.length),
              _phaseLabel('🟢', 'Green',
                  Colors.green,
                  _previewTotalSteps >= _totalSteps),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _phaseLabel(
      String emoji, String label, Color color, bool done) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji,
          style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.poppins(
              color: done ? color : AppColors.textMuted,
              fontSize: 9,
              fontWeight: done
                  ? FontWeight.bold
                  : FontWeight.normal)),
      const SizedBox(width: 2),
      Icon(
          done
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: done ? color : AppColors.textMuted,
          size: 9),
    ]);
  }

  // ── CANVAS ──
  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: RepaintBoundary(
          key: _canvasKey,
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.5,
            maxScale: 5.0,
            child: _showNailMap
                ? _buildNailMapCanvas()
                : _buildRGBCanvas(),
          ),
        ),
      ),
    );
  }

  Widget _buildRGBCanvas() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: RGBRingPainter(
          nailCount: widget.nailCount,
          shape: widget.shape,
          backgroundImage:
          _showBackground ? _bgImage : null,
          completedRed: _previewRed,
          completedGreen: _previewGreen,
          completedBlue: _previewBlue,
          currentNail:
          widget.bluePath.isNotEmpty
              ? widget.bluePath[0]
              : 0,
          nextNail:
          widget.bluePath.isNotEmpty
              ? widget.bluePath.last
              : 0,
          activeColor: 'Blue',
        ),
      ),
    );
  }

  Widget _buildNailMapCanvas() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: _RGBNailMapPainter(
          nailCount: widget.nailCount,
          shape: widget.shape,
          bluePath: widget.bluePath,
          redPath: widget.redPath,
          greenPath: widget.greenPath,
        ),
      ),
    );
  }

  // ── BOTTOM SECTION ──
  Widget _buildBottomSection() {
    final hasProgress =
        _currentStartPhase > 0 ||
            _currentStartStep > 0;
    final actual = _actualOverallProgress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      padding:
      const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── START / CONTINUE button ──
          GestureDetector(
            onTap: _goToWorkMode,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.red,
                    Colors.green],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius:
                BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue
                        .withOpacity(0.3),
                    blurRadius: 16,
                  )
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
                              ? 'Continue RGB Art'
                              : 'Start RGB Creation',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        Text(
                          hasProgress
                              ? 'Resume from ${(actual * 100).toStringAsFixed(0)}% — ${_phaseName(_currentStartPhase)} phase'
                              : 'Voice guided step by step',
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
                      color: Colors.white
                          .withOpacity(0.2),
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
          ),

          const SizedBox(height: 10),

          // ── CANVAS TOGGLES ──
          Row(
            children: [
              // Background toggle
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                          () => _showBackground =
                      !_showBackground),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 200),
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 9),
                    decoration: BoxDecoration(
                      color: _showBackground
                          ? Colors.blue
                          .withOpacity(0.15)
                          : AppColors.card,
                      borderRadius:
                      BorderRadius.circular(10),
                      border: Border.all(
                        color: _showBackground
                            ? Colors.blue
                            .withOpacity(0.4)
                            : Colors.white
                            .withOpacity(0.07),
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
                              ? Colors.blue
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
                                ? Colors.blue
                                : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // RGB mode label
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.red
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red
                            .withOpacity(0.25)),
                  ),
                  child: const Column(
                    children: [
                      Text('🌈',
                          style: TextStyle(
                              fontSize: 16)),
                      SizedBox(height: 2),
                      Text('RGB Mode',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── ACTION BUTTONS ──
          Row(
            children: [
              _actionBtn(
                icon: Icons.save_outlined,
                label: 'Save',
                color: AppColors.purple,
                onTap: _saveProject,
              ),
              const SizedBox(width: 8),
              _actionBtn(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Export PDF',
                color: AppColors.orange,
                onTap: _exportPdf,
              ),
              const SizedBox(width: 8),
              _actionBtn(
                icon: Icons.grain,
                label: 'Nail Map',
                color: Colors.blue,
                onTap: () => setState(
                        () => _showNailMap = true),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 400.ms);
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 10),
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
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ── NAVIGATE TO WORK MODE ──
  Future<void> _goToWorkMode() async {
    final returnedData =
    await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => RGBWorkModeScreen(
          imageFile: widget.imageFile,
          redPath: widget.redPath,
          greenPath: widget.greenPath,
          bluePath: widget.bluePath,
          nailCount: widget.nailCount,
          shape: widget.shape,
          startPhase: _currentStartPhase,
          startStep: _currentStartStep,
          projectId: widget.projectId,
        ),
      ),
    );

    // Update saved progress when user comes back
    if (returnedData != null && mounted) {
      setState(() {
        _currentStartPhase =
            returnedData['phase'] ?? _currentStartPhase;
        _currentStartStep =
            returnedData['step'] ?? _currentStartStep;
        _previewProgress = _actualOverallProgress;
      });
    }
  }

  // ── SAVE PROJECT ──
  Future<void> _saveProject() async {
    try {
      _showSnack('Saving...');
      final projectService =
      context.read<ProjectService>();

      if (widget.projectId != null) {
        await projectService.updateRGBProgress(
          widget.projectId!,
          _currentStartPhase,
          _currentStartStep,
        );
        _showSnack('RGB project updated! ✅');
        return;
      }

      final newId = DateTime.now()
          .millisecondsSinceEpoch
          .toString();

      final project = ProjectModel(
        id: newId,
        name:
        'RGB Art ${DateTime.now().day}/${DateTime.now().month}',
        imagePath: widget.imageFile.path,
        nailCount: widget.nailCount,
        shape: widget.shape,
        density: widget.density,
        nailPath: widget.bluePath,
        currentStep: _currentStartStep,
        createdAt: DateTime.now(),
        isRGB: true,
        redPath: widget.redPath,
        greenPath: widget.greenPath,
        currentPhase: _currentStartPhase,
      );

      await projectService.saveProject(project);
      _showSnack('Saved to My Projects! ✅');
    } catch (e) {
      _showSnack('Save failed!', isError: true);
    }
  }

  // ── EXPORT PDF ──
  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    _showSnack('Building RGB PDF...');
    try {
      // Export RGB step list
      final allSteps = [
        ...widget.bluePath.asMap().entries.map(
              (e) => '🔵 Step ${e.key + 1}: '
              'Nail ${e.value + 1} → '
              '${e.key + 1 < widget.bluePath.length ? widget.bluePath[e.key + 1] + 1 : "end"}',
        ),
        ...widget.redPath.asMap().entries.map(
              (e) => '🔴 Step ${e.key + 1}: '
              'Nail ${e.value + 1} → '
              '${e.key + 1 < widget.redPath.length ? widget.redPath[e.key + 1] + 1 : "end"}',
        ),
        ...widget.greenPath.asMap().entries.map(
              (e) => '🟢 Step ${e.key + 1}: '
              'Nail ${e.value + 1} → '
              '${e.key + 1 < widget.greenPath.length ? widget.greenPath[e.key + 1] + 1 : "end"}',
        ),
      ];

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/RGB_ThreadCRAFT_${widget.shape}.txt');
      await file.writeAsString(
          'ThreadCRAFT RGB Guide\n'
              '${widget.shape} | ${widget.nailCount} nails\n\n'
              '${allSteps.join('\n')}');

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ThreadCRAFT RGB Step Guide',
      );
    } catch (e) {
      _showSnack('Export failed!', isError: true);
    } finally {
      if (mounted)
        setState(() => _isExporting = false);
    }
  }

  Future<void> _shareImage() async {
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
      final file =
      File('${dir.path}/rgb_preview.png');
      await file.writeAsBytes(
          byteData.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)],
          text: 'My RGB ThreadCRAFT artwork! 🌈');
    } catch (_) {}
  }

  String _phaseName(int phase) {
    switch (phase) {
      case 0: return 'Blue';
      case 1: return 'Red';
      default: return 'Green';
    }
  }

  void _showSnack(String msg,
      {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        isError ? Colors.red.shade800 : AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Text(msg,
            style: GoogleFonts.poppins(
                color: Colors.white)),
      ),
    );
  }
}

// ── RGB NAIL MAP PAINTER ──
class _RGBNailMapPainter extends CustomPainter {
  final int nailCount;
  final String shape;
  final List<int> bluePath;
  final List<int> redPath;
  final List<int> greenPath;

  const _RGBNailMapPainter({
    required this.nailCount,
    required this.shape,
    required this.bluePath,
    required this.redPath,
    required this.greenPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );

    final cx = size.width / 2;
    final cy = size.height / 2;
    const padding = 28.0;
    final nails = _getNails(size, padding);

    // Outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (shape == 'Circle') {
      canvas.drawCircle(
        Offset(cx, cy),
        min(cx, cy) - padding,
        outlinePaint,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(padding, padding,
            size.width - padding * 2,
            size.height - padding * 2),
        outlinePaint,
      );
    }

    // RGB threads
    _drawLines(canvas, nails, bluePath,
        Colors.blue.withOpacity(0.35));
    _drawLines(canvas, nails, redPath,
        Colors.red.withOpacity(0.35));
    _drawLines(canvas, nails, greenPath,
        Colors.green.withOpacity(0.35));

    // Nails
    for (int i = 0; i < nails.length; i++) {
      canvas.drawCircle(nails[i], 3,
          Paint()..color = Colors.white.withOpacity(0.7));

      if (i % 10 == 0) {
        final dx = nails[i].dx - cx;
        final dy = nails[i].dy - cy;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist == 0) continue;
        final lx = nails[i].dx + (dx / dist) * 13;
        final ly = nails[i].dy + (dy / dist) * 13;
        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(
                color: Colors.white54, fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            (lx - tp.width / 2)
                .clamp(1.0, size.width - tp.width - 1),
            (ly - tp.height / 2)
                .clamp(1.0, size.height - tp.height - 1),
          ),
        );
      }
    }
  }

  void _drawLines(Canvas canvas, List<Offset> nails,
      List<int> path, Color color) {
    if (path.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (int i = 0; i < path.length - 1; i++) {
      if (path[i] < nails.length &&
          path[i + 1] < nails.length) {
        canvas.drawLine(
            nails[path[i]], nails[path[i + 1]], paint);
      }
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
          nails.add(
              Offset(padding + w * i / perSide, padding));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              size.width - padding,
              padding + h * i / perSide));
        }
        for (int i = 0; i < perSide; i++) {
          nails.add(Offset(
              size.width - padding - w * i / perSide,
              size.height - padding));
        }
        for (int i = 0; i < perSide + extra; i++) {
          nails.add(Offset(padding,
              size.height -
                  padding -
                  h * i / max(perSide + extra - 1, 1)));
        }
        break;
      default:
        final r = min(cx, cy) - padding;
        for (int i = 0; i < nailCount; i++) {
          final a =
              (2 * pi * i / nailCount) - (pi / 2);
          nails.add(
              Offset(cx + r * cos(a), cy + r * sin(a)));
        }
    }
    return nails.take(nailCount).toList();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) =>
      false;
}