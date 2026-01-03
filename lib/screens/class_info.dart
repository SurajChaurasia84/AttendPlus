import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ClassInfoScreen extends StatelessWidget {
  final String classId;
  final String className;

  const ClassInfoScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  CollectionReference get _classes =>
      FirebaseFirestore.instance.collection('classes');

  CollectionReference get _students =>
      FirebaseFirestore.instance.collection('classes').doc(classId).collection('students');

  // Share class link
  void _shareClass(BuildContext context) {
    final code = const Uuid().v4().substring(0, 6).toUpperCase();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sharable Code"),
        content: Text("Share this code with students: $code"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(className),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareClass(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total students
          StreamBuilder<DocumentSnapshot>(
            stream: _classes.doc(classId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final totalStudents = data['totalStudents'] ?? 0;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Total Students: $totalStudents",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),

          const Divider(),

          // Students list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _students.orderBy('addedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading students"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No students yet"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final student = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(student['name'] ?? ''),
                        subtitle: Text('Roll No: ${student['rollNo'] ?? '-'}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
