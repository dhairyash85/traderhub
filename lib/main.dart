import 'package:flutter/material.dart';
import 'package:traderhub/main_screen.dart';
import 'package:traderhub/profile_page.dart';
import 'package:traderhub/your_requests_page.dart';
import 'home_page.dart';
import "chat_list_page.dart";
import "chat_page.dart";
import 'auth_page.dart';
import 'post_item_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BarterApp());
}

class BarterApp extends StatelessWidget {
  const BarterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barter System App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      initialRoute: '/auth',
      // In your routes map
      // In your lib/main.dart, update the routes map
      routes: {
        '/auth': (context) => const AuthPage(),
        '/main': (context) => const MainScreen(),
        '/post-item': (context) => const PostItemPage(),
        '/requests': (context) => const YourRequestsPage(),
        '/chat-list': (context) => const ChatListPage(),
        '/chat': (context) => ChatPage(
              chatRoomId: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>)['chatRoomId'] ??
                  '',
              otherUserId: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>)['userId'] ??
                  '',
              otherUserName: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>)['userName'] ??
                  'User',
            ),
      },
    );
  }
}
