import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../services/recommendation_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glow_card.dart';
import 'image_crop_screen.dart';
import '../services/premium_service.dart';
import 'premium_screen.dart';
import 'package:provider/provider.dart';
class NewProjectScreen extends StatefulWidget {
  final String artType;

  const NewProjectScreen({
    super.key,
    this.artType = 'Thread Art',
  });

  @override
  State<NewProjectScreen> createState() =>
      _NewProjectScreenState();
}

class _NewProjectScreenState
    extends State<NewProjectScreen> {
  Color _selectedThreadColor = Colors.white;
  File? _selectedImage;
  String _selectedShape = 'Circle';
  double _nailCount = 200;
  String _threadDensity = 'Medium';
  String _selectedPreset = 'Balanced';
  bool _isRGBMode = false;
  // Thread size — default Normal
  ThreadSize _selectedThreadSize =
  RecommendationService.threadSizes[2];

  // Board size — default Medium
  BoardSize _selectedBoardSize =
  RecommendationService.boardSizes[1];

  final ImagePicker _picker = ImagePicker();

  // Presets list
  final List<Map<String, dynamic>> _threadColors = [
    {'name': 'White', 'color': Colors.white},
    {'name': 'Black', 'color': Colors.black},
    {'name': 'Gold', 'color': const Color(0xFFFFD700)},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Purple', 'color': AppColors.purple},
    {'name': 'Pink', 'color': AppColors.pink},
    {'name': 'Cyan', 'color': AppColors.cyan},
    {'name': 'Orange', 'color': AppColors.orange},
    {'name': 'Green', 'color': Colors.green},
  ];
  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Beginner',
      'desc': 'Easy to follow\nFirst timer',
      'nails': 100,
      'density': 'Low',
      'color': AppColors.cyan,
      'icon': Icons.star_border_rounded,
    },
    {
      'name': 'Balanced',
      'desc': 'Great detail\nRecommended',
      'nails': 200,
      'density': 'Medium',
      'color': AppColors.purple,
      'icon': Icons.auto_awesome,
    },
    {
      'name': 'Detailed',
      'desc': 'High quality\nPortraits',
      'nails': 300,
      'density': 'High',
      'color': AppColors.pink,
      'icon': Icons.diamond_outlined,
    },
    {
      'name': 'Ultra',
      'desc': 'Max detail\nBest results',
      'nails': 400,
      'density': 'High',
      'color': AppColors.orange,
      'icon': Icons.workspace_premium_rounded,
    },
  ];

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(
              () => _selectedImage = File(picked.path));
    }
  }

  // Apply preset — sets all values at once
  void _applyPreset(String presetName) {
    final rec = RecommendationService
        .getRecommendation(presetName);
    setState(() {
      _selectedPreset = presetName;
      _nailCount = rec.nailCount.toDouble();
      _threadDensity = rec.density;
      _selectedThreadSize = rec.threadSize;
      _selectedBoardSize = rec.boardSize;
    });
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
              border: Border.all(
                  color:
                  Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16),
          ),
        ),
        title: Text(
          'New Project',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // ─────────────────────
            // 1. CHOOSE IMAGE
            // ─────────────────────
            _sectionTitle('1. Choose Image'),
            const SizedBox(height: 12),
            _buildImagePicker(),

            const SizedBox(height: 24),

            // ─────────────────────
            // SMART PRESETS
            // ─────────────────────
            _buildSmartPresets(),

            const SizedBox(height: 24),

            // ─────────────────────
            // RECOMMENDED SETUP CARD
            // Shows when preset selected
            // ─────────────────────
            _buildRecommendedSetup(),

            const SizedBox(height: 24),

            // ─────────────────────
            // 2. FRAME SHAPE
            // ─────────────────────
            _sectionTitle('2. Frame Shape'),
            const SizedBox(height: 12),
            _buildShapeSelector(),

            const SizedBox(height: 24),

            // ─────────────────────
            // 3. NUMBER OF NAILS
            // ─────────────────────
            _sectionTitle('3. Number of Nails'),
            const SizedBox(height: 12),
            _buildNailSlider(),

            const SizedBox(height: 24),

            // ─────────────────────
            // 4. THREAD DENSITY
            // ─────────────────────
            _sectionTitle('4. Thread Density'),
            const SizedBox(height: 12),
            _buildDensitySelector(),

            const SizedBox(height: 24),

            // ─────────────────────
            // 5. THREAD SIZE
            // ─────────────────────
            _sectionTitle('5. Thread Size'),
            const SizedBox(height: 12),
            _buildThreadSizeSelector(),

            const SizedBox(height: 24),
            // ── THREAD COLOR ──
            _sectionTitle('6. Thread Color'),
            const SizedBox(height: 12),
            _buildThreadColorPicker(),

            const SizedBox(height: 24),
            // ─────────────────────
            // 6. BOARD SIZE
            // ─────────────────────
            _sectionTitle('6. Board Size'),
            const SizedBox(height: 12),
            _buildBoardSizeSelector(),

            const SizedBox(height: 32),
              // ── THREAD MODE SELECTOR ──
            _sectionTitle('7. Thread Mode'),
            const SizedBox(height: 12),
            _buildThreadModeSelector(),

            const SizedBox(height: 24),

            // ─────────────────────
            // GENERATE BUTTON
            // ─────────────────────
            GradientButton(
              text: 'Generate Pattern',
              icon: Icons.auto_awesome,
              gradient: AppColors.accentGradient,
              onTap: _onGenerate,
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section title ──
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Image Picker ──
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImage != null
                ? AppColors.purple
                : Colors.white.withOpacity(0.1),
            width: _selectedImage != null ? 2 : 1,
          ),
          color: AppColors.card,
          boxShadow: _selectedImage != null
              ? [
            BoxShadow(
                color: AppColors.purpleGlow,
                blurRadius: 20)
          ]
              : [],
        ),
        child: _selectedImage != null
            ? ClipRRect(
          borderRadius:
          BorderRadius.circular(19),
          child: Image.file(_selectedImage!,
              fit: BoxFit.cover),
        )
            : Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient:
                AppColors.primaryGradient,
                borderRadius:
                BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color:
                      AppColors.purpleGlow,
                      blurRadius: 16)
                ],
              ),
              child: const Icon(
                  Icons
                      .add_photo_alternate_outlined,
                  color: Colors.white,
                  size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to choose a photo',
              style: GoogleFonts.poppins(
                  color:
                  AppColors.textSecondary,
                  fontSize: 14),
            ),
            Text(
              'Portrait or face photos work best',
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 11),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Smart Presets ──
  Widget _buildSmartPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.primaryGradient
                      .createShader(b),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Smart Presets',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '— auto fills everything',
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            itemBuilder: (context, i) {
              final preset = _presets[i];
              final color = preset['color'] as Color;
              final isSelected =
                  _selectedPreset == preset['name'];

              return GestureDetector(
                onTap: () =>
                    _applyPreset(preset['name']),
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 250),
                  width: 125,
                  margin: const EdgeInsets.only(
                      right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ])
                        : null,
                    color: isSelected
                        ? null
                        : AppColors.card,
                    borderRadius:
                    BorderRadius.circular(16),
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
                          blurRadius: 12)
                    ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                          preset['icon'] as IconData,
                          color: color,
                          size: 18),
                      const SizedBox(height: 6),
                      Text(
                        preset['name'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        preset['desc'] as String,
                        style: GoogleFonts.poppins(
                          color:
                          AppColors.textSecondary,
                          fontSize: 9,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${preset['nails']} nails',
                        style: GoogleFonts.poppins(
                            color: color,
                            fontSize: 10,
                            fontWeight:
                            FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  // ── Recommended Setup Card ──
  Widget _buildRecommendedSetup() {
    final rec = RecommendationService
        .getRecommendation(_selectedPreset);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.15),
            AppColors.pink.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.recommend_rounded,
                  color: AppColors.purple, size: 18),
              const SizedBox(width: 8),
              Text(
                'Recommended Setup',
                style: GoogleFonts.poppins(
                  color: AppColors.purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                  AppColors.purple.withOpacity(0.2),
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedPreset,
                  style: GoogleFonts.poppins(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4 info boxes in a row
          Row(
            children: [
              _infoBox('Nails',
                  '${rec.nailCount}', AppColors.purple),
              _infoBox('Board',
                  '${rec.boardSize.cm} cm',
                  AppColors.pink),
              _infoBox('Thread',
                  rec.threadSize.mm,
                  AppColors.orange),
              _infoBox('Lines',
                  '~${rec.estimatedLines}',
                  AppColors.cyan),
            ],
          ),

          const SizedBox(height: 10),

          // Nail spacing
          Row(
            children: [
              const Icon(Icons.straighten,
                  color: AppColors.textMuted,
                  size: 13),
              const SizedBox(width: 6),
              Text(
                'Nail spacing: ${rec.boardSize.nailSpacing}  •  ${rec.density} density',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Reason
          Text(
            rec.reason,
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _infoBox(
      String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shape Selector ──
  Widget _buildShapeSelector() {
    final shapes = [
      {'label': 'Circle', 'icon': Icons.circle_outlined},
      {'label': 'Square', 'icon': Icons.crop_square},
      {'label': 'Rectangle',
        'icon': Icons.crop_landscape},
    ];

    return Row(
      children: shapes.map((shape) {
        final label = shape['label'] as String;
        final icon = shape['icon'] as IconData;
        final isSelected = _selectedShape == label;

        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _selectedShape = label),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.primaryGradient
                    : null,
                color: isSelected
                    ? null
                    : AppColors.card,
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.08),
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 16)
                ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color: Colors.white, size: 22),
                  const SizedBox(height: 6),
                  Text(label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Nail Slider ──
  Widget _buildNailSlider() {
    return GlowCard(
      padding:
      const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Nails:',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 13)),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.primaryGradient
                        .createShader(b),
                child: Text(
                  '${_nailCount.round()}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10),
              activeTrackColor: AppColors.purple,
              thumbColor: AppColors.pink,
              inactiveTrackColor:
              Colors.white.withOpacity(0.1),
            ),
            child: Slider(
              value: _nailCount,
              min: 50,
              max: 400,
              divisions: 70,
              onChanged: (v) =>
                  setState(() => _nailCount = v),
            ),
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text('50',
                  style: GoogleFonts.poppins(
                      color: AppColors.textMuted,
                      fontSize: 11)),
              Text('More nails = more detail',
                  style: GoogleFonts.poppins(
                      color: AppColors.textMuted,
                      fontSize: 11)),
              Text('400',
                  style: GoogleFonts.poppins(
                      color: AppColors.textMuted,
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Density Selector ──
  Widget _buildDensitySelector() {
    final options = [
      {'label': 'Low', 'desc': 'Faster',
        'icon': Icons.show_chart},
      {'label': 'Medium', 'desc': 'Balanced',
        'icon': Icons.stacked_line_chart},
      {'label': 'High', 'desc': 'Most Detail',
        'icon': Icons.bar_chart},
    ];

    return Row(
      children: options.map((opt) {
        final label = opt['label'] as String;
        final isSelected = _threadDensity == label;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _threadDensity = label),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.primaryGradient
                    : null,
                color: isSelected
                    ? null
                    : AppColors.card,
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.08),
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 16)
                ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(opt['icon'] as IconData,
                      color: Colors.white, size: 20),
                  const SizedBox(height: 6),
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  Text(opt['desc'] as String,
                      style: GoogleFonts.poppins(
                          color: Colors.white
                              .withOpacity(0.6),
                          fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Thread Size Selector ──
  Widget _buildThreadSizeSelector() {
    return Column(
      children: [
        // 4 thread size buttons
        GridView.count(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: RecommendationService.threadSizes
              .map((size) {
            final isSelected =
                _selectedThreadSize.mm == size.mm;

            return GestureDetector(
              onTap: () => setState(
                      () => _selectedThreadSize = size),
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? AppColors.primaryGradient
                      : null,
                  color: isSelected
                      ? null
                      : AppColors.card,
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white
                        .withOpacity(0.08),
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                        color:
                        AppColors.purpleGlow,
                        blurRadius: 12)
                  ]
                      : [],
                ),
                child: Row(
                  children: [
                    // Thread thickness visual
                    Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: _getThreadVisualHeight(
                              size.mm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors
                                .textSecondary,
                            borderRadius:
                            BorderRadius.circular(
                                2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            size.label,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                          Text(
                            size.mm,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  .withOpacity(0.8)
                                  : AppColors
                                  .textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        // Description of selected
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.textMuted, size: 14),
              const SizedBox(width: 8),
              Expanded(  // ← THIS FIXES THE OVERFLOW
                child: Text(
                  '${_selectedThreadSize.label} (${_selectedThreadSize.mm}) — '
                      '${_selectedThreadSize.desc}. '
                      'Max ~${_selectedThreadSize.maxLines} lines.',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getThreadVisualHeight(String mm) {
    switch (mm) {
      case '0.11 mm':
        return 1.5;
      case '0.16 mm':
        return 2.5;
      case '0.19 mm':
        return 3.5;
      case '0.25 mm':
        return 5.0;
      default:
        return 3.0;
    }
  }

  // ── Board Size Selector ──
  Widget _buildBoardSizeSelector() {
    return Column(
      children: [
        // 5 board size chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: RecommendationService.boardSizes
                .map((board) {
              final isSelected =
                  _selectedBoardSize.cm == board.cm;

              return GestureDetector(
                onTap: () => setState(
                        () => _selectedBoardSize = board),
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 200),
                  margin:
                  const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.accentGradient
                        : null,
                    color: isSelected
                        ? null
                        : AppColors.card,
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white
                          .withOpacity(0.08),
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                          color:
                          AppColors.orangeGlow,
                          blurRadius: 12)
                    ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${board.cm} cm',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        board.label,
                        style: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                .withOpacity(0.8)
                                : AppColors.textMuted,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Selected board info
        GlowCard(
          padding: const EdgeInsets.all(14),
          glowColor: AppColors.orange,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                  AppColors.orange.withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                    Icons.carpenter_rounded,
                    color: AppColors.orange,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedBoardSize.cm} cm ${_selectedBoardSize.label} Board',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Nail spacing: ${_selectedBoardSize.nailSpacing}  •  '
                          '${_selectedBoardSize.minNails}–${_selectedBoardSize.maxNails} nails',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildThreadColorPicker() {
    return Column(
      children: [
        // Scrollable color circles
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _threadColors.length,
            itemBuilder: (_, i) {
              final item = _threadColors[i];
              final color = item['color'] as Color;
              final isSelected =
                  _selectedThreadColor == color;

              return GestureDetector(
                onTap: () => setState(
                        () => _selectedThreadColor = color),
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 200),
                  margin: const EdgeInsets.only(
                      right: 12),
                  width: isSelected ? 56 : 48,
                  height: isSelected ? 56 : 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.purple
                          : Colors.white
                          .withOpacity(0.15),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: color
                            .withOpacity(0.5),
                        blurRadius: 12,
                      )
                    ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                      color: Colors.white,
                      size: 20)
                      : null,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Selected color name
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _selectedThreadColor
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedThreadColor
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _selectedThreadColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white
                          .withOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _threadColors.firstWhere(
                      (c) => c['color'] ==
                      _selectedThreadColor,
                  orElse: () =>
                  {'name': 'Custom'},
                )['name'] as String,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildThreadModeSelector() {
    return Row(
      children: [
        // Black Thread
        Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _isRGBMode = false),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: !_isRGBMode
                    ? AppColors.primaryGradient
                    : null,
                color: _isRGBMode
                    ? AppColors.card
                    : null,
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                  color: !_isRGBMode
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.08),
                ),
                boxShadow: !_isRGBMode
                    ? [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 16)
                ]
                    : [],
              ),
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _selectedThreadColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      '${_getColorName()} Thread',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: !_isRGBMode
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                  Text('Classic style',
                      style: GoogleFonts.poppins(
                          color:
                          Colors.white.withOpacity(0.6),
                          fontSize: 10)),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // RGB Thread
        Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _isRGBMode = true),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isRGBMode
                    ? const LinearGradient(colors: [
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                ])
                    : null,
                color: _isRGBMode
                    ? null
                    : AppColors.card,
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                  color: _isRGBMode
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.08),
                ),
                boxShadow: _isRGBMode
                    ? [
                  BoxShadow(
                      color: Colors.red
                          .withOpacity(0.3),
                      blurRadius: 16)
                ]
                    : [],
              ),
              child: Column(
                children: [
                  const Text('🎨',
                      style:
                      TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text('RGB Thread',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: _isRGBMode
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                  Text('3 color channels',
                      style: GoogleFonts.poppins(
                          color:
                          Colors.white.withOpacity(0.6),
                          fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  String _getColorName() {
    final match = _threadColors.firstWhere(
          (c) => c['color'] == _selectedThreadColor,
      orElse: () => {'name': 'Custom'},
    );
    return match['name'] as String;
  }
  // ── Generate button action ──
  void _onGenerate() {
    // ── Check image selected ──
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.orange),
              const SizedBox(width: 10),
              Text('Please select an image first!',
                  style: GoogleFonts.poppins(
                      color: Colors.white)),
            ],
          ),
        ),
      );
      return;
    }

    final premium = context.read<PremiumService>();

    // ── Check if plan just expired ──
    final justExpired = premium.checkAndRefresh();
    if (justExpired) {
      _showExpiredDialog();
      return;
    }

    // ── RGB mode check ──
    if (_isRGBMode) {
      if (!premium.hasRGBAccess) {
        _showPremiumRequired(isRGB: true);
        return;
      }
    } else {
      // ── Color thread check ──
      // Black and White are free, any other color needs Color Pass
      final isColorMode =
          _selectedThreadColor != Colors.black &&
              _selectedThreadColor !=
                  const Color(0xFF000000) &&
              _selectedThreadColor != Colors.white &&
              _selectedThreadColor !=
                  const Color(0xFFFFFFFF);

      if (isColorMode && !premium.hasColorAccess) {
        _showPremiumRequired(isRGB: false);
        return;
      }
    }

    // ── All checks passed — proceed ──
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageCropScreen(
          imageFile: _selectedImage!,
          nailCount: _nailCount.round(),
          shape: _selectedShape,
          density: _threadDensity,
          artType:
          _isRGBMode ? 'RGB' : widget.artType,
          threadColor: _selectedThreadColor,
        ),
      ),
    );
  }

  // ── Show premium required paywall ──
  void _showPremiumRequired({required bool isRGB}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isRGB
                    ? const LinearGradient(colors: [
                  Colors.red,
                  Colors.blue,
                  Colors.green
                ])
                    : AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: (isRGB
                        ? Colors.blue
                        : AppColors.purple)
                        .withOpacity(0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                isRGB
                    ? Icons.grain
                    : Icons.palette_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              isRGB
                  ? '🌈 RGB Thread Art'
                  : '🎨 Color Thread Art',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isRGB
                  ? 'RGB Thread Art is a premium feature.\n'
                  'Get the RGB Pass for ₹99 (24 hours)\n'
                  'or unlock Monthly Pro for ₹199.'
                  : 'Color Thread Art is a premium feature.\n'
                  'Get the Color Pass for ₹69 (24 hours)\n'
                  'or unlock Monthly Pro for ₹199.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 20),

            // Unlock button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                // Capture service BEFORE navigation (fixes context.read error)
                final premiumService =
                context.read<PremiumService>();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                ).then((_) {
                  if (!mounted) return;
                  // Use captured reference — no context needed
                  if ((isRGB && premiumService.hasRGBAccess) ||
                      (!isRGB && premiumService.hasColorAccess)) {
                    _onGenerate();
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 16),
                decoration: BoxDecoration(
                  gradient: isRGB
                      ? const LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.blue
                    ],
                  )
                      : AppColors.primaryGradient,
                  borderRadius:
                  BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isRGB
                          ? Colors.blue
                          : AppColors.purple)
                          .withOpacity(0.4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(
                  isRGB
                      ? 'Unlock RGB Pass — ₹99'
                      : 'Unlock Color Pass — ₹69',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Free option
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Switch to black thread and proceed
                setState(() {
                  _isRGBMode = false;
                  _selectedThreadColor = Colors.black;
                });
              },
              child: Text(
                'Continue with Black Thread (Free)',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

// ── Show expired plan dialog ──
  void _showExpiredDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.orange
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.orange
                          .withOpacity(0.4)),
                ),
                child: const Icon(Icons.timer_off,
                    color: AppColors.orange, size: 28),
              ),

              const SizedBox(height: 16),

              Text(
                'Pass Expired',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your Color/RGB Pass has expired.\n'
                    'Renew to continue creating colorful thread art.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Text('Cancel',
                            textAlign:
                            TextAlign.center,
                            style: GoogleFonts.poppins(
                                color: AppColors
                                    .textSecondary,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const PremiumScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          gradient:
                          AppColors.primaryGradient,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Renew Now',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
