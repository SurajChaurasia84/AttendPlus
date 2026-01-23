import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/animated_gradient_button.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  /// 🔹 STATIC FAQs
  static final List<_FaqItem> _faqs = [
    _FaqItem(
      question: "What is AttendPlus?",
      answer:
          "AttendPlus is an attendance and classroom management platform designed to simplify daily attendance tracking.",
    ),
    _FaqItem(
      question: "Is AttendPlus free to use?",
      answer: "Yes, AttendPlus offers completely free features.",
    ),
    _FaqItem(
      question: "Is my data secure?",
      answer:
          "Yes. We use optimized security rules and industry-standard practices to keep your data safe.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email!;

    return Scaffold(
      appBar: AppBar(title: const Text("FAQs")),
      body: Column(
        children: [
          /// 🔹 FAQ LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._faqs.map((f) => _FaqTile(faq: f)),

                const SizedBox(height: 14),
                const Text(
                  "Your Questions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                /// 🔥 USER QUESTIONS FROM FIRESTORE
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feedback')
                      .doc(email)
                      .collection('questions')
                      .orderBy('askedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "No questions asked yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _UserQuestionTile(data: data);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          /// 🔹 FOOTER
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Text(
                  "Have a question?",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AskQuestionScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Ask us",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 📦 FAQ MODEL
class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

/// 🎯 STATIC FAQ TILE
class _FaqTile extends StatelessWidget {
  final _FaqItem faq;

  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: ExpansionTile(
          title: Text(
            faq.question,
            // style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          iconColor: Colors.indigo,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  faq.answer,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.indigo),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 👤 USER QUESTION TILE
class _UserQuestionTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _UserQuestionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final String question = data['question'];
    final String? answer = data['answer'];

    final bool hasAnswer = answer != null && answer.trim().isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: hasAnswer
            ? ExpansionTile(
                title: Text(
                  question,
                  // style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        answer,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Colors.indigo),
                      ),
                    ),
                  ),
                ],
              )
            : ListTile(
                title: Text(
                  question,
                  // style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Awaiting reply",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
      ),
    );
  }
}

/// ❓ ASK QUESTION SCREEN
class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final controller = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email!;

    return Scaffold(
      appBar: AppBar(title: const Text("Ask a Question")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Have a question or confusion?\nAsk us and we'll get back to you.",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Type your question...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedGradientButton(
              text: "Submit",
              loading: loading,
              onPressed: loading
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;

                      setState(() => loading = true);

                      await FirebaseFirestore.instance
                          .collection('feedback')
                          .doc(email)
                          .collection('questions')
                          .add({
                            'question': controller.text.trim(),
                            'answer': "", // unanswered
                            'askedAt': FieldValue.serverTimestamp(),
                          });

                      setState(() => loading = false);
                      Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
