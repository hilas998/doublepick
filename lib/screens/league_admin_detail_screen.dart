import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeagueAdminDetailScreen extends StatefulWidget {
  final String leagueId;

  const LeagueAdminDetailScreen({super.key, required this.leagueId});

  @override
  State<LeagueAdminDetailScreen> createState() =>
      _LeagueAdminDetailScreenState();
}

class _LeagueAdminDetailScreenState extends State<LeagueAdminDetailScreen> {
  final db = FirebaseFirestore.instance;

  Map<String, dynamic> matches = {};

  // držimo rezultate u memoriji
  Map<String, TextEditingController> homeControllers = {};
  Map<String, TextEditingController> awayControllers = {};

  @override
  void initState() {
    super.initState();
    _loadLeague();
  }

  // =========================
  // LOAD DATA
  // =========================
  Future<void> _loadLeague() async {
    final doc =
    await db.collection('leagues2').doc(widget.leagueId).get();

    final data = doc.data()?['matches'] ?? {};

    setState(() {
      matches = Map<String, dynamic>.from(data);

      for (var entry in matches.entries) {
        homeControllers[entry.key] = TextEditingController();
        awayControllers[entry.key] = TextEditingController();
      }
    });
  }

  // =========================
  // UPDATE ALL RESULTS
  // =========================
  Future<void> _updateAllResults() async {
    final ref =
    db.collection('leagues2').doc(widget.leagueId);

    Map<String, dynamic> updates = {};

    homeControllers.forEach((key, controller) {
      final homeVal = int.tryParse(controller.text) ?? -1;
      updates['matches.$key.resHome'] = homeVal;
    });

    awayControllers.forEach((key, controller) {
      final awayVal = int.tryParse(controller.text) ?? -1;
      updates['matches.$key.resAway'] = awayVal;
    });

    await ref.update(updates);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Svi rezultati ažurirani")),
    );
  }

  // =========================
  // MATCH UI
  // =========================
  Widget matchCard(String key, Map match) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            // 🔥 SAMO ISPIS TIMOVA
            Text(
              "${match['home']} vs ${match['away']}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 10),

            // SCORE INPUT
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: homeControllers[key],
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: "Home score"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: awayControllers[key],
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: "Away score"),
                  ),
                ),
              ],
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
      appBar: AppBar(title: Text(widget.leagueId)),
      body: Column(
        children: [

          Expanded(
            child: ListView(
              children: matches.entries
                  .where((e) {
                final home = e.value['home'] ?? "";
                final away = e.value['away'] ?? "";

                return home.toString().isNotEmpty &&
                    away.toString().isNotEmpty;
              })
                  .map((e) {
                return matchCard(e.key, e.value);
              }).toList(),
            ),
          ),

          // 🔥 JEDAN GUMB NA DNU
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateAllResults,
                child: const Text("UPDATE ALL RESULTS"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}