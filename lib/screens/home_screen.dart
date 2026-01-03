import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error / no data
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Teacher data not found"));
          }

          // ✅ SAFE DATA
          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String name = data['name'] ?? 'Teacher';
          final String department = data['department'] ?? 'Department';
          final int totalClasses = data['totalClasses'] ?? 0;
          final int todayClasses = data['todayClasses'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👋 HEADER
                Text(
                  'Good day, $name 👨‍🏫',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  department,
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // 📅 TODAY STATUS CARD
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today,
                        color: Colors.indigo),
                    title: const Text("Today's Classes"),
                    subtitle: Text('$todayClasses scheduled'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),

                const SizedBox(height: 16),

                // 📊 OVERVIEW
                Row(
                  children: [
                    _infoCard(
                      title: 'Total Classes',
                      value: totalClasses.toString(),
                      icon: Icons.school,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 12),
                    _infoCard(
                      title: 'Today',
                      value: todayClasses.toString(),
                      icon: Icons.today,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ⚡ QUICK ACTIONS
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _actionButton(
                      icon: Icons.how_to_reg,
                      label: 'Take Attendance',
                      color: Colors.indigo,
                      onTap: () {
                        // TODO: Navigate to attendance screen
                      },
                    ),
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.people,
                      label: 'Students',
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Navigate to student list
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _actionButton(
                      icon: Icons.bar_chart,
                      label: 'Reports',
                      color: Colors.green,
                      onTap: () {
                        // TODO: Navigate to reports
                      },
                    ),
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.settings,
                      label: 'Settings',
                      color: Colors.grey,
                      onTap: () {
                        // TODO: Navigate to settings
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📊 INFO CARD
  static Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ⚡ ACTION BUTTON
  static Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
