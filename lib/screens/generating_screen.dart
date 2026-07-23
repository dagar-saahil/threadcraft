import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../features/thread_art/algorithm/thread_algorithm.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import 'preview_screen.dart';
import '../features/rgb_art/rgb_algorithm.dart';
import 'rgb_work_mode_screen.dart';
import 'rgb_preview_screen.dart';
import '../models/project_model.dart';
class GeneratingScreen extends StatefulWidget {
  final File imageFile;
  final int nailCount;
  final String shape;
  final String density;
  final String artType; // 'Thread', 'RGB'
  final Color threadColor;
  const GeneratingScreen({
    super.key,
    required this.imageFile,
    required this.nailCount,
    required this.shape,
    required this.density,
    this.artType = 'Thread',
    this.threadColor = Colors.white,
  });

  @override
  State<GeneratingScreen> createState() =>
      _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Loading your image...';
  bool _isDone = false;

  late AnimationController _ringController;
  late AnimationController _pulseController;

  final List<String> _tips = [
    'Higher nail count = more detail.',
    'Portrait photos work best.',
    'Dark backgrounds give clearer results.',
    'Medium density is great for beginners.',
    'You can undo steps while creating!',
    'Try the completion preview before starting.',
  ];
  int _currentTip = 0;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startTipCycle();
    _startGeneration();
  }

  void _startTipCycle() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      setState(() => _currentTip =
          (_currentTip + 1) % _tips.length);
      return !_isDone;
    });
  }

  Future<void> _startGeneration() async {
    _setStatus('Loading your image...', 0.1);
    await Future.delayed(const Duration(milliseconds: 400));

    final bytes = await widget.imageFile.readAsBytes();

    _setStatus('Processing image...', 0.25);
    await Future.delayed(const Duration(milliseconds: 300));

    final type = widget.artType.toLowerCase();

    if (type.contains('rgb')) {
      await _generateRGBArt(bytes);
    } else {
      await _generateThreadArt(bytes);
    }
  }

  // ── THREAD ART ──
  Future<void> _generateThreadArt(
      Uint8List bytes) async {
    _setStatus('Enhancing image contrast...', 0.40);
    await Future.delayed(const Duration(milliseconds: 200));

    _setStatus('Calculating nail positions...', 0.55);
    await Future.delayed(const Duration(milliseconds: 200));

    _setStatus('Generating thread path...', 0.65);

    final path = await compute(_runThreadAlgorithm, {
      'imageBytes': bytes,
      'nailCount': widget.nailCount,
      'shape': widget.shape,
      'density': widget.density,
    });

    _setStatus('Almost ready...', 0.88);
    await Future.delayed(const Duration(milliseconds: 500));

    _setStatus('Your artwork is ready! ✨', 1.0);
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      await _saveAndNavigateThread(path, bytes);
    }
  }

  Future<void> _generateRGBArt(Uint8List bytes) async {
    _setStatus('Analysing image colours...', 0.20);
    await Future.delayed(const Duration(milliseconds: 200));

    _setStatus('Building multi-pass RGB model...', 0.35);

    // Single compute call — multi-pass runs inside the isolate
    // The virtual canvas is shared across all 3 channels
    final result = await compute(
        _runMultiPassRGB, {
      'imageBytes': bytes,
      'nailCount': widget.nailCount,
      'shape': widget.shape,
      'density': widget.density,
    });

    _setStatus('Merging RGB layers...', 0.85);
    await Future.delayed(const Duration(milliseconds: 300));

    final blueResult =
    List<int>.from(result['blue'] as List);
    final redResult =
    List<int>.from(result['red'] as List);
    final greenResult =
    List<int>.from(result['green'] as List);

    _setStatus('RGB art ready! 🎨', 1.0);
    await Future.delayed(
        const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isDone = true);

      final projectId =
      DateTime.now().millisecondsSinceEpoch.toString();

      final project = ProjectModel(
        id: projectId,
        name:
        'RGB Art ${DateTime.now().day}/${DateTime.now().month}',
        imagePath: widget.imageFile.path,
        nailCount: widget.nailCount,
        shape: widget.shape,
        density: widget.density,
        nailPath: blueResult,
        currentStep: 0,
        createdAt: DateTime.now(),
        isRGB: true,
        redPath: redResult,
        greenPath: greenResult,
        currentPhase: 0,
      );

      await context.read<ProjectService>().saveProject(project);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RGBPreviewScreen(
            imageFile: widget.imageFile,
            redPath: redResult,
            greenPath: greenResult,
            bluePath: blueResult,
            nailCount: widget.nailCount,
            shape: widget.shape,
            density: widget.density,
            projectId: projectId,
            startPhase: 0,
            startStep: 0,
          ),
        ),
      );
    }
  }

  Future<void> _saveAndNavigateThread(
      List<int> path, Uint8List bytes) async {
    final projectId =
    DateTime.now().millisecondsSinceEpoch.toString();

    final project = ProjectModel(
      id: projectId,
      name:
      'ThreadCRAFT ${DateTime.now().day}/${DateTime.now().month}',
      imagePath: widget.imageFile.path,
      nailCount: widget.nailCount,
      shape: widget.shape,
      density: widget.density,
      nailPath: path,
      currentStep: 0,
      createdAt: DateTime.now(),
    );

    if (mounted) {
      await context.read<ProjectService>().saveProject(project);

      setState(() => _isDone = true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageFile: widget.imageFile,
            nailPath: path,
            nailCount: widget.nailCount,
            shape: widget.shape,
            density: widget.density,
            threadColor: widget.threadColor,
            projectId: projectId,
            startStep: 0,

          ),
        ),
      );
    }
  }

  void _setStatus(String text, double progress) {
    if (mounted) {
      setState(() {
        _statusText = text;
        _progress = progress;
      });
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.purple;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Text(
          'Generating ${widget.artType} Art',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            _buildNailRing(typeColor),
            const SizedBox(height: 32),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ).animate(key: ValueKey(_statusText)).fadeIn(),
            const SizedBox(height: 20),
            _buildProgressBar(typeColor),
            const Spacer(),
            _buildTipCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNailRing(Color color) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _ringController,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    color,
                    AppColors.pink,
                    AppColors.orange,
                    color,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 5),
                ],
              ),
            ),
          ),
          Container(
            width: 218,
            height: 218,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
          ClipOval(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
          ),
          ..._buildNailDots(color),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
      begin: const Offset(0.8, 0.8),
      curve: Curves.elasticOut,
      duration: 800.ms,
    );
  }

  List<Widget> _buildNailDots(Color color) {
    final dots = <Widget>[];
    final total = 28;
    const ringRadius = 123.0;
    const center = 125.0;

    for (int i = 0; i < total; i++) {
      final angle = (2 * pi * i) / total;
      final x = center + ringRadius * cos(angle) - 4;      final y = center + ringRadius * sin(angle) - 4;

      dots.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final pulse = sin(
                  _pulseController.value * pi + i * 0.4);
              final opacity =
              (0.4 + pulse * 0.6).clamp(0.0, 1.0);
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(opacity),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 6)
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return dots;
  }

  Widget _buildProgressBar(Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12)),
            Text(
              '${(_progress * 100).round()}%',
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 8,
            color: Colors.white.withOpacity(0.08),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 400),
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, AppColors.pink],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: AppColors.orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text('Tip',
                    style: GoogleFonts.poppins(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(_tips[_currentTip],
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12))
                    .animate(key: ValueKey(_currentTip))
                    .fadeIn(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── BACKGROUND ISOLATE FUNCTIONS ──
List<int> _runThreadAlgorithm(
    Map<String, dynamic> params) {
  final bytes =
  Uint8List.fromList(params['imageBytes'] as List<int>);
  final image = img.decodeImage(bytes);
  if (image == null) return [];
  return ThreadAlgorithm.generate(
    image: image,
    nailCount: params['nailCount'] as int,
    shape: params['shape'] as String,
    density: params['density'] as String,
  );
}

Map<String, List<int>> _runRGBAlgorithm(
    Map<String, dynamic> params) {
  final bytes = Uint8List.fromList(
      params['imageBytes'] as List<int>);
  final image = img.decodeImage(bytes);
  if (image == null) {
    return {'red': [], 'green': [], 'blue': []};
  }
  final paths = RGBAlgorithm.generate(
    image: image,
    nailCount: params['nailCount'] as int,
    shape: params['shape'] as String,
    density: params['density'] as String,
  );
  return {
    'red': paths.red,
    'green': paths.green,
    'blue': paths.blue,
  };
}
// ── New: single compute call for multi-pass RGB ──
Map<String, List<int>> _runMultiPassRGB(
    Map<String, dynamic> params) {
  final bytes = Uint8List.fromList(
      params['imageBytes'] as List<int>);
  final image = img.decodeImage(bytes);
  if (image == null) {
    return {'red': [], 'green': [], 'blue': []};
  }

  final paths = RGBAlgorithm.generate(
    image: image,
    nailCount: params['nailCount'] as int,
    shape: params['shape'] as String,
    density: params['density'] as String,
  );

  return {
    'red': paths.red,
    'green': paths.green,
    'blue': paths.blue,
  };
}
// ── Single channel RGB isolate ──
List<int> _runSingleChannelAlgorithm(
    Map<String, dynamic> params) {
  final bytes = Uint8List.fromList(
      params['imageBytes'] as List<int>);
  final image = img.decodeImage(bytes);
  if (image == null) return [];

  return RGBAlgorithm.generateSingleChannel(
    image: image,
    nailCount: params['nailCount'] as int,
    shape: params['shape'] as String,
    density: params['density'] as String,
    channel: params['channel'] as String,
  );
}