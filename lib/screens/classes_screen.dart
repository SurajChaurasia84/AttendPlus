import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'class_detail_screen.dart';
import 'attendance_screen.dart';

class ClassesScreen extends StatefulWidget {
  final bool fromAttendance;

  const ClassesScreen({
    super.key,
    this.fromAttendance = false, // 👈 default
  });

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final CollectionReference _classesCollection = FirebaseFirestore.instance
      .collection('classes');

  final User? _user = FirebaseAuth.instance.currentUser;

  // ➕ Open bottom sheet for adding class + subject
  void _openModal() {
    _classController.clear();
    _subjectController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _classController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveClass,
              child: const Text('Add Class'),
            ),
          ],
        ),
      ),
    );
  }

  // 💾 Save new class with subject
  Future<void> _saveClass() async {
    final className = _classController.text.trim();
    final subjectName = _subjectController.text.trim();

    if (className.isEmpty || subjectName.isEmpty || _user == null) return;

    try {
      // Add class
      final docRef = await _classesCollection.add({
        'name': className,
        'userId': _user.uid,
        'totalStudents': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add subject as subcollection
      await docRef.collection('subjects').add({
        'name': subjectName,
        'addedAt': FieldValue.serverTimestamp(),
      });

      _classController.clear();
      _subjectController.clear();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text("Please Login"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromAttendance ? 'Select Class' : 'Classes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _classesCollection
            .where('userId', isEqualTo: _user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No classes yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final classId = doc.id;
              final className = data['name'] ?? '';
              final totalStudents = data['totalStudents'] ?? 0;

              // Fetch first subject (for display)
              return StreamBuilder<QuerySnapshot>(
                stream: _classesCollection
                    .doc(classId)
                    .collection('subjects')
                    .orderBy('addedAt')
                    .snapshots(),
                builder: (context, subSnapshot) {
                  String subjectName = '';
                  if (subSnapshot.hasData &&
                      subSnapshot.data!.docs.isNotEmpty) {
                    subjectName =
                        (subSnapshot.data!.docs.first.data()
                            as Map<String, dynamic>)['name'] ??
                        '';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.class_),
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: className,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const TextSpan(
                              text: ' • ', // the dot separator
                              style: TextStyle(
                                fontSize: 14,
                                // fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: subjectName,
                              style: const TextStyle(
                                fontSize: 13, // smaller than class name
                                color: Colors.grey, // lighter/darker shade
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Text('$totalStudents Students'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (widget.fromAttendance) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceScreen(
                                classId: classId,
                                className: className,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailScreen(
                                classId: classId,
                                subjectName: subjectName,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: widget.fromAttendance
          ? null
          : FloatingActionButton(
              onPressed: _openModal,
              child: const Icon(Icons.add),
            ),
    );
  }
}
