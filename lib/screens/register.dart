import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'invite_code.dart';

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

    String generateInviteCode(String uid) {
      return uid.substring(0, 6).toUpperCase(); // uzimamo 6 karaktera iz UID
    }

    if (ime.isEmpty) return _show("Enter name");
    if (prezime.isEmpty) return _show("Enter surname");


    final mobRegex = RegExp(r"^[0-9]{9,15}$"); // minimalno 9, maksimalno 15 cifara
    if (!mobRegex.hasMatch(mobitel)) return _show("Enter valid mobile number");


    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) return _show("Enter valid email");


    if (email.isEmpty || email.length < 12) return _show("Enter valid email");


    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*])[A-Za-z\d!@#$%^&*]{6,}$'
    );

    if (!passwordRegex.hasMatch(password)) {
      return _show(
          "Password must have at least 6 characters, including uppercase, lowercase and a special character (!@#\$%^&*)"
      );
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
        "inviteCode": generateInviteCode(uid),
        "usedInviteCode": false,

      };

      await _fStore.collection("users").doc(uid).set(userData);
      await user.sendEmailVerification();
      await _tryRedeemReferral(uid);

      _show("Registration successful, verification email sent");

      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => InviteCodeScreen(userId: uid))
        );
      }

    } on FirebaseAuthException catch (e) {
      _show("Error: ${e.message}");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ime.dispose();
    _prezime.dispose();
    _mobitel.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFF00150A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // ===== TITLE =====
              const Text(
                "DoublePick",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEFFF8A),
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 40),

              // ===== REGISTER CARD =====
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22E58B).withOpacity(0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(2.5),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withOpacity(0.92),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00150A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _input(_ime, Icons.person, hint: "Name"),
                      const SizedBox(height: 14),
                      _input(_prezime, Icons.person, hint: "Surname"),
                      const SizedBox(height: 14),
                      _input(
                        _mobitel,
                        Icons.phone,
                        hint: "Mobile",
                        type: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _input(
                        _email,
                        Icons.email_outlined,
                        hint: "Email",
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _input(
                        _password,
                        Icons.lock,
                        hint: "Password",
                        obscure: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ===== REGISTER BUTTON =====
              _loading
                  ? const CircularProgressIndicator(color: Color(0xFFEFFF8A))
                  : GestureDetector(
                onTap: _register,
                child: Container(
                  height: 58,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        const Color(0xFF22E58B).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "← Back to Login",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
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

  Widget _input(
      TextEditingController controller,
      IconData icon, {
        required String hint,
        bool obscure = false,
        TextInputType type = TextInputType.text,
      }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22E58B).withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2.2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF00150A),
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: Color(0xFF22E58B)),
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF22E58B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }



}
