import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoundStandingsScreen extends StatefulWidget {
  const RoundStandingsScreen({super.key});

  @override
  State<RoundStandingsScreen> createState() => _RoundStandingsScreenState();
}

class _RoundStandingsScreenState extends State<RoundStandingsScreen> {
  List<Map<String, dynamic>> _roundUsers = [];
  bool _loading = true;

  int? _myRoundPosition;

  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBanner();
    _loadRoundStandings();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6791458589312613/3522917422',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<void> _loadRoundStandings() async {
    final db = FirebaseFirestore.instance;

    final roundDoc = await db.collection('timovi').doc('aktivni').get();
    if (!roundDoc.exists) {
      setState(() => _loading = false);
      return;
    }

    final r = roundDoc.data()!;
    String rez1 = r['stvarnirezultat1'] ?? "";
    String rez2 = r['stvarnirezultat2'] ?? "";
    String rez3 = r['stvarnirezultat3'] ?? "";
    String rez4 = r['stvarnirezultat4'] ?? "";

    if ([rez1, rez2, rez3, rez4].any((e) => e.isEmpty)) {
      setState(() => _loading = false);
      return;
    }

    int r1 = int.parse(rez1);
    int r2 = int.parse(rez2);
    int r3 = int.parse(rez3);
    int r4 = int.parse(rez4);

    final usersSnap = await db.collection('users').get();
    List<Map<String, dynamic>> list = [];

    for (var doc in usersSnap.docs) {
      final d = doc.data();

      String ime = d['ime'] ?? "";
      String prezime = d['prezime'] ?? "";

      String t1 = d['tip1']?.toString() ?? "";
      String t2 = d['tip2']?.toString() ?? "";
      String t3 = d['tip3']?.toString() ?? "";
      String t4 = d['tip4']?.toString() ?? "";

      int m1 = 0;
      int m2 = 0;

      if ([t1, t2, t3, t4].every((e) => e.isNotEmpty)) {
        int tip1 = int.parse(t1);
        int tip2 = int.parse(t2);
        int tip3 = int.parse(t3);
        int tip4 = int.parse(t4);

        bool exact1 = tip1 == r1 && tip2 == r2;
        bool exact2 = tip3 == r3 && tip4 == r4;

        bool outcome1 = _sameOutcome(tip1, tip2, r1, r2);
        bool outcome2 = _sameOutcome(tip3, tip4, r3, r4);

        m1 = exact1 ? 15 : (outcome1 ? 5 : 0);
        m2 = exact2 ? 15 : (outcome2 ? 5 : 0);
      }

      int total = m1 + m2;
      if (m1 == 15 && m2 == 15) total += 15;

      list.add({
        'uid': doc.id,
        'ime': ime,
        'prezime': prezime,
        'm1': m1,
        'm2': m2,
        'total': total,
      });
    }

    list.sort((a, b) => b['total'].compareTo(a['total']));

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null) {
      for (int i = 0; i < list.length; i++) {
        if (list[i]['uid'] == myUid) {
          _myRoundPosition = i + 1;
          break;
        }
      }
    }

    setState(() {
      _roundUsers = list;
      _loading = false;
    });
  }

  bool _sameOutcome(int a, int b, int x, int y) {
    int sign(int d) => d > 0 ? 1 : (d < 0 ? -1 : 0);
    return sign(a - b) == sign(x - y);
  }

  String _iconForRank(int pos) {
    if (pos == 1) return "🥇";
    if (pos == 2) return "🥈";
    if (pos == 3) return "🥉";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022904),

      appBar: AppBar(
        backgroundColor: const Color(0xFF022904),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DoublePick',
          style: TextStyle(
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "ROUND RANK",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          const SizedBox(height: 8),

          if (_roundUsers.isNotEmpty)
            Text(
              "Winner: ${_roundUsers.first['ime']} ${_roundUsers.first['prezime']}",
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 12),

          Expanded(
            child: Card(
              color: const Color(0xFFFFF59D),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListView.builder(
                itemCount: _roundUsers.length,
                itemBuilder: (context, index) {
                  final u = _roundUsers[index];
                  final pos = index + 1;

                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: u['uid'],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: (_myRoundPosition == pos)
                            ? Colors.green.shade200
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$pos. ${u['ime']} ${u['prezime']}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,     // ✔ crno
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _iconForRank(pos),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Match 1: ${u['m1']} pts",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,   // ✔ crno
                                ),
                              ),
                              Text(
                                "Match 2: ${u['m2']} pts",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,   // ✔ crno
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),
                          Text(
                            "Total: ${u['total']} pts",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,     // ✔ crno
                            ),
                          ),
                          const Divider(height: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if (_myRoundPosition != null)
            Text(
              "Your round position: $_myRoundPosition / ${_roundUsers.length}",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 10),



          const SizedBox(height: 10),
        ],
      ),

      bottomNavigationBar: _bannerAd == null
          ? null
          : Container(
        height: _bannerAd!.size.height.toDouble(),
        color: Colors.black,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
