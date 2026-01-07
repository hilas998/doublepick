import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeagueLeaderboardScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;

  const LeagueLeaderboardScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  State<LeagueLeaderboardScreen> createState() =>
      _LeagueLeaderboardScreenState();
}

class _LeagueLeaderboardScreenState extends State<LeagueLeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> standings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeagueStandings();
  }

  Future<void> _loadLeagueStandings() async {
    setState(() => loading = true);

    try {
      // Čitanje direktno iz dokumenta koji predstavlja ligu
      final doc = await _firestore
          .collection('leagueStandings')
          .doc(widget.leagueName.toLowerCase().replaceAll(' ', ''))
          .get();

      if (!doc.exists) {
        setState(() {
          standings = [];
          loading = false;
        });
        return;
      }

      final data = doc.data();
      final users = data?['users'] ?? [];

      // Pretvori u List<Map<String,dynamic>>
      final temp = List<Map<String, dynamic>>.from(users);

      // Sortiraj po bodovima
      temp.sort((a, b) => b['total'].compareTo(a['total']));

      setState(() {
        standings = temp;
        loading = false;
      });
    } catch (e) {
      debugPrint("Leaderboard error: $e");
      setState(() => loading = false);
    }
  }


  // ===== MEDAL ICON =====
  Widget _medalIcon(int rank) {
    if (rank == 1) {
      return const Text("🥇", style: TextStyle(fontSize: 26));
    } else if (rank == 2) {
      return const Text("🥈", style: TextStyle(fontSize: 26));
    } else if (rank == 3) {
      return const Text("🥉", style: TextStyle(fontSize: 26));
    }
    return Text(
      "#$rank",
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    );
  }

  // ===== CARD GRADIENT =====
  Gradient _rankGradient(int rank) {
    if (rank == 1) {
      return const LinearGradient(
        colors: [Color(0xFFFFE066), Color(0xFFFFC107)],
      );
    } else if (rank == 2) {
      return const LinearGradient(
        colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
      );
    } else if (rank == 3) {
      return const LinearGradient(
        colors: [Color(0xFFD7A86E), Color(0xFFB87333)],
      );
    }
    return const LinearGradient(
      colors: [Colors.white, Colors.white],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00150A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF44FF96)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "DoublePick",
          style: TextStyle(
            color: Color(0xFFEFFF8A),
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 12),
          Text(
            widget.leagueName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEFFF8A),
              shadows: [
                Shadow(color: Colors.yellow, blurRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: standings.length,
              itemBuilder: (context, index) {
                final user = standings[index];
                final rank = index + 1;

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: _rankGradient(rank),
                    boxShadow: rank <= 3
                        ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      )
                    ]
                        : [],
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    leading: _medalIcon(rank),
                    title: Text(
                      "${user['ime']} ${user['prezime']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    trailing: Text(
                      user['total'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
    onTap: () {
    Navigator.pushNamed(
    context,
    '/profile',
    arguments: user['uid'],
    );
    },




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
