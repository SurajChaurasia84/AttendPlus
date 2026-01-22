import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Us")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /// HEADER
                const Text(
                  "Get in touch",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  "We’d love to hear from you. Reach out to us anytime.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                /// EMAIL CARD
                _infoCard(
                  icon: Iconsax.sms,
                  title: "Email Support",
                  subtitle: "support@attendplus.app",
                  onTap: () {
                    _launchEmail("support@attendplus.app");
                  },
                ),

                /// PHONE CARD
                _infoCard(
                  icon: Iconsax.call,
                  title: "Phone",
                  subtitle: "+91 9XXXXXXXXX",
                  onTap: () {
                    _launchPhone("+919999999999");
                  },
                ),

                /// WORKING HOURS
                _infoCard(
                  icon: Iconsax.clock,
                  title: "Working Hours",
                  subtitle: "Monday – Saturday\n10:00 AM – 5:00 PM",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// INFO CARD
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
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
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  /// EMAIL
  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// PHONE
  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
