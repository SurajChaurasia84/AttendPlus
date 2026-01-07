import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _markAllRead();
  }

  /// 🔹 Mark all notifications as read
  Future<void> _markAllRead() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in snap.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      // Safe fallback if notifications collection doesn't exist
      debugPrint("No notifications to mark read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snap) {
          // 🔹 Error or collection missing
          if (snap.hasError) {
            return const Center(
              child: Text(
                "No notifications available.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // 🔹 Waiting for data
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          // 🔹 Empty state if no notifications
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // 🔹 List of notifications
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Notification';
              final body = data['body'] ?? '';
              final read = data['read'] ?? false;
              final timestamp = data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now();

              return Card(
                color: read ? Colors.white : Colors.indigo.shade50,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(body),
                  trailing: Text(
                    "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
