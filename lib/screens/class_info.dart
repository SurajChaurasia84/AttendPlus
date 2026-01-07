import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassInfoScreen extends StatelessWidget {
  final String classId;

  const ClassInfoScreen({
    super.key,
    required this.classId,
  });

  CollectionReference get _classes =>
      FirebaseFirestore.instance.collection('classes');

  CollectionReference get _students =>
      _classes.doc(classId).collection('students');

  // ================= MENU ACTIONS =================
  void _onMenuSelected(
    BuildContext context,
    String value,
    String className,
    String subjectName,
  ) {
    switch (value) {
      case 'edit_class':
        _showEditDialog(
          context,
          isSubject: false,
          initialValue: className,
        );
        break;

      case 'edit_subject':
        _showEditDialog(
          context,
          isSubject: true,
          initialValue: subjectName,
        );
        break;

      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  // ================= EDIT DIALOG =================
  void _showEditDialog(
    BuildContext context, {
    required bool isSubject,
    required String initialValue,
  }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSubject ? 'Edit Subject' : 'Edit Class'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isSubject ? 'Subject Name' : 'Class Name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) return;

              await _classes.doc(classId).update({
                isSubject ? 'subjectName' : 'name': value,
              });

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ================= DELETE =================
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Class"),
        content: const Text(
          "This will permanently delete the class and all students.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _classes.doc(classId).delete();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _classes.doc(classId).snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final className = data['name'] ?? '';
        final subjectName = data['subjectName'] ?? '';
        final totalStudents = data['totalStudents'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subjectName.isNotEmpty)
                  Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) =>
                    _onMenuSelected(context, v, className, subjectName),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit_class',
                    child: Text('Edit Class'),
                  ),
                  PopupMenuItem(
                    value: 'edit_subject',
                    child: Text('Edit Subject'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Total Students: $totalStudents",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Divider(),

              // ================= STUDENT LIST =================
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _students
                      .orderBy('addedAt', descending: true)
                      .snapshots(),
                  builder: (_, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text("No students yet"),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final s =
                            docs[i].data() as Map<String, dynamic>;

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(s['name'] ?? ''),
                            subtitle:
                                Text('Roll No: ${s['rollNo'] ?? '-'}'),
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
      },
    );
  }
}
