import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Logout
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  // Delete account completely (Auth + Firestore)
  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("This will permanently delete your account and all your data."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 1️⃣ Delete all user data from Firestore
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final classesCollection = userDoc.collection('classes');
      final classesSnapshot = await classesCollection.get();

      for (var classDoc in classesSnapshot.docs) {
        final studentsSnapshot = await classDoc.reference.collection('students').get();
        for (var student in studentsSnapshot.docs) {
          await student.reference.delete();
        }
        await classDoc.reference.delete();
      }

      await userDoc.delete();

      // 2️⃣ Delete Firebase Auth user
      await user.delete();

      // 3️⃣ Redirect to login screen
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account and all data deleted successfully")));
    } catch (e) {
      // If the user needs recent login
      if (e.toString().contains("requires-recent-login")) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Please log out and log back in before deleting your account.")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            // Logged-in user info
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? "Unknown User",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const Text("Tap to view profile",
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            const Divider(),

            // Profile
            ListTile(
              leading: const Icon(Iconsax.user),
              title: const Text("Profile"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(context, "/profile");
              },
            ),

            // Notifications
            ListTile(
              leading: const Icon(Iconsax.notification),
              title: const Text("Notifications"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),

            // Privacy
            ListTile(
              leading: const Icon(Iconsax.lock),
              title: const Text("Privacy"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),

            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Iconsax.logout4, color: Colors.red),
              title:
                  const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context),
            ),

            // Delete Account
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text("Delete Account"),
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
