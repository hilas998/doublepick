import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
 // BannerAd? _bannerAd;
  List<Map<String, dynamic>> _users = [];
  int? _myPosition;

  @override
  void initState() {
    super.initState();
    //_loadBanner();
    _loadLeaderboard();
  }

 /* void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6791458589312613/3522917422',
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
  }*/

  Future<void> _loadLeaderboard() async {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final currentEmail = auth.currentUser?.email ?? "";

    final snapshot = await db.collection('users').get();
    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      final scoreStr = data['score']?.toString() ?? '0';
      final score = int.tryParse(scoreStr) ?? 0;
      return {
        'ime': data['ime'] ?? '',
        'prezime': data['prezime'] ?? '',
        'email': data['email'] ?? '',
        'score': score,
      };
    }).toList();

    users.sort((a, b) => b['score'].compareTo(a['score']));

    int? myPos;
    for (int i = 0; i < users.length; i++) {
      if (users[i]['email'] == currentEmail) {
        myPos = i + 1;
        break;
      }
    }

    setState(() {
      _users = users;
      _myPosition = myPos;
    });
  }

  @override
  void dispose() {
   // _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022904),
      appBar: AppBar(
        backgroundColor: const Color(0xFF022904),
        centerTitle: true,
        title: Text(
          'DoublePick',
          style: TextStyle(
            color: Colors.yellow, // Žuti naslov
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "GLOBAL RANK",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Card(
              color: const Color(0xFFFFF59D),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: _users.isEmpty
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final rank = index + 1;
                  final isMe = _myPosition == rank;
                  return Container(
                    color: isMe ? Colors.green.shade200 : null,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$rank. ${user['ime']} ${user['prezime']}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          "${user['score']}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_myPosition != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Your position: $_myPosition / ${_users.length}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Nazad"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

}
