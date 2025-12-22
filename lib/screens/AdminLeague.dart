import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLeagueScreen extends StatefulWidget {
  const AdminLeagueScreen({super.key});

  @override
  State<AdminLeagueScreen> createState() => _AdminLeagueScreenState();
}

class _AdminLeagueScreenState extends State<AdminLeagueScreen> {
  Map<String, dynamic>? _league;
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final docId = ModalRoute.of(context)!.settings.arguments as String;
    _loadLeague(docId);
  }

  Future<void> _loadLeague(String docId) async {
    setState(() => _loading = true);
    final leagueSnap =
    await FirebaseFirestore.instance.collection('leagues').doc(docId).get();
    if (!leagueSnap.exists) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _league = leagueSnap.data()!..['docId'] = leagueSnap.id;
      _loading = false;
    });
  }

  Future<void> _addMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _league == null) return;

    setState(() => _loading = true);

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found")),
        );
        return;
      }

      final user = userSnap.docs.first;
      final uid = user.id;

      final members =
      List<Map<String, dynamic>>.from(_league!['members'] ?? []);
      final memberUids = List<String>.from(_league!['memberUids'] ?? []);

      if (members.any((m) => m['uid'] == uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User is already a member")),
        );
        return;
      }

      members.add({'uid': uid, 'email': email});
      memberUids.add(uid);

      await FirebaseFirestore.instance
          .collection('leagues')
          .doc(_league!['docId'])
          .update({
        'members': members,
        'memberUids': memberUids,
      });

      _emailController.clear();
      await _loadLeague(_league!['docId']);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeMember(int index) async {
    if (_league == null) return;

    setState(() => _loading = true);

    try {
      final members = List<Map<String, dynamic>>.from(_league!['members']);
      final memberUids = List<String>.from(_league!['memberUids']);

      final removedUid = members[index]['uid'];
      members.removeAt(index);
      memberUids.remove(removedUid);

      await FirebaseFirestore.instance
          .collection('leagues')
          .doc(_league!['docId'])
          .update({
        'members': members,
        'memberUids': memberUids,
      });

      await _loadLeague(_league!['docId']);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteLeague() async {
    if (_league == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete League"),
        content: const Text("Are you sure you want to delete this league?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('leagues')
        .doc(_league!['docId'])
        .delete();

    Navigator.pop(context); // Vrati nazad nakon brisanja
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A), // tamno-zelena, prijatno
      appBar: AppBar(
        backgroundColor: const Color(0xFF00150A),
        centerTitle: true,
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
        actions: [
          if (_league != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteLeague,
              tooltip: "Delete League",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.yellow),
        )
            : Column(
          children: [
            Text(
              _league?['name'] ?? 'Admin League',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFFEFFF8A),
                shadows: [
                  Shadow(color: Colors.yellow, blurRadius: 12),
                ],
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Enter user email",
                filled: true,
                fillColor: Colors.yellow[100]?.withOpacity(0.85),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: _addMember,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _league == null || (_league!['members'] as List).isEmpty
                  ? const Center(
                child: Text(
                  "No members yet",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              )
                  : ListView.builder(
                itemCount: (_league!['members'] as List).length,
                itemBuilder: (context, index) {
                  final member = (_league!['members'] as List)[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + index * 100),
                    curve: Curves.easeOut,
                    tween: Tween(begin: 0.0, end: 1.0),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade100.withOpacity(0.9),
                            Colors.yellow.shade100.withOpacity(0.85)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          member['email'] ?? '',
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeMember(index),
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
