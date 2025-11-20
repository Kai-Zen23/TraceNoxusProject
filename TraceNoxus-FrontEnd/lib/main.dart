import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/user_provider.dart';
import 'screens/dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome.dart';
import 'screens/teams_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Django Auth',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const InitialScreenWrapper(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const DashboardScreen(),
          '/teams': (context) => const TeamsScreen(),
        },
      ),
    );
  }
}

/// Wrapper widget that determines which screen to show based on:
/// 1. First time opening the app (freshly downloaded)
/// 2. User authentication status
class InitialScreenWrapper extends StatefulWidget {
  const InitialScreenWrapper({Key? key}) : super(key: key);

  @override
  State<InitialScreenWrapper> createState() => _InitialScreenWrapperState();
}

class _InitialScreenWrapperState extends State<InitialScreenWrapper> {
  bool _isLoading = true;
  bool _isFirstLaunch = false;
  bool _isAuthenticated = false;

  static const String _hasSeenWelcomeKey = 'has_seen_welcome';

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      // Check if it's the first launch
      final prefs = await SharedPreferences.getInstance();
      _isFirstLaunch = !(prefs.getBool(_hasSeenWelcomeKey) ?? false);

      // Check authentication status
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Wait a bit for AuthProvider to initialize and check auth status
      await Future.delayed(const Duration(milliseconds: 100));
      _isAuthenticated = authProvider.isAuthenticated;

      // Mark welcome screen as seen if it's the first launch
      if (_isFirstLaunch) {
        await prefs.setBool(_hasSeenWelcomeKey, true);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // On error, default to showing welcome screen (first launch)
      setState(() {
        _isLoading = false;
        _isFirstLaunch = true;
        _isAuthenticated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a loading screen while checking
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show WelcomeScreen ONLY on first launch (freshly downloaded)
    if (_isFirstLaunch) {
      return const WelcomeScreen();
    }

    // After first launch:
    // - If authenticated: show DashboardScreen
    // - If not authenticated: show LoginScreen (not WelcomeScreen)
    if (_isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
