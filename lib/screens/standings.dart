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
      backgroundColor: const Color(0xFF00150A),

      bottomNavigationBar: _bannerAd == null
          ? null
          : SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),

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

      body: Column(
        children: [
          const SizedBox(height: 10),

          const Text(
            "GLOBAL RANK",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEFFF8A),
              shadows: [
                Shadow(color: Colors.yellow, blurRadius: 12),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Color(0xFF00150A), fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Search by name...",
                  hintStyle: const TextStyle(color: Color(0xFF00150A)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00150A)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // RANK LIST
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: _filteredUsers.isEmpty
                  ? const Center(
                child: Text(
                  "No results",
                  style: TextStyle(color: Colors.black87, fontSize: 18),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final rank = _users.indexWhere((u) => u['uid'] == user['uid']) + 1;
                  final isMe = _myPosition == rank;

                  return InkWell(
                    onTap: () => Navigator.pushNamed(context, '/profile', arguments: user['uid']),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.greenAccent.withOpacity(0.25) : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ⭐ FAVORITE BUTTON
                          IconButton(
                            icon: Icon(
                              _favoriteIds.contains(user['uid']) ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.orange.shade700,
                              size: 28,
                            ),
                            onPressed: () => _toggleFavorite(user),
                          ),

                          // RANK + ICON
                          Text(
                            "${_iconForRank(rank)} $rank.",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // NAME
                          Expanded(
                            child: Text(
                              "${user['ime']} ${user['prezime']}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // SCORE + BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF44FF96), Color(0xFFEFFF8A)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [

                                const SizedBox(width: 6),
                                Text(
                                  "${user['score']}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // MY POSITION
          if (_myPosition != null)
            Text(
              "Your position: $_myPosition / ${_users.length}",
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF44FF96),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),

          // FAVORITES BUTTON
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
            icon: const Icon(Icons.star_rounded, color: Colors.white),
            label: const Text("MY FAVORITES"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          // MY LEAGUES BUTTON
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/myLeagues'),
            icon: const Icon(Icons.sports_soccer, color: Colors.white),
            label: const Text("MY LEAGUES"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8CC0FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

}
