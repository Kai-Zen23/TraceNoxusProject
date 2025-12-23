import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _panelController;
  late AnimationController _loadingController;
  
  // Animation for the Logo
  late Animation<Alignment> _logoAlignmentAnim;
  late Animation<double> _logoScaleAnim;

  // Animation for the Panel (Box)
  late Animation<Offset> _panelSlideAnim;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Controller for the Panel (0.0 = Hidden/Down, 1.0 = Shown/Up)
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0.0, // Start hidden for loading sequence
    );

    // Loading Animation Controller
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _setupAnimations();
    _startLoadingSequence();
  }

  void _setupAnimations() {
    // Logo goes from Center (Hidden) to Top (Shown)
    _logoAlignmentAnim = Tween<Alignment>(
      begin: Alignment.center,
      end: Alignment.topCenter,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOutCubic,
    ));

    // Logo scale: 1.5x (Hidden) -> 1.0x (Shown)
    _logoScaleAnim = Tween<double>(
      begin: 1.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOutCubic,
    ));

    // Panel slides from bottom off-screen (Offset y=1.0) to natural position (Offset.zero)
    _panelSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOutCubic,
    ));
  }

  Future<void> _startLoadingSequence() async {
    // 1. Start with Logo in Center (PanelController = 0)
    // 2. Play a loading animation if needed (e.g., logo pulse or separate loader)
    // 3. After delay, animate panel up
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _panelController.forward(); // Bring up the panel
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    _loadingController.dispose();
    super.dispose();
  }
  
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Screen height to normalize drag distance
    final screenHeight = MediaQuery.of(context).size.height;
    // Moving down (positive delta) decreases the value (hides panel)
    // Moving up (negative delta) increases the value (shows panel)
    _panelController.value -= details.primaryDelta! / screenHeight;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    // Velocity check for fling
    if (details.primaryVelocity! < -500) {
      _panelController.forward(); // Fling up
    } else if (details.primaryVelocity! > 500) {
      _panelController.reverse(); // Fling down
    } else {
      // Snap to nearest
      if (_panelController.value > 0.5) {
        _panelController.forward();
      } else {
        _panelController.reverse();
      }
    }
  }

  void _goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the existing spec logic for responsiveness, 
    // but we might override top spacing since logo is animated.
    final spec = _WelcomeSpec.fromWidth(MediaQuery.of(context).size.width);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        behavior: HitTestBehavior.translucent, // Catch taps on background
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/image/background_user.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black87),
              ),
            ),
            
            // 2. Dark Overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),

            // 3. Animated Content
            AnimatedBuilder(
              animation: _panelController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // --- LOGO SECTION ---
                    // We align the logo based on the animation value
                    Align(
                      alignment: _logoAlignmentAnim.value, // centers vertical/horizontal or topCenter
                      child: Transform.scale(
                        scale: _logoScaleAnim.value,
                        child: Padding(
                          // Add some top padding when at topCenter so it doesn't hit status bar
                          padding: EdgeInsets.only(
                            top: _panelController.value * spec.topSpacing, // Only apply padding when moving to top
                            left: 50,
                            right: 50,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/image/TraceNoxusLOGO.png',
                                height: spec.logoHeight,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: spec.logoFallbackHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    border: Border.all(color: const Color(0xFF88AEC9), width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: Color(0xFF88AEC9),
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              if (_panelController.value > 0.6) ...[
                                // Only show these when panel is visible/logo is at top
                                SizedBox(height: spec.brandSpacing),
                                Opacity(
                                  opacity: _panelController.value,
                                  child: Image.asset(
                                    'assets/image/VG VOUCHER DRAFT.png',
                                    height: spec.voucherHeight,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const SizedBox(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- SLIDING PANEL (THE BOX) ---
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SlideTransition(
                        position: _panelSlideAnim,
                        child: _buildBottomCard(context, spec),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 4. Loading Overlay (Optional: Initial Splash effect)
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF88AEC9),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard(BuildContext context, _WelcomeSpec spec) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spec.cardOuterPadding,
        0,
        spec.cardOuterPadding,
        0, // Keep some distance from actual bottom if needed
      ),
      child: Center( // Center horizontally if constrained max width
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: spec.cardMaxWidth),
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
                image: const AssetImage('assets/image/Charactergirl.png'),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                colorFilter: ColorFilter.mode(
                  const Color.fromARGB(255, 110, 131, 184).withOpacity(0.5),
                  BlendMode.srcATop,
                ),
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(spec.cardRightRadius),
                topLeft: const Radius.circular(0), // Added slight curve to left too for floating feel
                bottomLeft: const Radius.circular(0),
                bottomRight: const Radius.circular(0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle Indicator
                Center(
                  child: Container(
                    width: 80,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF233A66).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Welcome ',
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
                  onPressed: () => _goToLogin(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spec.buttonRadius),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6DA7CE), Color(0xFF375468)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(spec.buttonRadius),
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
                  onPressed: () => _goToRegister(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF233A66),
                    side: const BorderSide(color: Color(0xFF233A66), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spec.buttonRadius),
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
    );
  }
}

class _WelcomeSpec {
  final double topSpacing;
  final double logoHeight;
  final double logoFallbackHeight;
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

  const _WelcomeSpec({
    required this.topSpacing,
    required this.logoHeight,
    required this.logoFallbackHeight,
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

  factory _WelcomeSpec.fromWidth(double width) {
    final isTablet = width >= 768;
    final isDesktop = width >= 1024;

    double clamp(double value, double min, double max) => math.min(math.max(value, min), max);

    final topSpacing = clamp(width * 0.18, 80, 140);
    final logoHeight = clamp(width * 0.25, 120, 200);
    final logoFallbackHeight = clamp(logoHeight * 0.72, 90, 150);
    final brandSpacing = clamp(width * 0.03, 10, 24);
    final heroSpacing = clamp(width * 0.06, 24, 48);
    final voucherHeight = clamp(width * 0.2, 90, 160);
    final voucherFallbackFontSize = clamp(voucherHeight * 0.16, 18, 24);

    final cardOuterPadding = isDesktop ? 120.0 : isTablet ? 48.0 : 0.0;
    final cardMaxWidth = isDesktop
        ? clamp(width * 0.65, 600, 900)
        : isTablet
            ? clamp(width * 0.85, 500, 700)
            : clamp(width * 0.85, 700, 800);
    final cardVerticalPadding = clamp(width * 0.08, 24, 40);
    final cardHorizontalPadding = isTablet ? 32.0 : 24.0;
    final cardRightRadius = clamp(width * 0.2, 72, 130);
    final cardBottomPadding = isDesktop ? 80.0 : 40.0;

    final bodySpacing = clamp(width * 0.04, 16, 24);
    final sectionGap = clamp(width * 0.035, 14, 24);
    final headingFontSize = clamp(width * 0.07, 24, 30);
    final buttonRadius = 32.0;
    final buttonVerticalPadding = clamp(width * 0.04, 14, 18);

    return _WelcomeSpec(
      topSpacing: topSpacing,
      logoHeight: logoHeight,
      logoFallbackHeight: logoFallbackHeight,
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
