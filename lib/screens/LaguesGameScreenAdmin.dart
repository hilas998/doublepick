import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'league_admin_detail_screen.dart';


class LaguesGameScreen extends StatelessWidget {
  const LaguesGameScreen({super.key});




  final List<String> leagues = const [
  "champions_league",
  "conference_league",
  "english_league",
  "europa_league",
  "european_cup",
  "french_league",
  "german_league",
  "italian_league",
  "spanish_league",
  "world_cup",
  ];

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text("Leagues Admin Score")),
  body: ListView.builder(
  itemCount: leagues.length,
  itemBuilder: (context, index) {
  final league = leagues[index];

  return ListTile(
  title: Text(league),
  trailing: const Icon(Icons.arrow_forward),
  onTap: () {
  Navigator.push(
  context,
  MaterialPageRoute(
  builder: (_) => LeagueAdminDetailScreen(leagueId: league),
  ),
  );
  },
  );
  },
  ),
  );
  }
  }