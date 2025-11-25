import 'package:TraceNoxus/services/message_service.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:TraceNoxus/screens/InitialScreen.dart';
import 'package:TraceNoxus/screens/register_screen.dart';
import 'providers/message_provider.dart';
import 'screens/chat_screen.dart';
import 'providers/friend_provider.dart';
import 'providers/room_chat_provider.dart';
import 'screens/general_chat_screen.dart';
import 'providers/friend_requests_provider.dart';
import 'screens/friend_requests_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => RoomChatProvider()),
        ChangeNotifierProvider(create: (_) => FriendRequestsProvider()),
    
        
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TraceNoxus',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
       // home: const WelcomeScreen(),
        home: const InitialScreenWrapper(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const DashboardScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/user-home': (context) => const UserHomeScreen(), //add
          '/friends': (context) => const FriendsScreen(), //add
          '/messages': (context) => const MessagesScreen(),
          '/chat': (context) => const ChatScreen(otherUserId: 0),
          '/friend-requests': (context) => const FriendRequestsScreen(),
          '/calendar': (context) => const CalendarScreen(), //add
          '/notifications': (context) => const NotificationsScreen(), //add
          '/Initial': (context) => const InitialScreenWrapper(), //add
          '/general-chat': (context) => const GeneralChatScreen(),
        },
      ),
    );
  }
}
