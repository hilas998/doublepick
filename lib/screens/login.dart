import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'register.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  final _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "User not found";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022904), // ista tamna pozadina kao Home
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== NASLOV =====
              Container(
                height: 80,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF022904),
                ),
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

              // ===== KARTICA =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  color: const Color(0xFFFFF59D), // ista žuta kao home header
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- EMAIL ---
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle:
                            const TextStyle(color: Colors.black87),
                            prefixIcon:
                            const Icon(Icons.email_outlined, color: Colors.black),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- PASSWORD ---
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle:
                            const TextStyle(color: Colors.black87),
                            prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.black),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ===== LOGIN BUTTON (CIRCLE) =====
              _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                onTap: _login,
                child: Container(
                  width: 65,
                  height: 65,
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
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 36,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== REGISTER BUTTON =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade600,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "You are new? Make your account",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== RESET PASSWORD =====
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Forgot your password?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
