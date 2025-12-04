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

      // ✅ SVE IDE U BODY
      body: Column(
        children: [
          const SizedBox(height: 15),

          // ✅ NAZIV LIGE U BODY
          Text(
            _league?['name'] ?? 'League',
            style: const TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 15),

          // ✅ LISTA ČLANOVA
          Expanded(
            child: _members.isEmpty
                ? const Center(
              child: Text(
                "No members yet",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final user = _members[index];
                final rank = index + 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: user['uid'],
                      );
                    },
                    leading: Text(
                      "#$rank",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      "${user['ime']} ${user['prezime']}",
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Text(
                      user['score'].toString(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
