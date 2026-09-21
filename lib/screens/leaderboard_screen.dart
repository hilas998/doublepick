import 'package:flutter/material.dart';
import 'standings.dart';
import 'round_standings.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool showGlobal = true; // defaultno prikazujemo global

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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: showGlobal ? Colors.greenAccent : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => showGlobal = true);
                },
                child: const Text("GLOBAL"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: !showGlobal ? Colors.greenAccent : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => showGlobal = false);
                },
                child: const Text("ROUND"),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔹 Prikaz ekrana
          Expanded(
            child: showGlobal
                ? const StandingsScreen() // global leaderboard
                : const RoundStandingsScreen(), // round leaderboard
          ),
        ],
      ),
    );
  }
}
