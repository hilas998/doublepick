import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeagueAdminDetailScreenTeam extends StatefulWidget {
  final String leagueId;

  const LeagueAdminDetailScreenTeam({
    super.key,
    required this.leagueId,
  });

  @override
  State<LeagueAdminDetailScreenTeam> createState() =>
      _LeagueAdminDetailScreenTeamState();
}

class _LeagueAdminDetailScreenTeamState
    extends State<LeagueAdminDetailScreenTeam> {
  final db = FirebaseFirestore.instance;

  List<Map<String, String>> matches = [];
  List<String> allTeams = [];
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _addMatch();
  }

  // =========================
  // LOAD TEAMS FROM FIREBASE
  // =========================
  Future<void> _loadTeams() async {
    final doc = await db
        .collection("leagues2")
        .doc(widget.leagueId)
        .get();

    final data = doc.data()?["teams"] ?? {};

    setState(() {
      allTeams = List<String>.from(data.values);
    });
  }

  // =========================
  // ADD MATCH
  // =========================
  void _addMatch() {
    setState(() {
      matches.add({"home": "", "away": ""});
    });
  }

  // =========================
  // AVAILABLE TEAMS FILTER
  // =========================
  List<String> _availableTeams(int index) {
    Set<String> selected = {};

    for (int i = 0; i < matches.length; i++) {
      if (i == index) continue;

      if (matches[i]["home"]!.isNotEmpty) {
        selected.add(matches[i]["home"]!);
      }
      if (matches[i]["away"]!.isNotEmpty) {
        selected.add(matches[i]["away"]!);
      }
    }

    return allTeams.where((t) => !selected.contains(t)).toList();
  }

  // =========================
  // PICK DATE
  // =========================
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // =========================
  // UPDATE FIREBASE
  // =========================
  Future<void> _updateTeams() async {
    if (selectedDateTime == null) return;

    final global = selectedDateTime!.millisecondsSinceEpoch;
    final score = global + (5 * 24 * 60 * 60 * 1000);

    Map<String, dynamic> matchesUpdate = {};

    for (int i = 0; i < matches.length; i++) {
      final home = matches[i]["home"]!;
      final away = matches[i]["away"]!;

      if (home.isEmpty || away.isEmpty) continue;

      matchesUpdate["match${i + 1}"] = {
        "home": home,
        "away": away,
        "resHome": -1,
        "resAway": -1,
      };
    }

    await db.collection("leagues2").doc(widget.leagueId).update({
      "globalEndTimeMillis": global,
      "scoreCalcEndTimeMillis": score,
      "matches": matchesUpdate,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated")),
    );
  }

  // =========================
  // MATCH UI
  // =========================
  Widget matchInput(int index) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text("Match ${index + 1}"),

            // HOME
            DropdownButton<String>(
              value: matches[index]["home"]!.isEmpty
                  ? null
                  : matches[index]["home"],

              hint: const Text("Home team"),

              items: _availableTeams(index).map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(team),
                );
              }).toList(),

              onChanged: (val) {
                setState(() {
                  matches[index]["home"] = val ?? "";
                });
              },
            ),

            // AWAY
            DropdownButton<String>(
              value: matches[index]["away"]!.isEmpty
                  ? null
                  : matches[index]["away"],

              hint: const Text("Away team"),

              items: _availableTeams(index).map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(team),
                );
              }).toList(),

              onChanged: (val) {
                setState(() {
                  matches[index]["away"] = val ?? "";
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueId),
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return matchInput(index);
              },
            ),
          ),

          ElevatedButton(
            onPressed: _addMatch,
            child: const Text("ADD MATCH"),
          ),

          ElevatedButton(
            onPressed: _pickDate,
            child: const Text("PICK GLOBAL TIME"),
          ),

          ElevatedButton(
            onPressed: _updateTeams,
            child: const Text("SAVE"),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
