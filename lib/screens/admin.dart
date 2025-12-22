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

    // 🔹 Učitaj aktivno kolo
    final roundDoc = await db.collection('timovi').doc('aktivni').get();
    if (!roundDoc.exists) return;

    final r = roundDoc.data()!;
    final rez = [
      r['stvarnirezultat1'],
      r['stvarnirezultat2'],
      r['stvarnirezultat3'],
      r['stvarnirezultat4'],
    ];

    if (rez.any((e) => e == null || e.toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unesi sve rezultate!")),
      );
      return;
    }

    final r1 = int.parse(rez[0].toString());
    final r2 = int.parse(rez[1].toString());
    final r3 = int.parse(rez[2].toString());
    final r4 = int.parse(rez[3].toString());

    // 🔹 Dohvati broj kola
    final metaRef = db.collection('meta').doc('config');
    final metaSnap = await metaRef.get();
    int roundNumber = (metaSnap.data()?['currentRound'] ?? 0) + 1;

    final usersSnap = await db.collection('users').get();
    List<Map<String, dynamic>> standings = [];

    for (var doc in usersSnap.docs) {
      final d = doc.data();

      String t1 = d['tip1']?.toString() ?? "";
      String t2 = d['tip2']?.toString() ?? "";
      String t3 = d['tip3']?.toString() ?? "";
      String t4 = d['tip4']?.toString() ?? "";

      int m1 = 0;
      int m2 = 0;

      int tip1 = t1.isNotEmpty ? int.parse(t1) : -1;
      int tip2 = t2.isNotEmpty ? int.parse(t2) : -1;
      int tip3 = t3.isNotEmpty ? int.parse(t3) : -1;
      int tip4 = t4.isNotEmpty ? int.parse(t4) : -1;

      if ([tip1, tip2, tip3, tip4].every((e) => e != -1)) {
        bool exact1 = tip1 == r1 && tip2 == r2;
        bool exact2 = tip3 == r3 && tip4 == r4;

        bool outcome1 = _sameOutcome(tip1, tip2, r1, r2);
        bool outcome2 = _sameOutcome(tip3, tip4, r3, r4);

        m1 = exact1 ? 15 : (outcome1 ? 5 : 0);
        m2 = exact2 ? 15 : (outcome2 ? 5 : 0);
      }

      int total = m1 + m2;
      if (m1 == 15 && m2 == 15) total += 15;

      // 🔹 Update global score
      int global = int.tryParse(d['score'] ?? '0') ?? 0;
      await doc.reference.update({
        'score': (global + total).toString(),
      });

      standings.add({
        'uid': doc.id,
        'ime': d['ime'],
        'prezime': d['prezime'],
        'm1': m1,
        'm2': m2,
        'total': total,
        'tip1': t1,
        'tip2': t2,
        'tip3': t3,
        'tip4': t4,
      });
    }

    standings.sort((a, b) => b['total'].compareTo(a['total']));

    // 🔹 Snimi kolo sa stvarnim rezultatima
    await db.collection('rounds').doc('round_$roundNumber').set({
      'roundNumber': roundNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'stvarniRezultati': {
        'r1': r1,
        'r2': r2,
        'r3': r3,
        'r4': r4,
      },
      'timovi': {
        'team1': r['team1'] ?? '',
        'team2': r['team2'] ?? '',
        'team3': r['team3'] ?? '',
        'team4': r['team4'] ?? '',


    },
      'users': standings,
    });

    await metaRef.set({'currentRound': roundNumber});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Round $roundNumber spremljen!")),
    );
  }



  bool _sameOutcome(int a, int b, int x, int y) {
    // Računa rezultat: da li je ishod isti
    int sign(int d) => d > 0 ? 1 : (d < 0 ? -1 : 0);
    return sign(a - b) == sign(x - y);
  }

  // ================================
  //            RESET ROUND
  // ================================

  Future<void> _resetRound(BuildContext context) async {
    final db = FirebaseFirestore.instance;

    // 1️⃣ Prebaci sljedeće u aktivne
    final nextDoc = await db.collection('timovi').doc('sljedece').get();
    if (!nextDoc.exists) return;

    await db.collection('timovi').doc('aktivni').set(nextDoc.data()!);

    // 2️⃣ Batch brisanje tipova
    final usersSnap = await db.collection('users').get();
    final batch = db.batch();

    for (var doc in usersSnap.docs) {
      batch.update(doc.reference, {
        'tip1': FieldValue.delete(),
        'tip2': FieldValue.delete(),
        'tip3': FieldValue.delete(),
        'tip4': FieldValue.delete(),
      });
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Round resetovan – tipovi obrisani svima")),
    );
  }








  Future<void> _resetSeason(BuildContext context) async {
    final db = FirebaseFirestore.instance;

    // Reset score
    final users = await db.collection('users').get();
    for (var doc in users.docs) {
      await doc.reference.update({'score': '0'});
    }

    // Briši sva kola
    final rounds = await db.collection('rounds').get();
    for (var doc in rounds.docs) {
      await doc.reference.delete();
    }

    // Reset counter
    await db.collection('meta').doc('config').set({'currentRound': 0});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sezona resetovana")),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            ElevatedButton(
              onPressed: () => _calculateRound(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                "Calculate ROUND",
                style: TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => _resetRound(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                "Reset ROUND",
                style: TextStyle(fontSize: 18),
              ),
            ),

            // ⬇️ gura RESET SEASON na dno
            const Spacer(),

            const Divider(
              color: Colors.white24,
              thickness: 1,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _resetSeason(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 22),
              ),
              child: const Text(
                "RESET SEASON",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}
