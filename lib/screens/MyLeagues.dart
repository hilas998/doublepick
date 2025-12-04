import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyLeaguesScreen extends StatefulWidget {
  const MyLeaguesScreen({super.key});

  @override
  State<MyLeaguesScreen> createState() => _MyLeaguesScreenState();
}

class _MyLeaguesScreenState extends State<MyLeaguesScreen> {
  Map<String, dynamic>? _myLeague; // Liga gdje je admin
  List<Map<String, dynamic>> _memberLeagues = []; // Lige gdje je član

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    _myLeague = null;
    _memberLeagues.clear();

    // 🔹 1. Liga gdje je korisnik admin
    final myLeagueQuery = await FirebaseFirestore.instance
        .collection('leagues')
        .where('adminUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (myLeagueQuery.docs.isNotEmpty) {
      final doc = myLeagueQuery.docs.first;
      _myLeague = doc.data();
      _myLeague!['docId'] = doc.id;
    }

    // 🔹 2. Lige gdje je korisnik član (ali nije admin)
    final allDocs = await FirebaseFirestore.instance.collection('leagues').get();

    List<Map<String, dynamic>> memberLeagues = [];

    for (var doc in allDocs.docs) {
      final data = doc.data();

      // Provjera stare strukture: members: [{ uid: ..., email: ...}]
      if (data.containsKey('members')) {
        final List memberObjects = data['members'];
        final bool isMember = memberObjects.any((m) => m['uid'] == uid);

        if (isMember && data['adminUid'] != uid) {
          data['docId'] = doc.id;
          memberLeagues.add(data);
        }
      }

      // Provjera nove strukture: memberUids: ["uid1", "uid2"]
      try {
        final List<String> members = List<String>.from(data['memberUids']);

        if (members.contains(uid) && data['adminUid'] != uid) {
          data['docId'] = doc.id;
          memberLeagues.add(data);
        }
      } catch (_) {}
    }

    setState(() {
      _memberLeagues = memberLeagues;
    });
  }

  Future<void> _createLeague() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final email = FirebaseAuth.instance.currentUser!.email ?? '';
    final leagueNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create League"),
        content: TextField(
          controller: leagueNameController,
          decoration: const InputDecoration(hintText: "League name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (leagueNameController.text.isEmpty) return;

              final newLeague = {
                'name': leagueNameController.text,
                'adminUid': uid,
                'members': [
                  {'uid': uid, 'email': email}
                ],
                'memberUids': [uid],
              };

              await FirebaseFirestore.instance
                  .collection('leagues')
                  .add(newLeague);

              Navigator.pop(ctx);
              _loadLeagues();
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "MY LEAGUES",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Admin liga
            if (_myLeague == null)
              ElevatedButton.icon(
                onPressed: _createLeague,
                icon: const Icon(Icons.add),
                label: const Text("Create League"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
              )
            else
              Card(
                color: Colors.yellow[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/leagueDetail',
                      arguments: _myLeague!['docId'],
                    );
                  },
                  title: Text(
                    _myLeague!['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/adminLeague',
                        arguments: _myLeague!['docId'],
                      );
                    },
                    child: const Text("Admin League"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 🔹 Lige gdje je član
            if (_memberLeagues.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _memberLeagues.length,
                  itemBuilder: (context, index) {
                    final league = _memberLeagues[index];
                    return Card(
                      color: Colors.yellow[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/leagueDetail',
                            arguments: league['docId'],
                          );
                        },
                        title: Text(
                          league['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
