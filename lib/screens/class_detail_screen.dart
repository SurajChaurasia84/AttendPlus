import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_student_screen.dart';
import 'class_info.dart';
import 'student_info.dart';

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
  final _classes = FirebaseFirestore.instance.collection('classes');

  CollectionReference get _students =>
      _classes.doc(widget.classId).collection('students');

  DateTime selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
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

  Future<double> _studentPercent(String studentId) async {
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final snap = await _classes
        .doc(widget.classId)
        .collection('attendance')
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(start),
        )
        .where(
          FieldPath.documentId,
          isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(end),
        )
        .get();

    int total = 0;
    int present = 0;

    for (var d in snap.docs) {
      final r = d['records'];
      if (r != null && r[studentId] != null) {
        total++;
        if (r[studentId] == 'P') present++;
      }
    }

    if (total == 0) return 0;
    return (present / total) * 100;
  }

  void _openAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStudentScreen(classId: widget.classId),
      ),
    );
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

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassInfoScreen(
                      classId: widget.classId,
                      // subjectName: subject,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject, style: const TextStyle(fontSize: 16)),
                  Text(
                    "$total Students",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _openAddStudent,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                InkWell(
                  onTap: _selectMonth,
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _students.orderBy('rollNo').snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.data!.docs.isEmpty) {
                  return const Center(child: Text("No students"));
                }

                return ListView(
                  children: snap.data!.docs.map((doc) {
                    final s = doc.data() as Map<String, dynamic>;

                    return FutureBuilder<double>(
                      future: _studentPercent(doc.id),
                      builder: (_, pSnap) {
                        final percent = pSnap.data ?? 0;

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(s['name']),
                          subtitle: Text("Roll No: ${s['rollNo']}"),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentInfoScreen(
                                  classId: widget.classId,
                                  studentId: doc.id,
                                  studentName: s['name'],
                                  rollNo: s['rollNo'].toString(),
                                ),
                              ),
                            );
                          },
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
