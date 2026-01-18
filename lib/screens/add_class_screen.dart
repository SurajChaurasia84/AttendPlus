import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/animated_gradient_button.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _classCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  bool _keepAdding = false;
  bool _loading = false;

  Future<void> _saveClass() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final className = _classCtrl.text.trim();
    final subjectName = _subjectCtrl.text.trim();

    if (className.isEmpty || subjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Class & Subject both required")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔹 Add class with subject directly inside
      await FirebaseFirestore.instance.collection('classes').add({
        'name': className,
        'subjectName': subjectName, // flat structure, no subcollection
        'userId': user.uid,
        'totalStudents': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_keepAdding) {
        // clear fields, stay on screen
        _classCtrl.clear();
        _subjectCtrl.clear();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Class")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 📘 Class Name
            TextField(
              controller: _classCtrl,
              decoration: const InputDecoration(
                labelText: "Class Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// 📕 Subject Name
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: "Subject Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔁 Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Add another class after save"),
              subtitle: const Text(
                "Keep this screen open",
                style: TextStyle(fontSize: 12),
              ),
              value: _keepAdding,
              onChanged: (v) {
                setState(() => _keepAdding = v);
              },
            ),

            const Spacer(),

            /// 💾 Save Button
            AnimatedGradientButton(
              text: "Add Class",
              loading: _loading,
              onPressed: _loading ? null : _saveClass,
              height: 48,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
