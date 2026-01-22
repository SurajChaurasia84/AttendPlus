import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_feedback_screen.dart';
import '../widgets/animated_gradient_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to submit feedback.")),
      );
      return;
    }

    final feedback = _controller.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback cannot be empty.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userDoc = FirebaseFirestore.instance
          .collection('feedback')
          .doc(user.email);

      await userDoc.collection('feedbacks').add({
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending', // initially pending
        'reply': '', // empty reply field
      });

      _controller.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thank you for your feedback!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting feedback: $e")));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Give Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // My Feedbacks tile
            ListTile(
              leading: const Icon(
                Icons.feedback_outlined,
                color: Colors.indigo,
              ),
              title: const Text("My Feedbacks"),
              subtitle: const Text("View all feedbacks you have submitted"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyFeedbackScreen()),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text(
              "We value your feedback. Please write your suggestions or issues below:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "Write your feedback here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedGradientButton(
              text: "Submit Feedback",
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitFeedback,
            ),
          ],
        ),
      ),
    );
  }
}
