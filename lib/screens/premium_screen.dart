import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../services/premium_service.dart';
import '../widgets/gradient_button.dart';
import '../services/premium_service.dart';



class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() =>
      _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isLoading = false;
  int _selectedPlan = 2; // default Monthly

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ── Pricing plans ──
  final List<Map<String, dynamic>> _plans = [
    {
      'id': 0,
      'emoji': '🎨',
      'title': 'Color Pass',
      'subtitle': 'Valid 24 Hours',
      'oldPrice': '₹149',
      'price': '₹69',
      'usd': '\$0.99',
      'badge': null,
      'discount': 'Save 54%',
      'gradient': [
        const Color(0xFF7C3AED),
        const Color(0xFFEC4899)
      ],
      'features': [
        'Black & Multi-Color Thread Art',
        'PDF Nail Template Export',
        'Voice Guided Work Mode',
        'Save Projects',
        'Unlimited Generation (24 hrs)',
      ],
    },
    {
      'id': 1,
      'emoji': '🌈',
      'title': 'RGB Premium',
      'subtitle': 'Valid 24 Hours',
      'oldPrice': '₹249',
      'price': '₹99',
      'usd': '\$1.49',
      'badge': null,
      'discount': 'Save 60%',
      'gradient': [
        Colors.red,
        Colors.green,
        Colors.blue
      ],
      'features': [
        'Full RGB Thread Art System',
        'Advanced Multi-Phase RGB',
        'Premium Portrait Generation',
        'RGB Voice Guided Work Mode',
        'Everything in Color Pass',
        'Unlimited RGB Generation (24 hrs)',
      ],
    },
    {
      'id': 2,
      'emoji': '⭐',
      'title': 'Monthly Pro',
      'subtitle': 'Per Month',
      'oldPrice': '₹499',
      'price': '₹199',
      'usd': '\$2.49',
      'badge': '🔥 MOST POPULAR',
      'discount': 'Save 60%',
      'gradient': [
        const Color(0xFFF97316),
        const Color(0xFFEC4899)
      ],
      'features': [
        'Unlimited Standard + RGB Generation',
        'Unlimited PDF Nail Template Export',
        'Unlimited Saved Projects',
        'Premium Work Modes',
        'All Future Premium Features',
      ],
    },
    {
      'id': 3,
      'emoji': '👑',
      'title': 'Yearly Pro',
      'subtitle': 'Per Year',
      'oldPrice': '₹2,999',
      'price': '₹999',
      'usd': '\$11.99',
      'badge': null,
      'discount': 'Save 67%',
      'gradient': [
        const Color(0xFF06B6D4),
        const Color(0xFF7C3AED)
      ],
      'features': [
        'Everything in Monthly Pro',
        'Priority Generation Queue',
        'Advanced Portrait Presets',
        '12 Months Full Access',
      ],
    },
    {
      'id': 4,
      'emoji': '💎',
      'title': 'Lifetime',
      'subtitle': 'One-Time Payment',
      'oldPrice': '₹5,999',
      'price': '₹2,499',
      'usd': '\$29.99',
      'badge': '💎 BEST VALUE',
      'discount': 'Save 58%',
      'gradient': [
        const Color(0xFFFFD700),
        const Color(0xFFF97316)
      ],
      'features': [
        'Everything — Forever',
        'All Future Features Included',
        'Lifetime Priority Access',
        'ThreadCRAFT Pro Badge',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBgGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(),
                        const SizedBox(height: 20),
                        // Plan cards
                        ...List.generate(
                            _plans.length, (i) {
                          return _buildPlanCard(
                              _plans[i], i);
                        }),
                        const SizedBox(height: 20),
                        // Unlock button
                        if (!premium.isPremium)
                          GradientButton(
                            text: _isLoading
                                ? 'Processing...'
                                : '✦  Unlock Selected Plan',
                            gradient: LinearGradient(
                              colors: (_plans[_selectedPlan]
                              ['gradient']
                              as List)
                                  .cast<Color>(),
                            ),
                            isLoading: _isLoading,
                            onTap: () =>
                                _handlePurchase(context),
                          ).animate().fadeIn(
                              delay: 300.ms)
                        else
                          _buildAlreadyPremium(),
                        const SizedBox(height: 12),
                        _buildFooter(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgGlow() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) => Stack(children: [
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple.withOpacity(
                  0.05 + _glowController.value * 0.03),
            ),
          ),
        ),
        Positioned(
          top: 100,
          right: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pink.withOpacity(
                  0.04 + _glowController.value * 0.03),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          Text('ThreadCRAFT Pro',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowController,
          builder: (_, __) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withOpacity(
                      0.3 +
                          _glowController.value * 0.2),
                  blurRadius: 28,
                  spreadRadius: 4,
                )
              ],
            ),
            child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 40),
          ),
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (b) =>
              AppColors.accentGradient.createShader(b),
          child: Text('Unlock ThreadCRAFT',
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 6),
        Text(
          'Professional Thread Art — Real Results',
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildPlanCard(
      Map<String, dynamic> plan, int index) {
    final isSelected = _selectedPlan == index;
    final gradient =
    (plan['gradient'] as List).cast<Color>();
    final badge = plan['badge'] as String?;

    return GestureDetector(
      onTap: () =>
          setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: gradient
                .map((c) => c.withOpacity(0.2))
                .toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? gradient.first
                : Colors.white.withOpacity(0.07),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color:
              gradient.first.withOpacity(0.3),
              blurRadius: 16,
            )
          ]
              : [],
        ),
        child: Column(
          children: [
            // ── Card header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 14, 16, 10),
              child: Row(
                children: [
                  // Emoji + Title
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(plan['emoji'],
                              style: const TextStyle(
                                  fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(plan['title'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight:
                                FontWeight.bold,
                              )),
                        ],
                      ),
                      Text(plan['subtitle'],
                          style: GoogleFonts.poppins(
                              color:
                              AppColors.textSecondary,
                              fontSize: 11)),
                    ],
                  ),

                  const Spacer(),

                  // Price
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Text(plan['oldPrice'],
                          style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            decoration: TextDecoration
                                .lineThrough,
                          )),
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (b) =>
                                LinearGradient(
                                    colors: gradient)
                                    .createShader(b),
                            child: Text(plan['price'],
                                style:
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight:
                                  FontWeight.bold,
                                )),
                          ),
                        ],
                      ),
                      Text(plan['usd'],
                          style: GoogleFonts.poppins(
                              color:
                              AppColors.textSecondary,
                              fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            // Badge row
            if (badge != null || plan['discount'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 10),
                child: Row(
                  children: [
                    if (badge != null)
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: gradient),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Text(badge,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight:
                                FontWeight.bold)),
                      ),
                    if (badge != null)
                      const SizedBox(width: 8),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(8),
                        border: Border.all(
                            color:
                            Colors.green.withOpacity(
                                0.3)),
                      ),
                      child: Text(
                          plan['discount'],
                          style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight:
                              FontWeight.w600)),
                    ),
                    const Spacer(),
                    // Selected indicator
                    AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                            ? LinearGradient(
                            colors: gradient)
                            : null,
                        border: isSelected
                            ? null
                            : Border.all(
                            color: AppColors
                                .textMuted),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                          color: Colors.white,
                          size: 12)
                          : null,
                    ),
                  ],
                ),
              ),

            // Features list (only when selected)
            if (isSelected)
              Container(
                margin: const EdgeInsets.fromLTRB(
                    12, 0, 12, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Column(
                  children: (plan['features'] as List<String>)
                      .map(
                        (f) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .check_circle_outline,
                            color: gradient.first,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f,
                                style:
                                GoogleFonts.poppins(
                                  color:
                                  Colors.white
                                      .withOpacity(
                                      0.85),
                                  fontSize: 11,
                                )),
                          ),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                ),
              ).animate().fadeIn(duration: 200.ms),
          ],
        ),
      ).animate().fadeIn(
          delay: Duration(
              milliseconds: 100 + index * 60)),
    );
  }

  Widget _buildAlreadyPremium() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium,
              color: Colors.white),
          const SizedBox(width: 10),
          Text('Premium Active! 🎉',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final premium = context.read<PremiumService>();
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(
              backgroundColor: AppColors.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12)),
              content: Text(
                'No previous purchase found.',
                style: GoogleFonts.poppins(
                    color: Colors.white),
              ),
            ));
          },
          child: Text('Restore Purchase',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  decoration:
                  TextDecoration.underline)),
        ),
        const SizedBox(height: 6),
        Text('Terms  ·  Privacy  ·  Refund Policy',
            style: GoogleFonts.poppins(
                color: AppColors.textMuted,
                fontSize: 10)),
      ],
    );
  }

  Future<void> _handlePurchase(
      BuildContext context) async {
    setState(() => _isLoading = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Map selected plan index to PlanType
      final planTypes = [
        PlanType.colorPass,  // index 0 — ₹69
        PlanType.rgbPass,    // index 1 — ₹99
        PlanType.monthly,    // index 2 — ₹199
        PlanType.yearly,     // index 3 — ₹999
        PlanType.lifetime,   // index 4 — ₹2499
      ];

      final selectedPlanType =
      planTypes[_selectedPlan.clamp(
          0, planTypes.length - 1)];

      await context
          .read<PremiumService>()
          .unlockPlan(selectedPlanType);

      setState(() => _isLoading = false);
      _showSuccess(context);
    }
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.accentGradient,
                ),
                child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 36),
              ),
              const SizedBox(height: 16),
              Text('Welcome to Pro! 🎉',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your plan is now active.\nEnjoy ThreadCRAFT!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 13),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Start Creating!',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}