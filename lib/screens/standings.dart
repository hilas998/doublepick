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
  BannerAd? _bannerAd;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  int? _myPosition;

  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Set<String> _favoriteIds = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBanner();
    _loadLeaderboard();
    _loadFavorites();

    _searchController.addListener(_applySearch);
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6791458589312613/3522917422',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  Future<void> _loadFavorites() async {
    final snap = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(currentUserId)
        .collection('favoritedUsers')
        .get();

    setState(() {
      _favoriteIds = snap.docs.map((d) => d.id).toSet();
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> user) async {
    final uid = user['uid'];

    final ref = FirebaseFirestore.instance
        .collection('favorites')
        .doc(currentUserId)
        .collection('favoritedUsers')
        .doc(uid);

    if (_favoriteIds.contains(uid)) {
      await ref.delete();
      setState(() => _favoriteIds.remove(uid));
    } else {
      await ref.set({
        'uid': uid,
        'ime': user['ime'],
        'prezime': user['prezime'],
        'email': user['email'],
      });

      setState(() => _favoriteIds.add(uid));
    }
  }

  Future<void> _loadLeaderboard() async {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final currentEmail = auth.currentUser?.email ?? "";

    final snapshot = await db.collection('users').get();

    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      final score = int.tryParse(data['score']?.toString() ?? '0') ?? 0;

      return {
        'uid': doc.id,
        'ime': data['ime'] ?? '',
        'prezime': data['prezime'] ?? '',
        'email': data['email'] ?? '',
        'score': score,
      };
    }).toList();

    users.sort((a, b) => b['score'].compareTo(a['score']));

    int? pos;
    for (int i = 0; i < users.length; i++) {
      if (users[i]['email'] == currentEmail) {
        pos = i + 1;
      }
    }

    setState(() {
      _users = users;
      _filteredUsers = users;
      _myPosition = pos;
    });
  }

  void _applySearch() {
    final text = _searchController.text.toLowerCase();

    setState(() {
      _filteredUsers = _users.where((user) {
        final fullName = "${user['ime']} ${user['prezime']}".toLowerCase();
        return fullName.contains(text);
      }).toList();
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
      backgroundColor: const Color(0xFF022904),

      bottomNavigationBar: _bannerAd == null
          ? null
          : SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),

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

          // 🔎 SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.green.shade900,
                hintText: "Search by name...",
                hintStyle: const TextStyle(color: Colors.black),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
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
              child: _filteredUsers.isEmpty
                  ? const Center(child: Text("No results"))
                  : ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final rank = _users.indexWhere(
                          (u) => u['uid'] == user['uid']) +
                      1;

                  final isMe = _myPosition == rank;

                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: user['uid'],
                      );
                    },
                    child: Container(
                      color: isMe ? Colors.green.shade200 : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // ⭐ FAVORITE BUTTON
                          IconButton(
                            icon: Icon(
                              _favoriteIds.contains(user['uid'])
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                            ),
                            onPressed: () => _toggleFavorite(user),
                          ),

                          Text(
                            "$rank. ",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          Expanded(
                            child: Text(
                              "${user['ime']} ${user['prezime']}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          Row(
                            children: [
                              Text(
                                "${user['score']}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _iconForRank(rank),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
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
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },

            icon: const Icon(Icons.star),
            label: const Text("MY FAVORITES"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),


          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/myLeagues'),
            icon: const Icon(Icons.sports_soccer),
            label: const Text("MY LEAGUES"),
            style: ElevatedButton.styleFrom(
              backgroundColor:  Color(0xFF8CC0FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
