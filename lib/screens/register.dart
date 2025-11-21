import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _ime = TextEditingController();
  final _prezime = TextEditingController();
  final _mobitel = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  final _auth = FirebaseAuth.instance;
  final _fStore = FirebaseFirestore.instance;

  Future<void> _register() async {
    final ime = _ime.text.trim();
    final prezime = _prezime.text.trim();
    final mobitel = _mobitel.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (ime.isEmpty) return _show("Enter name");
    if (prezime.isEmpty) return _show("Enter surname");
    if (mobitel.isEmpty || mobitel.length < 9) {
      return _show("Enter valid mobile number");
    }
    if (email.isEmpty || email.length < 12) return _show("Enter valid email");
    if (password.isEmpty || password.length < 6) {
      return _show("Password must be at least 6 characters");
    }

    setState(() => _loading = true);

    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = userCred.user;
      if (user == null) return;

      final uid = user.uid;
      final userData = {
        "ime": ime,
        "prezime": prezime,
        "email": email,
        "mobitel": mobitel,
        "password": password,
        "userIDText": uid,
        "score": "0",
        "referralUsed": false,
        "referredBy": null,
      };

      await _fStore.collection("users").doc(uid).set(userData);
      await user.sendEmailVerification();
      await _tryRedeemReferral(uid);

      _show("Registration successful, verification email sent");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _show("Error: ${e.message}");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _tryRedeemReferral(String newUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final referralUid = prefs.getString("referral_uid");
    if (referralUid == null || referralUid == newUserId) return;

    final inviterRef = _fStore.collection("users").doc(referralUid);
    final referralRecordRef = _fStore.collection("referrals").doc(newUserId);
    final inviteeRef = _fStore.collection("users").doc(newUserId);

    await _fStore.runTransaction((transaction) async {
      final existing = await transaction.get(referralRecordRef);
      if (existing.exists) return;

      final inviterSnap = await transaction.get(inviterRef);
      if (!inviterSnap.exists) return;

      int currentScore = 0;
      final scoreField = inviterSnap.data()?["score"];
      if (scoreField is String) {
        currentScore = int.tryParse(scoreField) ?? 0;
      } else if (scoreField is int) {
        currentScore = scoreField;
      }

      transaction.set(referralRecordRef, {
        "inviterId": referralUid,
        "inviteeId": newUserId,
        "timestamp": FieldValue.serverTimestamp(),
      });

      transaction.update(inviterRef, {"score": (currentScore + 10).toString()});
      transaction.update(inviteeRef, {
        "referralUsed": true,
        "referredBy": referralUid,
      });
    });

    await prefs.remove("referral_uid");
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022904),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== NASLOV ======
              Container(
                height: 80,
                width: double.infinity,
                alignment: Alignment.center,
                child: const Text(
                  "DoublePick",
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ===== KARTICA ======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  color: const Color(0xFFFFF59D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(26.0),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Create account",
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _input(_ime, "Name", Icons.person),
                        const SizedBox(height: 12),

                        _input(_prezime, "Surname", Icons.person),
                        const SizedBox(height: 12),

                        _input(_mobitel, "Mobile", Icons.phone,
                            type: TextInputType.number),
                        const SizedBox(height: 12),

                        _input(_email, "Email", Icons.email),
                        const SizedBox(height: 12),

                        _input(_password, "Password", Icons.lock,
                            obscure: true),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ===== CIRCLE REGISTER BUTTON =====
              _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                onTap: _register,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellow.shade700,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child:
                  const Icon(Icons.arrow_forward, size: 36, color: Colors.black),
                ),
              ),

              const SizedBox(height: 16),

              // ===== BACK TO LOGIN =====
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "← Back to Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ====== INPUT POLJA ======
  Widget _input(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
