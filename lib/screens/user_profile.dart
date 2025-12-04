import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatelessWidget {
  final String uid;

  const UserProfileScreen({super.key, required this.uid});

  Future<Map<String, dynamic>?> _getUser() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
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

      body: FutureBuilder(
        future: _getUser(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          final u = snap.data;
          if (u == null) {
            return const Center(
              child: Text(
                "User not found",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: const Color(0xFFFFF59D),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // PROFIL ZAGLAVLJE
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.black26,
                          child: Icon(Icons.person, size: 42, color: Colors.black),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            "${u['ime'] ?? ''} ${u['prezime'] ?? ''}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.black54),

                    // EMAIL
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.black),
                      title: const Text("Email", style: TextStyle(color: Colors.black)),
                      subtitle: Text(
                        u['email'] ?? "N/A",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),

                    // TOTAL SCORE
                    ListTile(
                      leading: const Icon(Icons.star, color: Colors.black),
                      title: const Text("Total Score", style: TextStyle(color: Colors.black)),
                      subtitle: Text(
                        "${u['score'] ?? "0"}",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),

                    const Divider(color: Colors.black54, height: 30),

                    // RECENT PREDICTIONS TITLES
                    const Text(
                      "Recent Predictions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _predictionTile("Match 1", u['tip1'], u['tip2']),
                    _predictionTile("Match 2", u['tip3'], u['tip4']),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _predictionTile(String title, dynamic home, dynamic away) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            "${home ?? "-"} : ${away ?? "-"}",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
