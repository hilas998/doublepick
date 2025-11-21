import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'home.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _loading = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email sent successfully!")),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022904),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              // ===== NASLOV =====
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

              const SizedBox(height: 35),

              // ===== KARTICA =====
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
                        const Text(
                          "Reset password",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // *** SEND EMAIL BUTTON ***
                        _loading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow.shade700,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _resetPassword,
                          child: const Text(
                            "Send reset email",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // *** RETURN / SIGN IN LINKS ***
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "← Back to Login",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== OPTIONAL BACK TO HOME BUTTON =====
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow.shade700,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(140, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: const Text(
                  "Back to Home",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
