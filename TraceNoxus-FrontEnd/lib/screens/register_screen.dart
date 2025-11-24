import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';
import '../widgets/ResponsiveSpec.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen ({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}


class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _emailController.text,
        _nameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OtpVerificationScreen(),
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Services'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = ResponsiveSpec.fromWidth(MediaQuery.of(context).size.width);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/image/backgrounduser.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.black87);
              },
            ),
          ),
          // Overlay for better text readability
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
                          SizedBox(height: spec.topSpacing * 0.6), // Reduced spacing
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // TraceNoxus Logo on the left
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Image.asset(
                                      'assets/image/TraceNoxusLOGO.png',
                                      height: spec.logoHeight * 0.65, // Smaller to fit better
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                            height: spec.logoFallbackHeight * 0.65,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[800],
                                              border: Border.all(
                                                color: const Color(0xFF88AEC9),
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  color: const Color(0xFF88AEC9),
                                                  size: spec.logoIconSize,
                                                ),
                                              ),
                                            );
                                        },
                                    ),
                                  ),
                                ),
                                // VG VOUCHER DRAFT Logo on the right
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Image.asset(
                                      'assets/image/VG VOUCHER DRAFT.png',
                                      height: spec.voucherHeight * 0.65, // Smaller to fit better
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Text(
                                          'Ascend the trail',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: spec.voucherFallbackFontSize * 0.65,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.0,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spec.heroSpacing * 0.5), // Reduced spacing
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
                                image: const AssetImage('assets/image/Charactergirl.png'),
                                fit: BoxFit.cover,
                                alignment: const Alignment(0.3, 0.5), // Move more to the right
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
                                        'WELCOME TO TRACE!',
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
                                        'Name',
                                        style: TextStyle(
                                          color: Color(0xFF233A66),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _nameController,
                                        validator: (value) =>
                                        value?.isEmpty ?? true ? 'Please enter your name' : null,
                                        decoration: const InputDecoration(
                                          hintText: 'Full Name',
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
                                          hintText: 'Valid Email',
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
                                        validator: _validatePassword,
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
                                      SizedBox(height: spec.fieldSpacing),
                                      const Text(
                                        'Confirm Password',
                                        style: TextStyle(
                                          color: Color(0xFF233A66),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: true,
                                        validator: _validateConfirmPassword,
                                        decoration: const InputDecoration(
                                          hintText: 'Confirm Password',
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
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _acceptTerms,
                                            activeColor: const Color(0xFF233A66),
                                            checkColor: Colors.white,
                                            onChanged: (value) {
                                              setState(() {
                                                _acceptTerms = value ?? false;
                                              });
                                            },
                                          ),
                                          const Expanded(
                                            child: Text(
                                              'I accept the Terms and Services',
                                              style: TextStyle(
                                                color: Color(0xFF233A66),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
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
                                              onPressed: _acceptTerms ? _register : null,
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
                                                    'SIGN UP',
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed: _goToLogin,
                                            child: const Text(
                                              'Already have an account? Sign in',
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