import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'feedback_screen.dart';
import 'contact_us_screen.dart';
import 'faq_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: Column(
        children: [
          /// MAIN CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Need help?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  "We’re here to help you with any issues or feedback.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                _helpTile(
                  context,
                  icon: Iconsax.message_text,
                  title: "Give Feedback",
                  subtitle: "Share your experience or suggestions",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                    );
                  },
                ),

                _helpTile(
                  context,
                  icon: Iconsax.call,
                  title: "Contact Us",
                  subtitle: "Get in touch with support",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ContactUsScreen(),
                      ),
                    );
                  },
                ),

                _helpTile(
                  context,
                  icon: Iconsax.message_question,
                  title: "FAQs",
                  subtitle: "Common questions & answers",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          /// FOOTER (FIXED BOTTOM)
        ],
      ),
    );
  }

  Widget _helpTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
