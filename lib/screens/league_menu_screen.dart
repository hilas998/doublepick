import 'package:flutter/material.dart';
import 'LeagueScreenGlobal.dart'; // 👈 koristiš svoj globalni liga screen

class LeagueMenuScreen extends StatelessWidget {
  const LeagueMenuScreen({super.key});

  final List<Map<String, dynamic>> leagues = const [
    {'id': 'english_league', 'name': 'English League', 'icon': Icons.flag },
    {'id': 'german_league', 'name': 'German League', 'icon': Icons.sports_soccer},
    {'id': 'french_league', 'name': 'French League', 'icon': Icons.emoji_events},
    {'id': 'italian_league', 'name': 'Italian League', 'icon': Icons.shield},
    {'id': 'spanish_league', 'name': 'Spanish League', 'icon': Icons.sports},
    {'id': 'champions_league', 'name': 'Champions League', 'icon': Icons.star},
    {'id': 'conference_league', 'name': 'Conference League', 'icon': Icons.public},
    {'id': 'europa_league', 'name': 'Europa League', 'icon': Icons.workspace_premium},
    {'id': 'world_cup', 'name': 'World Cup', 'icon': Icons.public},
    {'id': 'european_cup', 'name': 'European Cup', 'icon': Icons.emoji_events},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF011F0A),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leagues',
              style: TextStyle(
                color: Color(0xFFEFFF8A),
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: leagues.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (context, index) {
                  final league = leagues[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.greenAccent.withOpacity(0.2),
                    child: InkWell(
                      onTap: () {
                        // 👇 otvara direktno LeagueScreenGlobal sa ID-om
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeagueScreenGlobal(
                              leagueId: league['id'],
                              leagueName: league['name'],
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(league['icon'], size: 40, color: Colors.yellow),
                            const SizedBox(height: 8),
                            Text(
                              league['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
