import 'invite_code.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key, required this.userId});

  final String userId;

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool loading = false;

  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter invite code")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "If you were invited by a friend, enter the code below.\nYou and your friend will both receive 5 points.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Invite code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _submitCode,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Confirm"),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Text("Skip"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final uid = widget.userId;
    setState(() => loading = true);

    final meRef = firestore.collection('users').doc(uid);
    final meSnap = await meRef.get();
    if (meSnap['usedInviteCode'] == true) {
      _msg("Invite code already used");
      setState(() => loading = false);
      return;
    }

    final q = await firestore
        .collection('users')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      _msg("Invalid invite code");
      setState(() => loading = false);
      return;
    }

    final inviterDoc = q.docs.first;
    if (inviterDoc.id == uid) {
      _msg("You can't use your own code");
      setState(() => loading = false);
      return;
    }

    const bonus = 5;

    await firestore.runTransaction((tx) async {
      final inviterRef = inviterDoc.reference;

      final inviterSnap = await tx.get(inviterRef);
      final mySnap = await tx.get(meRef);

      final inviterScore =
          int.tryParse(inviterSnap['score'] ?? '0') ?? 0;
      final myScore = int.tryParse(mySnap['score'] ?? '0') ?? 0;

      tx.update(inviterRef, {"score": (inviterScore + bonus).toString()});
      tx.update(meRef, {
        "score": (myScore + bonus).toString(),
        "usedInviteCode": true,
        "referredBy": inviterDoc.id
      });
    });

    _msg("✅ Success! You received 5 points");
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }
}
