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

  // Dropdown
  int _selectedRound = 1;
  int _totalRounds = 1;

  @override
  void initState() {
    super.initState();
    _loadBanner();
    _loadTotalRounds();
    _loadRoundStandings(_selectedRound);
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

  Future<void> _loadTotalRounds() async {
    final metaDoc = await FirebaseFirestore.instance.collection('meta').doc('config').get();
    setState(() {
      _totalRounds = metaDoc.data()?['currentRound'] ?? 1;
    });
  }

  Future<void> _loadRoundStandings(int roundNumber) async {
    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;
    final doc = await db.collection('rounds').doc('round_$roundNumber').get();

    if (!doc.exists) {
      setState(() {
        _roundUsers = [];
        _myRoundPosition = null;
        _loading = false;
      });
      return;
    }

    final users = List<Map<String, dynamic>>.from(doc.data()!['users']);
    users.sort((a, b) => b['total'].compareTo(a['total']));

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    int? myPos;
    if (myUid != null) {
      for (int i = 0; i < users.length; i++) {
        if (users[i]['uid'] == myUid) {
          myPos = i + 1;
          break;
        }
      }
    }

    setState(() {
      _roundUsers = users;
      _myRoundPosition = myPos;
      _loading = false;
    });
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
      backgroundColor: const Color(0xFF00150A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00150A),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF44FF96)),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFEFFF8A)),
      )
          : Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            "ROUND RANK",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFFEFFF8A),
                shadows: [
                  Shadow(color: Colors.yellow, blurRadius: 12),
                ],
          ),
          ),
          const SizedBox(height: 8),

          // Dropdown za izbor kola
          if (_totalRounds > 0)
            Center(
              child: Container(
                width: 140, // manja širina
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22E58B).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedRound,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    dropdownColor: const Color(0xFF112309),
                   // plava pozadina kada se otvori
                    items: List.generate(_totalRounds, (index) {
                      int rn = index + 1;
                      return DropdownMenuItem(
                        value: rn,
                        child: Center(
                          child: Text(
                            "Round $rn",
                            style: const TextStyle(color: Colors.yellow),
                          ),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRound = val;
                        });
                        _loadRoundStandings(val);
                      }
                    },
                  ),
                ),
              ),
            ),


          const SizedBox(height: 14),

          if (_roundUsers.isNotEmpty)
            Text(
              "🏆 Winner: ${_roundUsers.first['ime']} ${_roundUsers.first['prezime']}",
              style: const TextStyle(
                color: Color(0xFF44FF96),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 14),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE9FFB1), Color(0xFFDFFF8E)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ListView.builder(
                itemCount: _roundUsers.length,
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final u = _roundUsers[index];
                  final pos = index + 1;
                  final bool isMe = _myRoundPosition == pos;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: u['uid'],
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isMe ? Colors.greenAccent.withOpacity(0.35) : Colors.white.withOpacity(0.6),
                        border: Border.all(
                          color: isMe ? Colors.green : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$pos. ${u['ime']} ${u['prezime']}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(_iconForRank(pos), style: const TextStyle(fontSize: 24)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Match 1: ${u['m1']} pts", style: const TextStyle(fontSize: 16, color: Colors.black)),
                              Text("Match 2: ${u['m2']} pts", style: const TextStyle(fontSize: 16, color: Colors.black)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Total: ${u['total']} pts",
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
          if (_myRoundPosition != null)
            Text(
              "Your round position: $_myRoundPosition / ${_roundUsers.length}",
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF44FF96),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 14),
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
