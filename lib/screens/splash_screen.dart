import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Navigate to home after 3 seconds
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Neon swirl logo
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating outer ring glow
                  RotationTransition(
                    turns: _rotateController,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppColors.purple,
                            AppColors.pink,
                            AppColors.orange,
                            AppColors.blue,
                            AppColors.purple,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purpleGlow,
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms),

                  // Inner dark circle
                  Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Thread icon
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 50,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App name
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                'ThreadCRAFT',
                style: GoogleFonts.poppins(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 700.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 10),

            Text(
              'Turn Images Into Thread Masterpieces',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),

            const SizedBox(height: 60),

            // Loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.purple, AppColors.pink],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purpleGlow,
                        blurRadius: 8,
                      )
                    ],
                  ),
                )
                    .animate(delay: Duration(milliseconds: 1000 + i * 150))
                    .fadeIn(duration: 400.ms)
                    .then()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                  begin: 1,
                  end: 1.5,
                  duration: 600.ms,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}