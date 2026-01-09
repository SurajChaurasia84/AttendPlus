import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ------------------------------
/// SUBMITTED + NOT SUBMITTED CLASSES SCREEN
/// ------------------------------
class SubmittedClassesScreen extends StatelessWidget {
  final DateTime date;

  const SubmittedClassesScreen({super.key, required this.date});

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Status'),
            Text(
              DateFormat('EEE, dd MMM yyyy').format(date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!classSnap.hasData || classSnap.data!.docs.isEmpty) {
            return const Center(child: Text('No classes found'));
          }

          final classes = classSnap.data!.docs;

          return FutureBuilder<_ClassResult>(
            future: _processClasses(classes),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snap.hasData) {
                return const Center(child: Text('Failed to load data'));
              }

              final submitted = snap.data!.submitted;
              final notSubmitted = snap.data!.notSubmitted;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('Submitted Classes (${submitted.length})'),
                  const SizedBox(height: 12),
                  if (submitted.isEmpty)
                    _emptyText('No attendance submitted'),
                  ...submitted.map((e) => _submittedTile(context, e)),

                  const SizedBox(height: 15),

                  _sectionTitle('Not Submitted (${notSubmitted.length})'),
                  const SizedBox(height: 12),
                  if (notSubmitted.isEmpty)
                    _emptyText('All classes submitted'),
                  ...notSubmitted.map(_notSubmittedTile),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// ------------------------------
  /// DATA PROCESSING
  /// ------------------------------
  Future<_ClassResult> _processClasses(
    List<QueryDocumentSnapshot> classes,
  ) async {
    final submitted = <_SubmittedClass>[];
    final notSubmitted = <QueryDocumentSnapshot>[];

    for (final cls in classes) {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(cls.id)
          .collection('attendance')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        submitted.add(
          _SubmittedClass(
            classDoc: cls,
            submittedAt: doc.data()?['createdAt'] != null
                ? (doc['createdAt'] as Timestamp).toDate()
                : null,
          ),
        );
      } else {
        notSubmitted.add(cls);
      }
    }

    return _ClassResult(submitted, notSubmitted);
  }

  /// ------------------------------
  /// UI HELPERS
  /// ------------------------------
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _submittedTile(BuildContext context, _SubmittedClass data) {
    final cls = data.classDoc;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceDetailScreen(
              classId: cls.id,
              className: cls['name'] ?? 'Class',
              date: date,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cls['name'] ?? 'Class',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(cls['subjectName'] ?? '',
                style: const TextStyle(color: Colors.grey)),
            if (data.submittedAt != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Submitted at ${DateFormat('hh:mm a').format(data.submittedAt!)}',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _notSubmittedTile(QueryDocumentSnapshot cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cls['name'] ?? 'Class',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(cls['subjectName'] ?? '',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// ATTENDANCE DETAIL SCREEN (UPDATED UI)
/// ------------------------------
class AttendanceDetailScreen extends StatefulWidget {
  final String classId;
  final String className;
  final DateTime date;

  const AttendanceDetailScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.date,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  late DateTime _selectedDate;

  String get dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.className),
                  Text(
                    DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'date') _pickDate();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'date',
                  child: Text('Go to date'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('attendance')
            .doc(dateKey)
            .snapshots(),
        builder: (context, attendanceSnap) {
          if (!attendanceSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = attendanceSnap.data!.data() as Map<String, dynamic>?;
          final records = Map<String, dynamic>.from(data?['records'] ?? {});

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('students')
                .orderBy('rollNo')
                .snapshots(),
            builder: (context, studentSnap) {
              if (!studentSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final students = studentSnap.data!.docs;

              int present = 0;
              int absent = 0;

              for (final s in students) {
                final status = records[s.id];
                if (status == 'P') {
                  present++;
                } else {
                  absent++;
                }
              }

              return Column(
                children: [
                  /// SUMMARY BAR
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        _countChip('Present', present, Colors.green),
                        const SizedBox(width: 8),
                        _countChip('Absent', absent, Colors.red),
                        const Spacer(),
                        Text(
                          'Total: ${students.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  /// STUDENT LIST
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      separatorBuilder: (_,_) => const Divider(),
                      itemBuilder: (context, i) {
                        final student = students[i];
                        final status = records[student.id];
                        final isPresent = status == 'P';

                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'] ?? 'Student',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Roll No: ${student['rollNo']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              isPresent ? 'Present' : 'Absent',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPresent ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}


/// ------------------------------
/// MODELS
/// ------------------------------
class _SubmittedClass {
  final QueryDocumentSnapshot classDoc;
  final DateTime? submittedAt;

  _SubmittedClass({required this.classDoc, this.submittedAt});
}

class _ClassResult {
  final List<_SubmittedClass> submitted;
  final List<QueryDocumentSnapshot> notSubmitted;

  _ClassResult(this.submitted, this.notSubmitted);
}
