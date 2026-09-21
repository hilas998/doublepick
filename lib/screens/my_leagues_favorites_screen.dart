import 'package:flutter/material.dart';
import 'MyLeagues.dart'; // tvoj MyLeaguesScreen
import 'favorites_screen.dart'; // tvoj FavoritesScreen

class MyLeaguesFavoritesScreen extends StatefulWidget {
  const MyLeaguesFavoritesScreen({super.key});

  @override
  State<MyLeaguesFavoritesScreen> createState() => _MyLeaguesFavoritesScreenState();
}

class _MyLeaguesFavoritesScreenState extends State<MyLeaguesFavoritesScreen> {
  bool showLeagues = true; // defaultno prikazujemo My Leagues

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00150A),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'DoublePick',
          style: TextStyle(
            color: Color(0xFFEFFF8A),
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // 🔹 Dugmad za izbor
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.sports_soccer, color: Colors.black),
                style: ElevatedButton.styleFrom(
                  backgroundColor: showLeagues ? Colors.greenAccent : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => showLeagues = true);
                },
                label: const Text("MY LEAGUES", style: TextStyle(color: Colors.black)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.star, color: Colors.black),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !showLeagues ? Colors.greenAccent : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => showLeagues = false);
                },
                label: const Text("MY FAVORITES", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔹 Prikaz ekrana
          Expanded(
            child: showLeagues
                ? const MyLeaguesScreen()
                : const FavoritesScreen(),
          ),
        ],
      ),
    );
  }
}
