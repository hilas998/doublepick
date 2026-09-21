import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile.dart';
import 'rules.dart';
import 'leaderboard_screen.dart';
import 'league_menu_screen.dart';
import 'bonus_game_menu_screen.dart';
import 'my_leagues_favorites_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BonusGameMenuScreen(),
    const LeagueMenuScreen(),
    const LeaderboardScreen(),
    const MyLeaguesFavoritesScreen(),
    const RulesScreen(),
    UserProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A), // tamna pozadina
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF022D12), Color(0xFF011F0A)], // tamnozelena
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFFFFD700), // žuta boja
          unselectedItemColor: Colors.grey.shade600,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.rule), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
          ],
        ),
      ),
    );
  }
}
