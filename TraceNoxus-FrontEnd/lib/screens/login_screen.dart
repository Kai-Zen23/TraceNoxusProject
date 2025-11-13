import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
// import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _ResponsiveSpec {
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

  const _ResponsiveSpec({
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

  factory _ResponsiveSpec.fromWidth(double width) {
    final isTablet = width >= 768;
    final isDesktop = width >= 1024;

    final topSpacing = _clampDouble(width * 0.18, 160, 300);
    final logoHeight = _clampDouble(width * 0.25, 170, 300);
    final logoFallbackHeight = _clampDouble(logoHeight * 0.72, 90, 150);
    final logoIconSize = _clampDouble(logoHeight * 0.22, 28, 44);
    final brandSpacing = _clampDouble(width * 0.03, 10, 20);
    final heroSpacing = _clampDouble(width * 0.08, 48, 80);
    final voucherHeight = _clampDouble(width * 0.22, 100, 180);
    final voucherFallbackFontSize = _clampDouble(voucherHeight * 0.16, 18, 26);

    final cardOuterPadding = isDesktop ? 80.0 : isTablet ? 32.0 : 0.0;
    final cardMaxWidth = isDesktop
        ? _clampDouble(width * 0.72, 560.0, 820.0)
        : isTablet
            ? _clampDouble(width * 0.88, 400.0, 640.0)
            : width;
    final cardVerticalPadding = _clampDouble(width * 0.08, 24, 40);
    final cardHorizontalPadding = isTablet ? 32.0 : 20.0;
    final cardRightRadius = _clampDouble(width * 0.22, 72, 140);
    final cardLeftRadius = 0.0;
    final cardBottomRadius = 0.0;
    final cardBottomPadding = isDesktop ? 64.0 : 32.0;
    final fieldSpacing = _clampDouble(width * 0.045, 16.0, 26.0);
    final sectionGap = _clampDouble(width * 0.035, 14.0, 24.0);

    final buttonMaxWidth = _clampDouble(width * 0.65, 220.0, isDesktop ? 420.0 : 320.0);
    final buttonVerticalPadding = _clampDouble(width * 0.035, 12.0, 18.0);
    final buttonRadius = 32.0;
    final buttonFontSize = _clampDouble(width * 0.045, 16.0, 20.0);

    return _ResponsiveSpec(
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

double _clampDouble(double value, double min, double max) {
  return math.min(math.max(value, min), max);
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
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
    final spec = _ResponsiveSpec.fromWidth(MediaQuery.of(context).size.width);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/Image/BackGroundIm(2).png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return Container(color: Colors.black87);
              },
            ),
          ),
          // Overlay for better text readability (lighter overlay to show background image)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Content Layer
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
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
                                      color: Color(0xFF88AEC9),
                                      size: spec.logoIconSize,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: spec.brandSpacing),
                          Image.asset(
                            'assets/Image/VG VOUCHER DRAFT.png',
                            height: spec.voucherHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                'Ascend the trail',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: spec.voucherFallbackFontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: spec.heroSpacing),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          spec.cardOuterPadding,
                          0,
                          spec.cardOuterPadding,
                          spec.cardBottomPadding,
                        ),
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
                                image: const AssetImage('assets/Image/Girl.png'),
                                fit: BoxFit.cover,
                                alignment: Alignment.centerRight,
                                colorFilter: ColorFilter.mode(
                                  const Color.fromARGB(255, 110, 131, 184).withOpacity(0.5),
                                  BlendMode.srcATop,
                                ),
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(spec.cardRightRadius),
                              ),
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
                                    children: [
                                      const Text(
                                        'Welcome back!',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Color(0xFF233A66),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 26,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: spec.fieldSpacing),
                                      const Text(
                                        'Email',
                                        style: TextStyle(
                                          color: Color(0xFF233A66),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: _validateEmail,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter your email',
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(0xFF88AEC9), width: 2),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(0xFF233A66), width: 2),
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: spec.fieldSpacing),
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          color: Color(0xFF233A66),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        validator: (value) =>
                                            value?.isEmpty ?? true ? 'Please enter your password' : null,
                                        decoration: const InputDecoration(
                                          hintText: 'Password',
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(0xFF88AEC9), width: 2),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(0xFF233A66), width: 2),
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 16),
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
                                          TextButton(
                                            onPressed: _forgotPassword,
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: Color(0xFF233A66),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          TextButton(
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
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}