import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_student_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final String subjectName;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.subjectName,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final CollectionReference _classes =
      FirebaseFirestore.instance.collection('classes');

  CollectionReference get _students =>
      _classes.doc(widget.classId).collection('students');

  DateTime selectedMonth = DateTime.now();

  String _monthKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}";

  // ⬅️➡️ Month navigation
  void _previousMonth() {
    setState(() {
      selectedMonth =
          DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth =
          DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _openAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStudentScreen(classId: widget.classId),
      ),
    );
  }

  Future<void> _editSubject(String current) async {
    final controller = TextEditingController(text: current);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Subject"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _classes.doc(widget.classId).update({
                  'subjectName': controller.text.trim(),
                });
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Class"),
        content: const Text("This cannot be undone"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    final students = await _students.get();
    for (var d in students.docs) {
      await d.reference.delete();
    }
    await _classes.doc(widget.classId).delete();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _classes.doc(widget.classId).snapshots(),
          builder: (_, snap) {
            final data = snap.data?.data() as Map<String, dynamic>?;

            final subject = data?['subjectName'] ?? widget.subjectName;
            final total = data?['totalStudents'] ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontSize: 16)),
                Text(
                  "$total Students",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'add') _openAddStudent();
              if (v == 'edit') _editSubject(widget.subjectName);
              if (v == 'delete') _deleteClass();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'add', child: Text("Add Student")),
              PopupMenuItem(value: 'edit', child: Text("Edit Subject")),
              PopupMenuItem(value: 'delete', child: Text("Delete Class")),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          // 📅 Month selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth),
                InkWell(
                  onTap: _selectMonth,
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth),
              ],
            ),
          ),
          const Divider(height: 1),

          // 👨‍🎓 Student list + attendance %
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _students.orderBy('rollNo').snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.data!.docs.isEmpty) {
                  return const Center(child: Text("No students yet"));
                }

                return ListView(
                  children: snap.data!.docs.map((doc) {
                    final student =
                        doc.data() as Map<String, dynamic>;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: _students
                          .doc(doc.id)
                          .collection('attendance')
                          .doc(_monthKey(selectedMonth))
                          .snapshots(),
                      builder: (_, aSnap) {
                        double percent = 0;

                        if (aSnap.hasData && aSnap.data!.exists) {
                          final a =
                              aSnap.data!.data() as Map<String, dynamic>;
                          final int p = a['present'] ?? 0;
                          final int t = a['total'] ?? 0;
                          if (t > 0) percent = (p / t) * 100;
                        }

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(student['name']),
                          subtitle:
                              Text("Roll No: ${student['rollNo']}"),
                          trailing: Text(
                            "${percent.toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: percent >= 75
                                  ? Colors.green
                                  : percent >= 50
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
