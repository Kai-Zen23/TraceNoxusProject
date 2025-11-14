import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'welcome.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Slide up animation - card moves from bottom to center
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.2), // Start completely below screen
      end: Offset.zero, // End at normal position
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Scale animation for smooth expansion
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation
    _controller.forward().then((_) {
      // After animation completes, navigate to welcome screen with instant transition
      // Since both screens are identical, instant transition prevents blinking
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const WelcomeScreen(),
              transitionDuration: Duration.zero, // Instant - no transition
              reverseTransitionDuration: Duration.zero,
              opaque: true,
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _SplashSpec.fromWidth(MediaQuery.of(context).size.width);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/Image/BackGroundIm(2).png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black87),
            ),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Content Layer
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top section with logo
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: spec.topSpacing),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Image.asset(
                          'assets/Image/TraceNoxus LOGO.png',
                          height: spec.logoHeight,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: spec.logoFallbackHeight,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              border: Border.all(
                                color: const Color(0xFF88AEC9),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: const Color(0xFF88AEC9),
                                size: spec.logoIconSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spec.brandSpacing),
                      Image.asset(
                        'assets/Image/VG VOUCHER DRAFT.png',
                        height: spec.voucherHeight,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'Ascend the trail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: spec.voucherFallbackFontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: spec.heroSpacing),
                    ],
                  ),
                  // Animated card section - moves up from bottom
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            spec.cardOuterPadding,
                            0,
                            spec.cardOuterPadding,
                            spec.cardBottomPadding,
                          ),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: spec.cardMaxWidth),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: spec.cardVerticalPadding,
                                horizontal: spec.cardHorizontalPadding,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color.fromARGB(255, 149, 186, 216),
                                    Color(0xFF7CAED7),
                                  ],
                                  stops: [0.0, 0.55, 1.0],
                                ),
                                image: DecorationImage(
                                  image: const AssetImage(
                                      'assets/Image/Girl.png'),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                  colorFilter: ColorFilter.mode(
                                    const Color.fromARGB(255, 110, 131, 184)
                                        .withOpacity(0.5),
                                    BlendMode.srcATop,
                                  ),
                                ),
                                borderRadius: BorderRadius.only(
                                  topRight:
                                      Radius.circular(spec.cardRightRadius),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Welcome to Trace Noxus',
                                    style: TextStyle(
                                      color: const Color(0xFF233A66),
                                      fontWeight: FontWeight.w800,
                                      fontSize: spec.headingFontSize,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: spec.bodySpacing),
                                  const Text(
                                    'Ascend the trail, unlock rewards, and explore the community.',
                                    style: TextStyle(
                                      color: Color(0xFF233A66),
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: spec.sectionGap),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            spec.buttonRadius),
                                      ),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6DA7CE),
                                            Color(0xFF375468),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            spec.buttonRadius),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.symmetric(
                                          vertical: spec.buttonVerticalPadding,
                                        ),
                                        child: const Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: spec.bodySpacing),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF233A66),
                                      side: const BorderSide(
                                          color: Color(0xFF233A66), width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            spec.buttonRadius),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: spec.buttonVerticalPadding,
                                      ),
                                    ),
                                    child: const Text(
                                      'CREATE ACCOUNT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SplashSpec {
  final double topSpacing;
  final double logoHeight;
  final double logoFallbackHeight;
  final double logoIconSize;
  final double brandSpacing;
  final double heroSpacing;
  final double voucherHeight;
  final double voucherFallbackFontSize;
  final double cardOuterPadding;
  final double cardMaxWidth;
  final double cardVerticalPadding;
  final double cardHorizontalPadding;
  final double cardRightRadius;
  final double cardBottomPadding;
  final double bodySpacing;
  final double sectionGap;
  final double headingFontSize;
  final double buttonRadius;
  final double buttonVerticalPadding;

  const _SplashSpec({
    required this.topSpacing,
    required this.logoHeight,
    required this.logoFallbackHeight,
    required this.logoIconSize,
    required this.brandSpacing,
    required this.heroSpacing,
    required this.voucherHeight,
    required this.voucherFallbackFontSize,
    required this.cardOuterPadding,
    required this.cardMaxWidth,
    required this.cardVerticalPadding,
    required this.cardHorizontalPadding,
    required this.cardRightRadius,
    required this.cardBottomPadding,
    required this.bodySpacing,
    required this.sectionGap,
    required this.headingFontSize,
    required this.buttonRadius,
    required this.buttonVerticalPadding,
  });

  factory _SplashSpec.fromWidth(double width) {
    final isTablet = width >= 768;
    final isDesktop = width >= 1024;

    double clamp(double value, double min, double max) =>
        math.min(math.max(value, min), max);

    final topSpacing = clamp(width * 0.18, 160, 300);
    final logoHeight = clamp(width * 0.25, 170, 300);
    final logoFallbackHeight = clamp(logoHeight * 0.72, 90, 150);
    final logoIconSize = clamp(logoHeight * 0.22, 28, 44);
    final brandSpacing = clamp(width * 0.03, 10, 20);
    final heroSpacing = clamp(width * 0.08, 48, 80);
    final voucherHeight = clamp(width * 0.22, 100, 180);
    final voucherFallbackFontSize = clamp(voucherHeight * 0.16, 18, 26);

    final cardOuterPadding = isDesktop ? 120.0 : isTablet ? 48.0 : 0.0;
    final cardMaxWidth = isDesktop
        ? clamp(width * 0.5, 520, 720)
        : isTablet
            ? clamp(width * 0.7, 420, 540)
            : clamp(width * 0.92, 320, 420);
    final cardVerticalPadding = clamp(width * 0.08, 24, 40);
    final cardHorizontalPadding = isTablet ? 32.0 : 24.0;
    final cardRightRadius = clamp(width * 0.2, 72, 130);
    final cardBottomPadding = isDesktop ? 80.0 : 40.0;

    final bodySpacing = clamp(width * 0.04, 16, 24);
    final sectionGap = clamp(width * 0.035, 14, 24);
    final headingFontSize = clamp(width * 0.07, 24, 30);
    final buttonRadius = 32.0;
    final buttonVerticalPadding = clamp(width * 0.04, 14, 18);

    return _SplashSpec(
      topSpacing: topSpacing,
      logoHeight: logoHeight,
      logoFallbackHeight: logoFallbackHeight,
      logoIconSize: logoIconSize,
      brandSpacing: brandSpacing,
      heroSpacing: heroSpacing,
      voucherHeight: voucherHeight,
      voucherFallbackFontSize: voucherFallbackFontSize,
      cardOuterPadding: cardOuterPadding,
      cardMaxWidth: cardMaxWidth,
      cardVerticalPadding: cardVerticalPadding,
      cardHorizontalPadding: cardHorizontalPadding,
      cardRightRadius: cardRightRadius,
      cardBottomPadding: cardBottomPadding,
      bodySpacing: bodySpacing,
      sectionGap: sectionGap,
      headingFontSize: headingFontSize,
      buttonRadius: buttonRadius,
      buttonVerticalPadding: buttonVerticalPadding,
    );
  }
}

