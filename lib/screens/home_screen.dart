import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../services/premium_service.dart';
import '../services/project_service.dart';
import '../services/voice_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glow_card.dart';
import '../widgets/neon_toggle.dart';
import 'dart:math';
import 'new_project_screen.dart';
import 'my_projects_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'voice_guide_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── CONTENT AREA (switches per tab) ──
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: const [
                  _HomeTab(),
                  _CreateTab(),
                  _GuideTab(),
                  _ProfileTab(),
                ],
              ),
            ),

            // ── BOTTOM NAV ──
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM NAV ──
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.add_circle_outline, 'label': 'Create'},
      {'icon': Icons.menu_book_outlined, 'label': 'Guide'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10101A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isSelected = i == _currentTab;
          return GestureDetector(
            onTap: () => setState(() => _currentTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purple.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i]['icon'] as IconData,
                    color: isSelected
                        ? AppColors.purple
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i]['label'] as String,
                    style: GoogleFonts.poppins(
                      color: isSelected
                          ? AppColors.purple
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════
// TAB 1 — HOME
// ═══════════════════════════════════════
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── TOP BAR ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pro badge
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PremiumScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: premium.isPremium
                        ? AppColors.accentGradient
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.purpleGlow,
                          blurRadius: 12)
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        premium.isPremium
                            ? Icons.workspace_premium
                            : Icons.star,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        premium.isPremium
                            ? premium.isTimedPlan
                            ? premium.timeRemainingString
                            : premium.planDisplayName
                            : 'Free',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Settings
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── TITLE ──
          ShaderMask(
            shaderCallback: (b) =>
                AppColors.primaryGradient.createShader(b),
            child: Text(
              'ThreadCRAFT',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ).animate().fadeIn(duration: 700.ms),

          const SizedBox(height: 6),

          Text(
            'Turn Images Into Thread Masterpieces',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 30),

          // ── NEON SWIRL ──
          _buildNeonSwirl(),

          const SizedBox(height: 36),

          // ── NEW PROJECT BUTTON ──
          GradientButton(
            text: 'New Project',
            icon: Icons.add_circle_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NewProjectScreen()),
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 16),

          // ── MY PROJECTS + GALLERY ──
          GlowCard(
            padding: const EdgeInsets.symmetric(
                vertical: 18, horizontal: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MyProjectsScreen()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_rounded,
                      color: AppColors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Projects',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Resume or view saved work',
                      style: GoogleFonts.poppins(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textMuted, size: 14),
              ],
            ),
          ).animate().fadeIn(delay: 700.ms),

          const SizedBox(height: 20),

          // ── FEATURE ROW ──
          GlowCard(
            padding: const EdgeInsets.symmetric(
                vertical: 20, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icons.image,
                Icons.circle_outlined,
                Icons.mic,
                Icons.swap_horiz,
              ].asMap().entries.map((e) {
                final labels = [
                  'Image to\nThread Art',
                  'Smart Nail\nPlacement',
                  'Voice\nGuidance',
                  'Step by Step\nNavigation'
                ];
                return Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.purpleGlow,
                              blurRadius: 10)
                        ],
                      ),
                      child: Icon(e.value,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[e.key],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 900.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNeonSwirl() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _spinController,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    AppColors.purple,
                    AppColors.pink,
                    AppColors.orange,
                    AppColors.blue,
                    AppColors.cyan,
                    AppColors.purple,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 40,
                      spreadRadius: 5),
                ],
              ),
            ),
          ),
          Container(
            width: 190,
            height: 190,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
          CustomPaint(
            size: const Size(160, 160),
            painter: _SwirlPainter(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(
      begin: const Offset(0.8, 0.8),
      duration: 800.ms,
      curve: Curves.elasticOut,
    );
  }
}

// ═══════════════════════════════════════
// TAB 2 — CREATE
// ═══════════════════════════════════════
class _CreateTab extends StatelessWidget {
  const _CreateTab();

  @override
  Widget build(BuildContext context) {
    final artStyles = [
      {
        'title': 'Thread Art',
        'desc': 'Classic nail & string portrait',
        'icon': Icons.auto_awesome,
        'gradient': AppColors.primaryGradient,
        'tag': 'Most Popular',
        'free': true,
        'comingSoon': false,
      },
      {
        'title': 'Line Art',
        'desc': 'Edge detection drawing style',
        'icon': Icons.show_chart,
        'gradient': AppColors.accentGradient,
        'tag': 'Coming Soon',
        'free': false,
        'comingSoon': true,
      },
      {
        'title': 'Dot Art',
        'desc': 'Connect-the-dots recreation',
        'icon': Icons.grain,
        'gradient': AppColors.coolGradient,
        'tag': 'Coming Soon',
        'free': false,
        'comingSoon': true,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Text(
            'Create New',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          ...artStyles.asMap().entries.map((entry) {
            final i = entry.key;
            final style = entry.value;
            final isFree = style['free'] as bool;
            final isComingSoon = style['comingSoon'] as bool;
            final premium =
                context.watch<PremiumService>().isPremium;
            final canUse = isFree || premium;

            return GestureDetector(
              onTap: isComingSoon ? null : () {
                if (!canUse) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PremiumScreen()),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewProjectScreen(
                      artType: style['title'] as String,
                    ),
                  ),
                );
              },
              child: Opacity(
                opacity: isComingSoon ? 0.7 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: (style['gradient'] as LinearGradient),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                    boxShadow: !isComingSoon ? [
                      BoxShadow(
                        color: AppColors.purpleGlow,
                        blurRadius: 20,
                      )
                    ] : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        child: Icon(
                          style['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  style['title'] as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(0.2),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    style['tag'] as String,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              style['desc'] as String,
                              style: GoogleFonts.poppins(
                                color: Colors.white
                                    .withOpacity(0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isComingSoon ? Icons.hourglass_empty : (canUse
                            ? Icons.arrow_forward_ios
                            : Icons.lock_outline),
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(
                delay: Duration(milliseconds: 100 + i * 100))
                .slideX(begin: 0.2);
          }),

          const SizedBox(height: 8),

          // Quick tips card
          GlowCard(
            padding: const EdgeInsets.all(16),
            glowColor: AppColors.cyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.cyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Tips',
                      style: GoogleFonts.poppins(
                        color: AppColors.cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...[
                  '📸 Use high contrast portrait photos',
                  '🔩 More nails = more detail',
                  '🧵 Start with Medium density',
                  '💡 Dark board works best for beginners',
                ].map((tip) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: 6),
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                )),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// TAB 3 — GUIDE
// ═══════════════════════════════════════
class _GuideTab extends StatelessWidget {
  const _GuideTab();

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'num': '01',
        'title': 'Choose Your Image',
        'desc':
        'Pick a high contrast photo. Portraits and faces work best. Black & white images give the clearest results.',
        'icon': Icons.image_outlined,
        'color': AppColors.purple,
      },
      {
        'num': '02',
        'title': 'Set Up Your Frame',
        'desc':
        'Hammer nails evenly around your frame. Use the nail count from the app. More nails = more detail.',
        'icon': Icons.circle_outlined,
        'color': AppColors.pink,
      },
      {
        'num': '03',
        'title': 'Generate the Pattern',
        'desc':
        'The app calculates which nails to connect. This creates the nail sequence you will follow.',
        'icon': Icons.auto_awesome,
        'color': AppColors.orange,
      },
      {
        'num': '04',
        'title': 'Follow the Steps',
        'desc':
        'The app shows you: go from nail 56 to nail 89. Wind your thread around each nail and pull tight.',
        'icon': Icons.swap_horiz,
        'color': AppColors.cyan,
      },
      {
        'num': '05',
        'title': 'Use Voice Guide',
        'desc':
        'Enable voice guide so the app reads each step out loud. You can focus on the art without looking at the screen.',
        'icon': Icons.mic_rounded,
        'color': AppColors.blue,
      },
      {
        'num': '06',
        'title': 'Watch It Come Alive!',
        'desc':
        'As you add more threads, the image appears. The overlapping threads create light and shadow.',
        'icon': Icons.visibility_outlined,
        'color': AppColors.purple,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Text(
            'How It Works',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(),

          Text(
            'Step by step thread art guide',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // Voice Guide quick access card
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const VoiceGuideScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 20)
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Guide Settings',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Configure speed, gender & auto advance',
                          style: GoogleFonts.poppins(
                            color:
                            Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Step by step guide
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return _GuideStepCard(step: step, index: i);
          }),

          const SizedBox(height: 16),

          // Materials needed card
          GlowCard(
            glowColor: AppColors.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: AppColors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'What You Need',
                      style: GoogleFonts.poppins(
                        color: AppColors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...[
                  '🪵 Wooden board (any size)',
                  '🔩 Small nails or pins',
                  '🧵 Black thread (for beginners)',
                  '🔨 Hammer',
                  '📏 Ruler or compass',
                  '📱 ThreadCRAFT app!',
                ].map((item) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: 8),
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  final Map<String, dynamic> step;
  final int index;

  const _GuideStepCard({required this.step, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (step['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (step['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                step['num'] as String,
                style: GoogleFonts.poppins(
                  color: step['color'] as Color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['desc'] as String,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + index * 80))
        .slideX(begin: 0.1);
  }
}

// ═══════════════════════════════════════
// TAB 4 — PROFILE
// ═══════════════════════════════════════
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();
    final projects = context.watch<ProjectService>();

    final total = projects.totalProjects;
    final completed = projects.projects
        .where((p) => p.isCompleted)
        .length;
    final inProgress = total - completed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // ── AVATAR + NAME ──
          _buildAvatar(premium),

          const SizedBox(height: 28),

          // ── STATS ROW ──
          _buildStatsRow(total, completed, inProgress),

          const SizedBox(height: 24),

          // ── PREMIUM STATUS ──
          _buildPremiumCard(context, premium),

          const SizedBox(height: 16),

          // ── QUICK LINKS ──
          _buildQuickLinks(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvatar(PremiumService premium) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 20)
                ],
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 46),
            ),
            if (premium.isPremium)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.background, width: 2),
                  ),
                  child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 14),
                ),
              ),
          ],
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),

        const SizedBox(height: 14),

        Text(
          'Thread Artist',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 200.ms),

        Text(
          premium.isPremium
              ? '✨ Premium Member'
              : '🌱 Free Member',
          style: GoogleFonts.poppins(
            color: premium.isPremium
                ? AppColors.orange
                : AppColors.textSecondary,
            fontSize: 13,
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildStatsRow(int total, int completed, int inProgress) {
    return Row(
      children: [
        _statCard('Total\nProjects', '$total',
            AppColors.purple),
        const SizedBox(width: 12),
        _statCard('Completed', '$completed',
            AppColors.pink),
        const SizedBox(width: 12),
        _statCard('In\nProgress', '$inProgress',
            AppColors.orange),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12)
          ],
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ).createShader(b),
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(
      BuildContext context, PremiumService premium) {
    if (premium.isPremium) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.orangeGlow, blurRadius: 20)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'Premium Member — All Unlocked! 🎉',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 500.ms);
    }

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
            BoxShadow(
                color: AppColors.purpleGlow, blurRadius: 20)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Unlock all features for \$2.99',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      {
        'icon': Icons.folder_outlined,
        'label': 'My Projects',
        'color': AppColors.purple,
        'screen': const MyProjectsScreen(),
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'color': AppColors.cyan,
        'screen': const SettingsScreen(),
      },
      {
        'icon': Icons.mic_rounded,
        'label': 'Voice Guide',
        'color': AppColors.pink,
        'screen': const VoiceGuideScreen(),
      },
    ];

    return Column(
      children: links.asMap().entries.map((entry) {
        final i = entry.key;
        final link = entry.value;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                link['screen'] as Widget),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (link['color'] as Color)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    link['icon'] as IconData,
                    color: link['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  link['label'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textMuted, size: 14),
              ],
            ),
          )
              .animate()
              .fadeIn(
              delay: Duration(
                  milliseconds: 600 + i * 80)),
        );
      }).toList(),
    );
  }
}

// ── Simple swirl painter for home animation ──
class _SwirlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final colors = [
      AppColors.purple,
      AppColors.pink,
      AppColors.orange,
      AppColors.cyan,
    ];
    final nails = List.generate(48, (i) {
      final angle = (2 * pi * i / 48) - (pi / 2);
      return Offset(
        center.dx + radius * 0.92 * cos(angle),
        center.dy + radius * 0.92 * sin(angle),
      );
    });
    final pairs = [
      [0, 24], [3, 27], [6, 30], [9, 33],
      [12, 36], [15, 39], [18, 42], [21, 45],
      [2, 26], [5, 29], [8, 32], [11, 35],
    ];
    for (int i = 0; i < pairs.length; i++) {
      canvas.drawLine(
        nails[pairs[i][0]],
        nails[pairs[i][1]],
        Paint()
          ..color = colors[i % colors.length].withOpacity(0.5)
          ..strokeWidth = 0.9,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}