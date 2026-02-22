import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeagueDetailScreen extends StatefulWidget {
  const LeagueDetailScreen({super.key});

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen> {
  Map<String, dynamic>? _league;
  List<Map<String, dynamic>> _members = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adminUid = ModalRoute.of(context)!.settings.arguments as String;
    _loadLeague(adminUid);
  }

  Future<void> _loadLeague(String adminUid) async {
    final leagueSnap = await FirebaseFirestore.instance
        .collection('leagues')
        .doc(adminUid)
        .get();

    if (!leagueSnap.exists) return;

    final leagueData = leagueSnap.data()!;
    final members = leagueData['members'] as List<dynamic>;

    List<Map<String, dynamic>> memberData = [];

    for (var m in members) {
      final uid = m['uid'];
      final userSnap =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userSnap.exists) {
        final data = userSnap.data()!;
        memberData.add({
          'uid': uid,
          'ime': data['ime'] ?? '',
          'prezime': data['prezime'] ?? '',
          'score': int.tryParse(data['score']?.toString() ?? '0') ?? 0,
        });
      }
    }

    memberData.sort((a, b) => b['score'].compareTo(a['score']));

    setState(() {
      _league = leagueData;
      _members = memberData;
    });
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // NAZIV LIGE (fiksiran)
          // =========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: const Color(0xFF00150A),
            child: Text(
              _league?['name'] ?? 'League',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFEFFF8A),
                shadows: [
                  Shadow(color: Colors.yellow.withOpacity(0.4), blurRadius: 12),
                ],
              ),
            ),
          ),

          // =========================
          // SCROLLABLE SADRŽAJ
          // =========================
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Moderni “Standings League” button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                          context, '/standings',
                          arguments: _league?['id']);
                    },
                    icon: const Icon(Icons.emoji_events, color: Colors.black),
                    label: const Text(
                      "Standings League",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista članova
                  _members.isEmpty
                      ? const Center(
                    child: Text(
                      "No members yet",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final user = _members[index];
                      final rank = index + 1;

                      return TweenAnimationBuilder<double>(
                        duration:
                        Duration(milliseconds: 300 + index * 100),
                        curve: Curves.easeOut,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 50 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin:
                          const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade200.withOpacity(0.95),
                                Colors.yellow.shade200.withOpacity(0.85)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.greenAccent.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            onTap: () {
                              Navigator.pushNamed(
                                  context, '/profile',
                                  arguments: user['uid']);
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.greenAccent
                                  .shade400
                                  .withOpacity(0.9),
                              child: Text(
                                "#$rank",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              "${user['ime']} ${user['prezime']}",
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700
                                    .withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${user['score'] ?? 0} pts",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
