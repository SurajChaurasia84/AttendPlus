import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool loading = false;

  // 🔹 SIGNUP FUNCTION
  Future signup() async {
    if (email.text.isEmpty || password.text.isEmpty || name.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ Create Firebase user
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      User user = userCred.user!;

      // 2️⃣ Save user info to Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": name.text.trim(),
        "email": email.text.trim(),
        "created": DateTime.now(),
        "verified": false,
      });

      // 3️⃣ Send verification email
      await user.sendEmailVerification();

      // 4️⃣ Navigate to verification screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EmailVerificationScreen(user: user)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ✅ SIGNUP IMAGE
              SizedBox(
                height: 200,
                child: Image.asset(
                  'assets/src/signup.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 TITLE
              const Text(
                "Create Account",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),

              // 🔹 NAME FIELD
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Iconsax.user),
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 EMAIL FIELD
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Iconsax.sms),
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 PASSWORD FIELD
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Iconsax.lock),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 SIGNUP BUTTON
              ElevatedButton(
                onPressed: loading ? null : signup,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Account"),
              ),

              const SizedBox(height: 20),

              // 🔹 LOGIN NAVIGATION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------- EMAIL VERIFICATION SCREEN ----------------
class EmailVerificationScreen extends StatefulWidget {
  final User user;
  const EmailVerificationScreen({super.key, required this.user});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late final Timer _timer;
  bool verified = false;

  @override
  void initState() {
    super.initState();
    // 🔹 Poll Firebase every 3 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkEmailVerified(),
    );
  }

  Future<void> checkEmailVerified() async {
    await widget.user.reload();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      setState(() => verified = true);
      _timer.cancel();

      // 🔹 Update Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"verified": true},
      );

      // 🔹 Navigate to Main App
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "/main", (route) => false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const SizedBox(height: 20),

            // ✅ IMAGE
            SizedBox(
              height: 200,
              child: Image.asset('assets/src/signup.png', fit: BoxFit.contain),
            ),

            const SizedBox(height: 20),
            const Text(
              "A verification link has been sent to your email.\nPlease verify to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // 🔹 RESEND BUTTON
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () async {
                  await widget.user.sendEmailVerification();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Verification email sent again"),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7925F6), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Resend Email",
                  style: TextStyle(
                    color: Color(0xFF7925F6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
