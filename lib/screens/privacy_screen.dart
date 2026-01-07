import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy & Terms"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Privacy Policy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "We respect your privacy and are committed to protecting your personal information. "
                "All data collected by the app, such as attendance records and profile information, "
                "is stored securely and only accessible by you. "
                "We do not share your data with third parties without your consent.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              const Text(
                "Terms of Service",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "By using this application, you agree to comply with all applicable laws and regulations. "
                "You are responsible for maintaining the confidentiality of your account and password. "
                "The app is provided 'as is' without warranties of any kind. "
                "We reserve the right to modify or terminate services at any time.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              const Text(
                "Usage Guidelines",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "1. Use the app only for legitimate educational purposes.\n"
                "2. Do not share your login credentials with others.\n"
                "3. Do not attempt to access or modify other users' data.\n"
                "4. Report any security issues to the app administrators immediately.\n"
                "5. Respect the privacy and rights of other users.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Optional: Accept Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("I Understand"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
