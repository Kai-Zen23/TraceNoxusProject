import 'package:TraceNoxus/screens/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:TraceNoxus/providers/auth_provider.dart';
import 'package:TraceNoxus/screens/welcome.dart';
import 'package:TraceNoxus/screens/login_screen.dart';


class InitialScreenWrapper extends StatefulWidget {
  const InitialScreenWrapper({Key? key}) : super(key: key);

  @override
  State<InitialScreenWrapper> createState() => _InitialScreenWrapperState();
}

class _InitialScreenWrapperState extends State<InitialScreenWrapper> {
  bool _isLocalCheckDone = false;
  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Use 'has_seen_welcome' key as defined previously (not visible but implied)
    // We can just use the string literal for clarity
    _isFirstLaunch = !(prefs.getBool('has_seen_welcome') ?? false);
    
    // If it is first launch, we mark it as seen immediately for next time?
    // Or wait until they finish welcome? 
    // Usually wait, but logic above had explicit set.
    // Let's keep logic: if first launch, show welcome, mark as seen.
    if (_isFirstLaunch) {
        await prefs.setBool('has_seen_welcome', true);
    }
    
    if (mounted) {
      setState(() {
        _isLocalCheckDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider
    final auth = Provider.of<AuthProvider>(context);

    // Show loading if either local check isn't done OR auth isn't initialized
    if (!_isLocalCheckDone || !auth.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 1. First Launch -> Welcome
    if (_isFirstLaunch) {
      return const WelcomeScreen();
    }

    // 2. Authenticated -> User Home
    if (auth.isAuthenticated) {
      return const UserHomeScreen();
    } 
    
    // 3. Not Authenticated -> Login
    return const LoginScreen();
  }
}