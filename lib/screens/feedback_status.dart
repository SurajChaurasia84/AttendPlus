import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackStatusScreen extends StatelessWidget {
  final String feedbackId;

  const FeedbackStatusScreen({
    super.key,
    required this.feedbackId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    final feedbackRef = FirebaseFirestore.instance
        .collection('feedback')
        .doc(user.email)
        .collection('feedbacks')
        .doc(feedbackId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Feedback Status"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: feedbackRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Feedback not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final feedback = data['feedback'] ?? '';
          final status = data['status'] ?? 'Pending';
          final reply = data['reply'] ?? '';
          final seen = data['seen'] ?? false;
          final feedbackTime = data['timestamp'] as Timestamp?;

          /// 🔴 REMOVE RED BADGE AFTER SEEN (ONLY ONCE)
          if (reply.toString().isNotEmpty && seen == false) {
            feedbackRef.update({'seen': true});
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 📝 FEEDBACK
                const Text(
                  "Your Feedback",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feedback,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Submitted on: ${_formatTime(feedbackTime)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                /// 📌 STATUS
                Row(
                  children: [
                    const Text(
                      "Status: ",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: status == 'Pending'
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// 💬 REPLY
                if (reply.toString().isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: const Text(
                      "No reply yet. Please wait.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.shade50,
                    ),
                    child: Text(
                      reply,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
