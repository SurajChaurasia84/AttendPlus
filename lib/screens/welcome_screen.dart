import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/animated_gradient_button.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _onGetStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(), // ⬆️ top spacing

              // 🖼️ Image (FIXED HEIGHT)
              SizedBox(
                height: 200,
                child: Image.asset(
                  'assets/src/welcome.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // 📝 Title
              const Text(
                'Welcome to Attend Plus',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // 📄 Description
              const Text(
                'Take attendance digitally, manage classes easily, '
                'and track student performance in one smart app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // 🚀 Get Started Button
              AnimatedGradientButton(
                text: 'Get Started',
                onPressed: () => _onGetStarted(context),
              ),

              const Spacer(flex: 2), // ⬇️ bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}
