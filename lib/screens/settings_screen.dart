import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../services/premium_service.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import '../widgets/neon_toggle.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final premium = context.watch<PremiumService>();
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
          'Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── PREMIUM BANNER ──
            if (!premium.isPremium)
              _buildPremiumBanner(context),
            if (!premium.isPremium)
              const SizedBox(height: 24),


            // ── GENERAL ──
            _sectionHeader('General'),
            const SizedBox(height: 12),
            _buildGeneralSettings(context, settings),

            const SizedBox(height: 24),

// ── AUTO ADVANCE ──
            _sectionHeader('Auto Advance'),
            const SizedBox(height: 12),
            _buildAutoAdvanceSettings(context, settings),



            const SizedBox(height: 24),

            // ── ABOUT ──
            _sectionHeader('About'),
            const SizedBox(height: 12),
            _buildAboutSection(context, premium),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── PREMIUM BANNER ──
  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.purpleGlow, blurRadius: 20)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade to Premium',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text('Unlock all features for \$2.99',
                      style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }


  // ── GENERAL SETTINGS ──
  Widget _buildGeneralSettings(
      BuildContext context, SettingsService settings) {
    return _card(
      children: [
        _toggleRow(
          icon: Icons.vibration_rounded,
          iconColor: AppColors.purple,
          title: 'Haptic Feedback',
          subtitle: 'Vibrate on each step',
          value: settings.hapticFeedback,
          onChanged: (v) => settings.setHaptic(v),
        ),
        _divider(),
        _toggleRow(
          icon: Icons.save_outlined,
          iconColor: AppColors.cyan,
          title: 'Auto Save',
          subtitle: 'Save progress automatically',
          value: settings.autoSave,
          onChanged: (v) => settings.setAutoSave(v),
        ),
        _divider(),
        _toggleRow(
          icon: Icons.history_rounded,
          iconColor: AppColors.pink,
          title: 'Step History',
          subtitle: 'Show recent steps',
          value: settings.showStepHistory,
          onChanged: (v) => settings.setStepHistory(v),
        ),
        _divider(),
        _toggleRow(
          icon: Icons.dark_mode_rounded,
          iconColor: AppColors.blue,
          title: 'Dark Canvas',
          subtitle: 'Dark background for art',
          value: settings.darkCanvas,
          onChanged: (v) => settings.setDarkCanvas(v),
        ),
      ],
    );
  }
// ── AUTO ADVANCE SETTINGS ──
  Widget _buildAutoAdvanceSettings(
      BuildContext context, SettingsService settings) {
    return _card(
      children: [

        // Toggle
        _toggleRow(
          icon: Icons.play_circle_outline_rounded,
          iconColor: AppColors.cyan,
          title: 'Auto Advance',
          subtitle: 'Automatically move to next step',
          value: settings.autoAdvance,
          onChanged: (val) async {
            await settings.setAutoAdvance(val);
            // Auto-enable voice when turned on
            if (val) {
              await settings.setVoiceEnabled(true);
            }
          },
        ),

        // Slider — only visible when ON
        if (settings.autoAdvance) ...[
          _divider(),
          _paddedRow(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.blue
                            .withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.timer_outlined,
                          color: AppColors.blue,
                          size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Step Delay',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.primaryGradient
                              .createShader(b),
                      child: Text(
                        '${settings.autoDelay}s',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                    activeTrackColor: AppColors.purple,
                    thumbColor: AppColors.pink,
                    inactiveTrackColor:
                    Color(0x30FFFFFF),
                  ),
                  child: Slider(
                    value: settings.autoDelay
                        .toDouble(),
                    min: 4,
                    max: 20,
                    divisions: 16,
                    // Save only when released = NO LAG
                    onChangeEnd: (val) async {
                      await settings
                          .setAutoDelay(val.round());
                    },
                    onChanged: (val) {
                      // UI updates instantly during drag
                      settings
                          .setAutoDelay(val.round());
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text('4s (faster)',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 10)),
                    Text('20s (slower)',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }


  // ── ABOUT ──
  Widget _buildAboutSection(
      BuildContext context, PremiumService premium) {
    return _card(
      children: [
        _tapRow(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.purple,
          title: 'Version',
          trailing: Text('1.0.0',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
          onTap: () {},
        ),
        _divider(),
        _tapRow(
          icon: Icons.star_outline_rounded,
          iconColor: AppColors.orange,
          title: 'Rate ThreadCRAFT',
          onTap: () => _showSnack(context, '⭐ Thank you!'),
        ),
        _divider(),
        _tapRow(
          icon: Icons.bug_report_outlined,
          iconColor: AppColors.pink,
          title: 'Report a Bug',
          onTap: () => _showSnack(context, '🙏 Thank you!'),
        ),
        _divider(),
        _tapRow(
          icon: Icons.developer_mode_rounded,
          iconColor: AppColors.textMuted,
          title: 'Debug: Toggle Premium',
          subtitle: premium.isPremium
              ? '${premium.planDisplayName} — ${premium.timeRemainingString}'
              : 'Currently: Free',
          onTap: () async {
            if (premium.isPremium) {
              await premium.resetPremium();
              _showSnack(context, 'Reset to Free (debug)');
            } else {
              await premium.debugUnlock();
              _showSnack(context, 'Monthly Pro unlocked 🔓');
            }
          },
        ),
      ],
    );
  }

  // ── REUSABLE WIDGETS ──

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _toggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return _paddedRow(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 14)),
                if (subtitle != null)
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                          fontSize: 11)),
              ],
            ),
          ),
          NeonToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _tapRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _paddedRow(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 11)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _paddedRow({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: child,
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: Colors.white.withOpacity(0.05),
    indent: 64,
  );

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      content: Text(msg,
          style: GoogleFonts.poppins(color: Colors.white)),
    ));
  }
}