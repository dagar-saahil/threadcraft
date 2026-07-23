import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../services/voice_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/neon_toggle.dart';

class VoiceGuideScreen extends StatefulWidget {
  const VoiceGuideScreen({super.key});

  @override
  State<VoiceGuideScreen> createState() => _VoiceGuideScreenState();
}

class _VoiceGuideScreenState extends State<VoiceGuideScreen>
    with TickerProviderStateMixin {

  // Mic pulse animation
  late AnimationController _micPulseController;

  // Waveform animation
  late AnimationController _waveController;

  // Selected speed
  double _selectedSpeed = 1.0;
  final List<double> _speeds = [0.5, 1.0, 1.5, 2.0];

  // Testing voice
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceService>();

    return Scaffold(
      backgroundColor: AppColors.background,

      // ── TOP BAR ──
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
          'Voice Guide',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.graphic_eq,
                color: Colors.white, size: 20),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 10),

            // ── BIG MIC CIRCLE ──
            _buildMicCircle(voice),

            const SizedBox(height: 40),

            // ── VOICE TOGGLE ──
            _buildVoiceToggle(voice),

            const SizedBox(height: 20),

            // ── SPEED SELECTOR ──
            _buildSpeedSelector(voice),

            const SizedBox(height: 20),

            // ── VOICE GENDER SELECTOR ──
            _buildGenderSelector(voice),

            const SizedBox(height: 24),

            // ── WAVEFORM ──
            _buildWaveform(voice),

            const SizedBox(height: 32),

            // ── TEST VOICE BUTTON ──
            GradientButton(
              text: _isTesting ? '🔊  Speaking...' : '▶  Test Voice',
              gradient: AppColors.primaryGradient,
              isLoading: _isTesting,
              onTap: () => _testVoice(voice),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── BIG MIC CIRCLE ──
  Widget _buildMicCircle(VoiceService voice) {
    return AnimatedBuilder(
      animation: _micPulseController,
      builder: (_, __) {
        final pulse = _micPulseController.value;
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              if (voice.isEnabled)
                Container(
                  width: 190 + (pulse * 10),
                  height: 190 + (pulse * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.purple.withOpacity(0.2 - pulse * 0.1),
                      width: 2,
                    ),
                  ),
                ),

              // Middle ring
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppColors.purple,
                      AppColors.pink,
                      AppColors.orange,
                      AppColors.purple,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(
                          0.3 + pulse * 0.2),
                      blurRadius: 30 + pulse * 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Inner dark circle
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Color(0xFF12121C),
                  shape: BoxShape.circle,
                ),
              ),

              // Mic icon
              Icon(
                voice.isEnabled
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                color: Colors.white,
                size: 50,
              ).animate(key: ValueKey(voice.isEnabled))
                  .scale(begin: const Offset(0.8, 0.8), duration: 200.ms),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 600.ms).scale(
      begin: const Offset(0.7, 0.7),
      curve: Curves.elasticOut,
      duration: 800.ms,
    );
  }

  // ── VOICE TOGGLE ──
  Widget _buildVoiceToggle(VoiceService voice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded,
                  color: AppColors.purple, size: 20),
              const SizedBox(width: 10),
              Text(
                'Voice Guide',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          NeonToggle(
            value: voice.isEnabled,
            onChanged: (_) => voice.toggleVoice(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── SPEED SELECTOR ──
  Widget _buildSpeedSelector(VoiceService voice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speed',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _speeds.map((speed) {
              final isSelected = _selectedSpeed == speed;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _selectedSpeed = speed);
                    await voice.setSpeed(speed);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppColors.primaryGradient
                          : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [BoxShadow(
                          color: AppColors.purpleGlow,
                          blurRadius: 10)]
                          : [],
                    ),
                    child: Text(
                      '${speed}x',
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
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ── GENDER SELECTOR ──
  Widget _buildGenderSelector(VoiceService voice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Female', 'Male'].map((gender) {
              final isSelected = voice.voice == gender;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await voice.setVoice(gender);
                    // Immediately test the new voice
                    await voice.testSpeak();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppColors.primaryGradient
                          : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [BoxShadow(
                          color: AppColors.purpleGlow,
                          blurRadius: 10)]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gender == 'Female'
                              ? Icons.face_3_rounded
                              : Icons.face_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          gender,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── WAVEFORM ──
  Widget _buildWaveform(VoiceService voice) {
    return SizedBox(
      height: 50,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(28, (i) {
              final phase = (i / 28) * 2 * pi;
              final wave = voice.isEnabled
                  ? sin(_waveController.value * 2 * pi + phase)
                  : 0.0;
              final height = voice.isEnabled
                  ? 6 + (wave * 18).abs()
                  : 4.0;

              final colors = [
                AppColors.purple,
                AppColors.pink,
                AppColors.orange,
                AppColors.cyan,
              ];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: voice.isEnabled
                      ? colors[i % colors.length]
                      .withOpacity(0.6 + wave.abs() * 0.4)
                      : AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ── TEST VOICE ──
  Future<void> _testVoice(VoiceService voice) async {
    if (_isTesting) return;
    setState(() => _isTesting = true);

    // Test always speaks regardless of toggle
    await voice.testSpeak();
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) setState(() => _isTesting = false);
  }
}