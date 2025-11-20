import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/user_provider.dart';
import 'screens/dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_home_screen.dart'; //add
import 'screens/friends_screen.dart';  //add
import 'screens/messages_screen.dart'; //add
import 'screens/calendar_screen.dart'; //add
import 'screens/notifications_screen.dart'; //add

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TraceNoxus',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const WelcomeScreen(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const DashboardScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/user-home': (context) => const UserHomeScreen(), //add
          '/friends': (context) => const FriendsScreen(), //add
          '/messages': (context) => const MessagesScreen(), //add
          '/calendar': (context) => const CalendarScreen(), //add
          '/notifications': (context) => const NotificationsScreen(), //add
        },
      ),
    );
  }
}
