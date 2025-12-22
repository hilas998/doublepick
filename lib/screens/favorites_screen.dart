import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _global = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Load favorites
    final favSnap = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(currentUserId)
        .collection('favoritedUsers')
        .get();

    final favorites = favSnap.docs.map((doc) => doc.data()).toList();

    // Load global users for ranking
    final allSnap = await FirebaseFirestore.instance
        .collection('users')
        .get();

    final allUsers = allSnap.docs.map((doc) {
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

    allUsers.sort((a, b) => b['score'].compareTo(a['score']));

    // Match rank & score
    for (var fav in favorites) {
      final index = allUsers.indexWhere((u) => u['uid'] == fav['uid']);
      fav['rank'] = index == -1 ? null : index + 1;
      fav['score'] = index == -1 ? 0 : allUsers[index]['score'];
    }

    // Sort favorites by score too (top first)
    favorites.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    setState(() {
      _favorites = favorites;
      _global = allUsers;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A), // svjetlija tamno zelena
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
          const SizedBox(height: 12),
          const Text(
            "MY FAVORITES",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEFFF8A),
              shadows: [
                Shadow(color: Colors.yellow, blurRadius: 12),
              ],
          ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _favorites.isEmpty
                ? const Center(
              child: Text(
                "No favorites yet",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final user = _favorites[index];

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + index * 100),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade100.withOpacity(0.95),
                          Colors.yellow.shade200.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pushNamed(context, '/profile', arguments: user['uid']);
                      },
                      leading: Text(
                        "#${user['rank'] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      title: Text(
                        "${user['ime']} ${user['prezime']}",
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user['score'].toString(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.orange),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


}
