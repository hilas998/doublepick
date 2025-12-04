import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // ❗ DOZVOLJEN SAMO TVOJI EMAIL
  bool _isAdmin(User? user) {
    if (user == null) return false;
    return user.email == "salihlihic998@gmail.com";
  }

  // ================================
  //        CALCULATE ROUND
  // ================================
  Future<void> _calculateRound(BuildContext context) async {
    final db = FirebaseFirestore.instance;

    // Učitavamo aktivno kolo
    final roundDoc = await db.collection('timovi').doc('aktivni').get();
    if (!roundDoc.exists) return;

    final r = roundDoc.data()!;
    final rez1 = r['stvarnirezultat1'] ?? "";
    final rez2 = r['stvarnirezultat2'] ?? "";
    final rez3 = r['stvarnirezultat3'] ?? "";
    final rez4 = r['stvarnirezultat4'] ?? "";

    if ([rez1, rez2, rez3, rez4].any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unesi sve rezultate!")),
      );
      return;
    }

    int r1 = int.parse(rez1);
    int r2 = int.parse(rez2);
    int r3 = int.parse(rez3);
    int r4 = int.parse(rez4);

    // Učitavamo sve korisnike
    final usersSnap = await db.collection('users').get();

    for (var doc in usersSnap.docs) {
      final d = doc.data();

      String t1 = d['tip1']?.toString() ?? "";
      String t2 = d['tip2']?.toString() ?? "";
      String t3 = d['tip3']?.toString() ?? "";
      String t4 = d['tip4']?.toString() ?? "";

      int pts = 0;

      if ([t1, t2, t3, t4].any((e) => e.isEmpty)) {
        // Nije unio tipove → ostaje 0
      } else {
        int tip1 = int.parse(t1);
        int tip2 = int.parse(t2);
        int tip3 = int.parse(t3);
        int tip4 = int.parse(t4);

        bool exact1 = tip1 == r1 && tip2 == r2;
        bool exact2 = tip3 == r3 && tip4 == r4;

        bool outcome1 = _sameOutcome(tip1, tip2, r1, r2);
        bool outcome2 = _sameOutcome(tip3, tip4, r3, r4);

        if (exact1) pts += 15;
        else if (outcome1) pts += 5;

        if (exact2) pts += 15;
        else if (outcome2) pts += 5;

        if (exact1 && exact2) pts += 15;
      }

      // Dodavanje na globalni score
      final global = int.tryParse(d['score'] ?? '0') ?? 0;
      final newScore = global + pts;

      await doc.reference.update({
        'score': newScore.toString(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Scoring završen!")),
    );
  }

  bool _sameOutcome(int a, int b, int x, int y) {
    int sign(int d) => d > 0 ? 1 : (d < 0 ? -1 : 0);
    return sign(a - b) == sign(x - y);
  }

  // ================================
  //            RESET ROUND
  // ================================
  Future<void> _resetRound(BuildContext context) async {
    final db = FirebaseFirestore.instance;

    // ——————————————————————————
    // 1. Učitamo SLJEDEĆE kolo
    // ——————————————————————————
    final nextDoc = await db.collection('timovi').doc('sljedece').get();
    if (!nextDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Next round not found!")),
      );
      return;
    }

    final nextData = nextDoc.data();

    // ——————————————————————————
    // 2. Prebacimo SLJEDEĆE → AKTIVNO
    // ——————————————————————————
    await db.collection('timovi').doc('aktivni').set(nextData!);

    // ——————————————————————————
    // 3. Učitamo sve korisnike
    // ——————————————————————————
    final usersSnap = await db.collection('users').get();

    // ——————————————————————————
    // 4. Brišemo tipove i roundScore
    // ——————————————————————————
    for (var doc in usersSnap.docs) {
      await doc.reference.update({
        'tip1': FieldValue.delete(),
        'tip2': FieldValue.delete(),
        'tip3': FieldValue.delete(),
        'tip4': FieldValue.delete(),
        'roundScore': FieldValue.delete(),
      });
    }

    // ——————————————————————————
    // 5. Brišemo scored_ markere starog kola
    // ——————————————————————————
    for (var doc in usersSnap.docs) {
      final data = doc.data();
      Map<String, dynamic> updates = {};

      for (var key in data.keys) {
        if (key.startsWith("scored_")) {
          updates[key] = FieldValue.delete();
        }
      }

      if (updates.isNotEmpty) {
        await doc.reference.update(updates);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Round resetovan!")),
    );
  }

  // ================================
  //           BUILD UI
  // ================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (!_isAdmin(user)) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Unauthorized",
            style: TextStyle(color: Colors.red, fontSize: 24),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF022904),
      appBar: AppBar(
        backgroundColor: const Color(0xFF022904),
        title: const Text(
          "DoublePick ADMIN",
          style: TextStyle(color: Colors.yellow),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _calculateRound(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Calculate ROUND"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _resetRound(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Reset ROUND"),
            ),
          ],
        ),
      ),
    );
  }
}
