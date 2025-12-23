import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _panelController;
  late AnimationController _loadingController;
  
  // Animation for the Logo
  late Animation<Alignment> _logoAlignmentAnim;
  late Animation<double> _logoScaleAnim;

  // Animation for the Panel (Box)
  late Animation<Offset> _panelSlideAnim;

  bool _isLoading = true;
  bool _rememberMe = true;

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
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final authService = AuthService();
    final credentials = await authService.getSavedCredentials();
    if (credentials['email'] != null && mounted) {
      setState(() {
        _emailController.text = credentials['email']!;
        if (credentials['password'] != null) {
          _passwordController.text = credentials['password']!;
        }
        _rememberMe = true; // If we found credentials, rememberMe was true
      });
    }
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
    _emailController.dispose();
    _passwordController.dispose();
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        // Redirect based on user role (RBAC pattern)
        if (authProvider.isAdmin) {
          Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
        }
      }
    }
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = _LoginSpec.fromWidth(MediaQuery.of(context).size.width);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image Layer
            Positioned.fill(
              child: Image.asset(
                'assets/image/background_user.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.black87);
                },
              ),
            ),
            // Overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            // Animated Content
            AnimatedBuilder(
              animation: _panelController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // --- LOGO SECTION ---
                    Align(
                      alignment: _logoAlignmentAnim.value,
                      child: Transform.scale(
                        scale: _logoScaleAnim.value,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: _panelController.value * spec.topSpacing,
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
                    
                    // --- SLIDING PANEL ---
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SlideTransition(
                        position: _panelSlideAnim,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: bottomInset),
                          child: SingleChildScrollView(
                            child: _buildBottomCard(context, spec),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // Loading Overlay
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
  
  Widget _buildBottomCard(BuildContext context, _LoginSpec spec) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spec.cardOuterPadding,
        0,
        spec.cardOuterPadding,
        0,
      ),
      child: Center(
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
                topLeft: const Radius.circular(0),
                bottomLeft: const Radius.circular(30),
                bottomRight: const Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min, // Changed to min to fit content
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
                      const Text(
                        'Welcome',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Color(0xFF233A66),
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: spec.fieldSpacing),
                      CustomTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        spacing: spec.fieldSpacing,
                      ),
                      CustomTextField(
                        label: 'Password',
                        hint: 'Password',
                        controller: _passwordController,
                        isPassword: true,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter your password' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? true;
                                });
                              },
                              activeColor: const Color(0xFF233A66),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const Text(
                            'Remember Me',
                            style: TextStyle(
                              color: Color(0xFF233A66),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spec.sectionGap),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: spec.buttonMaxWidth),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
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
                                    colors: [
                                      Color(0xFF6DA7CE),
                                      Color(0xFF375468),
                                    ],
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
                                  child: Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: spec.buttonFontSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spec.sectionGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          authProvider.isLoading
                          ? const SizedBox(
                            width: 120,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2,),
                            ),
                          )
                         : TextButton(
                            onPressed: _forgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF233A66),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          authProvider.isLoading
                          ? const SizedBox(
                            width: 150,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )

                         : TextButton(
                            onPressed: _createAccount,
                            child: const Text(
                              'Create an account',
                              style: TextStyle(
                                color: Color(0xFF233A66),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginSpec {
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
  final double cardLeftRadius;
  final double cardBottomRadius;
  final double cardBottomPadding;
  final double fieldSpacing;
  final double sectionGap;
  final double buttonMaxWidth;
  final double buttonVerticalPadding;
  final double buttonRadius;
  final double buttonFontSize;

  const _LoginSpec({
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
    required this.cardLeftRadius,
    required this.cardBottomRadius,
    required this.cardBottomPadding,
    required this.fieldSpacing,
    required this.sectionGap,
    required this.buttonMaxWidth,
    required this.buttonVerticalPadding,
    required this.buttonRadius,
    required this.buttonFontSize,
  });

  factory _LoginSpec.fromWidth(double width) {
    final isTablet = width >= 768;
    final isDesktop = width >= 1024;

    double clamp(double value, double min, double max) => math.min(math.max(value, min), max);

    final topSpacing = clamp(width * 0.18, 80, 140);
    final logoHeight = clamp(width * 0.25, 120, 200);
    final logoFallbackHeight = clamp(logoHeight * 0.72, 90, 150);
    final logoIconSize = clamp(logoHeight * 0.22, 28, 44);
    final brandSpacing = clamp(width * 0.03, 10, 24);
    final heroSpacing = clamp(width * 0.06, 24, 48);
    final voucherHeight = clamp(width * 0.2, 90, 160);
    final voucherFallbackFontSize = clamp(voucherHeight * 0.16, 18, 24);

    final cardOuterPadding = isDesktop ? 120.0 : isTablet ? 48.0 : 0.0;
    
    // Updated widths from welcome.dart
    final cardMaxWidth = isDesktop
        ? clamp(width * 0.65, 600, 900)
        : isTablet
            ? clamp(width * 0.85, 500, 700)
            : clamp(width * 0.70, 600, 800);

    final cardVerticalPadding = clamp(width * 0.08, 24, 40);
    final cardHorizontalPadding = isTablet ? 32.0 : 20.0;
    final cardRightRadius = clamp(width * 0.2, 72, 130);
    final cardLeftRadius = 0.0;
    final cardBottomRadius = 0.0;
    final cardBottomPadding = isDesktop ? 64.0 : 32.0;
    final fieldSpacing = clamp(width * 0.045, 16.0, 26.0);
    final sectionGap = clamp(width * 0.035, 14.0, 24.0);

    final buttonMaxWidth = clamp(width * 0.65, 220.0, isDesktop ? 420.0 : 320.0);
    final buttonVerticalPadding = clamp(width * 0.035, 12.0, 18.0);
    final buttonRadius = 32.0;
    final buttonFontSize = clamp(width * 0.045, 16.0, 20.0);

    return _LoginSpec(
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
      cardLeftRadius: cardLeftRadius,
      cardBottomRadius: cardBottomRadius,
      cardBottomPadding: cardBottomPadding,
      fieldSpacing: fieldSpacing,
      sectionGap: sectionGap,
      buttonMaxWidth: buttonMaxWidth,
      buttonVerticalPadding: buttonVerticalPadding,
      buttonRadius: buttonRadius,
      buttonFontSize: buttonFontSize,
    );
  }
}