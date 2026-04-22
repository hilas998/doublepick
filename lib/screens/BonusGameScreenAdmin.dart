import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BonusGameScreen extends StatefulWidget {
  const BonusGameScreen({super.key});

  @override
  State<BonusGameScreen> createState() => _BonusGameScreenState();
}

class _BonusGameScreenState extends State<BonusGameScreen> {
  final db = FirebaseFirestore.instance;

  // aktivni timovi
  String team1 = "", team2 = "", team3 = "", team4 = "";

  // rezultati
  final r1 = TextEditingController();
  final r2 = TextEditingController();
  final r3 = TextEditingController();
  final r4 = TextEditingController();

  // sljedece
  final n1 = TextEditingController();
  final n2 = TextEditingController();
  final n3 = TextEditingController();
  final n4 = TextEditingController();

  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  // =========================
  // LOAD ACTIVE
  // =========================
  Future<void> _loadActive() async {
    final doc = await db.collection('timovi').doc('aktivni').get();
    final d = doc.data();

    setState(() {
      team1 = d?['team1'] ?? "";
      team2 = d?['team2'] ?? "";
      team3 = d?['team3'] ?? "";
      team4 = d?['team4'] ?? "";
    });
  }

  // =========================
  // SAVE RESULTS (AKTIVNI)
  // =========================
  Future<void> _saveResults() async {
    await db.collection('timovi').doc('aktivni').update({
      'stvarnirezultat1': r1.text,
      'stvarnirezultat2': r2.text,
      'stvarnirezultat3': r3.text,
      'stvarnirezultat4': r4.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rezultati spremljeni u AKTIVNI")),
    );
  }

  // =========================
  // DATE PICKER
  // =========================
  Future<void> _pickDateTime() async {
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
  // SAVE NEXT (SLJEDECE)
  // =========================
  Future<void> _setNext() async {
    if (selectedDateTime == null) return;

    final global = selectedDateTime!.millisecondsSinceEpoch;
    final score = global + (3 * 24 * 60 * 60 * 1000);

    await db.collection('timovi').doc('sljedece').set({
      'team1': n1.text,
      'team2': n2.text,
      'team3': n3.text,
      'team4': n4.text,

      // 🔥 NE DIRAMO START
      'globalEndTimeMillis': global,
      'scoreCalcEndTimeMillis': score,

      'startTimeMillis': 1767893405000,

      // 🔥 REZULTATI RESET ZA SLJEDEĆE KOLO
      'stvarnirezultat1': "",
      'stvarnirezultat2': "",
      'stvarnirezultat3': "",
      'stvarnirezultat4': "",


    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sljedeće kolo spremljeno")),
    );
  }

  // =========================
  // MATCH UI
  // =========================
  Widget matchBox(String t1, String t2,
      TextEditingController c1, TextEditingController c2) {
    return Column(
      children: [
        Text("$t1 vs $t2", style: const TextStyle(fontSize: 16)),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: c1,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Score 1"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: c2,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Score 2"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),
      ],
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bonus Admin")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ===== AKTIVNI =====
            const Text("AKTIVNI MEČEVI", style: TextStyle(fontSize: 18)),

            matchBox(team1, team2, r1, r2),
            matchBox(team3, team4, r3, r4),

            ElevatedButton(
              onPressed: _saveResults,
              child: const Text("SEND SCORE"),
            ),

            const Divider(),

            // ===== SLJEDEĆE =====
            const Text("SLJEDEĆE KOLO", style: TextStyle(fontSize: 18)),

            TextField(controller: n1, decoration: const InputDecoration(labelText: "Team 1")),
            TextField(controller: n2, decoration: const InputDecoration(labelText: "Team 2")),
            TextField(controller: n3, decoration: const InputDecoration(labelText: "Team 3")),
            TextField(controller: n4, decoration: const InputDecoration(labelText: "Team 4")),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _pickDateTime,
              child: Text(
                selectedDateTime == null
                    ? "Odaberi GLOBAL vrijeme"
                    : selectedDateTime.toString(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _setNext,
              child: const Text("SET NEXT ROUND"),
            ),
          ],
        ),
      ),
    );
  }
}