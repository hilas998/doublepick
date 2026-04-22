import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpisTeamSezona extends StatefulWidget {
  const UpisTeamSezona({super.key});

  @override
  State<UpisTeamSezona> createState() => _UpisTeamSezonaState();
}

class _UpisTeamSezonaState extends State<UpisTeamSezona> {
  final db = FirebaseFirestore.instance;

  String? selectedLeague;

  List<TextEditingController> teamControllers = [];

  final List<String> leagues = [
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
  void initState() {
    super.initState();
    _addTeam(); // start 1 input
  }

  void _addTeam() {
    setState(() {
      teamControllers.add(TextEditingController());
    });
  }

  Future<void> _saveTeams() async {
    if (selectedLeague == null) return;

    Map<String, dynamic> data = {};

    for (int i = 0; i < teamControllers.length; i++) {
      final name = teamControllers[i].text.trim();
      if (name.isEmpty) continue;

      data["team${i + 1}"] = name;
    }

    await db.collection("leagues2").doc(selectedLeague).update({
      "teams": data,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Teams saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upis timova sezone")),
      body: Column(
        children: [

          // 🔥 SELECT LIGA
          DropdownButton<String>(
            hint: const Text("Select league"),
            value: selectedLeague,
            items: leagues.map((league) {
              return DropdownMenuItem(
                value: league,
                child: Text(league),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedLeague = val;
              });
            },
          ),

          const SizedBox(height: 10),

          // 🔥 TEAM INPUTS
          Expanded(
            child: ListView.builder(
              itemCount: teamControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: teamControllers[index],
                    decoration: InputDecoration(
                      labelText: "Team ${index + 1}",
                    ),
                  ),
                );
              },
            ),
          ),

          // ADD TEAM
          ElevatedButton(
            onPressed: _addTeam,
            child: const Text("ADD TEAM"),
          ),

          // SAVE
          ElevatedButton(
            onPressed: _saveTeams,
            child: const Text("SAVE TEAMS"),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}