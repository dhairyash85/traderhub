import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of pages
  final List<Widget> _pages = [
    const HomePage(),   // Home
    const ChatListPage(), // Messages
    const ProfilePage() // Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // Update selected page index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],  // Show selected page

      // Bottom Navigation Bar with Messages tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}