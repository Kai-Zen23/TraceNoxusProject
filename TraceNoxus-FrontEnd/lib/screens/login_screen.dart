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
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // TRACE NOXUS Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Image.asset(
                    'assets/Image/TraceNoxus LOGO.png',
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          border: Border.all(
                            color: const Color(0xFF88AEC9),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Color(0xFF88AEC9),
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/Image/VG VOUCHER DRAFT.png',
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'Ascend the trail',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                          Colors.white.withOpacity(0.15),
                          BlendMode.srcATop,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(130),
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
                              const SizedBox(height: 16),
                              // Email
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
                              const SizedBox(height: 24),
                              // Password
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
                              const SizedBox(height: 10),
                              // Primary sign-in button
                              SizedBox(
                                width: 220,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
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
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: const Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Secondary actions
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}