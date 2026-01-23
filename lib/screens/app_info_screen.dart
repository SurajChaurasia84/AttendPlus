import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("App Info"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 APP HEADER
            Center(
              child: Column(
                children: [
                  Container(
                    height: 96,
                    width: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.chart_square,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "AttendPlus",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Attendance made simple & smart",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            /// 🧠 ABOUT APP
            const Text(
              "About the app",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "AttendPlus is a modern attendance management solution designed "
              "to help teachers and institutions manage classes, students, "
              "and attendance records efficiently with a clean and intuitive experience.",
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

            /// DEVELOPER INFO
            const SizedBox(height: 32),
            const Text(
              "Developer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: const ListTile(
                leading: Icon(Iconsax.building),
                title: Text(
                  "AttendPlus",
                  style: TextStyle(
                    // fontSize: 15,
                    color: Colors.indigo,
                  ),
                ),
                subtitle: Text("AttendPlus Technologies Pvt. Ltd.\nIndia"),
              ),
            ),
            const SizedBox(height: 28),

            /// 📦 APP DETAILS
            const Text(
              "App details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            _infoRow("Version", "1.1.0"),
            // _infoRow("Build", "100"),
            _infoRow("Platform", "Android"),

            const SizedBox(height: 30),

            /// ⚖️ COPYRIGHT
            Center(
              child: Text(
                "© 2026 AttendPlus\nAll rights reserved",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Color.fromARGB(255, 102, 102, 102)),
          ),
        ],
      ),
    );
  }
}
