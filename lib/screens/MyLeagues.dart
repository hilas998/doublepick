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

    // 🔹 Liga gdje je korisnik admin
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

    // 🔹 Lige gdje je korisnik član (ali nije admin)
    final allDocs = await FirebaseFirestore.instance.collection('leagues').get();
    List<Map<String, dynamic>> memberLeagues = [];

    for (var doc in allDocs.docs) {
      final data = doc.data();

      // preskoči ako je admin
      if (data['adminUid'] == uid) continue;

      bool added = false;

      // Nova struktura
      if (data.containsKey('memberUids')) {
        final List<String> members = List<String>.from(data['memberUids']);
        if (members.contains(uid)) {
          data['docId'] = doc.id;
          memberLeagues.add(data);
          added = true;
        }
      }

      // Stara struktura
      if (!added && data.containsKey('members')) {
        final List memberObjects = data['members'];
        final bool isMember = memberObjects.any((m) => m['uid'] == uid);
        if (isMember) {
          data['docId'] = doc.id;
          memberLeagues.add(data);
        }
      }
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              "MY LEAGUES",
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

            // Kreiraj ligu ako nema admin lige
            if (_myLeague == null)
              ElevatedButton.icon(
                onPressed: _createLeague,
                icon: const Icon(Icons.add),
                label: const Text("Create League"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            else
              _leagueCard(_myLeague!, isAdmin: true),

            const SizedBox(height: 16),

            // Lige gdje je član
            if (_memberLeagues.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _memberLeagues.length,
                  itemBuilder: (context, index) {
                    final league = _memberLeagues[index];
                    return _leagueCard(league);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== Liga Card Widget =====
  Widget _leagueCard(Map<String, dynamic> league, {bool isAdmin = false}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: isAdmin
                ? [Colors.green.shade200.withOpacity(0.95), Colors.yellow.shade200.withOpacity(0.85)]
                : [Colors.green.shade100.withOpacity(0.9), Colors.yellow.shade100.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          onTap: () {
            Navigator.pushNamed(context, '/leagueDetail', arguments: league['docId']);
          },
          title: Text(
            league['name'] ?? '',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: isAdmin
              ? ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/adminLeague', arguments: league['docId']);
            },
            child: const Text("Admin League"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
          )
              : null,
        ),
      ),
    );
  }
}
