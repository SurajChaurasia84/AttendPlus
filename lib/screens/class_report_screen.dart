import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'student_info.dart';

class ClassReportScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ClassReportScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  final _db = FirebaseFirestore.instance;
  DateTime selectedMonth = DateTime.now();

  Future<Map<String, dynamic>> _generateReport() async {
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final studentsSnap = await _db
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .orderBy('rollNo')
        .get();

    final attendanceSnap = await _db
        .collection('classes')
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

    Map<String, int> total = {};
    Map<String, int> present = {};

    for (var d in attendanceSnap.docs) {
      final records = Map<String, dynamic>.from(d['records'] ?? {});
      for (final e in records.entries) {
        total[e.key] = (total[e.key] ?? 0) + 1;
        if (e.value == 'P') present[e.key] = (present[e.key] ?? 0) + 1;
      }
    }

    List<Map<String, dynamic>> students = [];
    double overallPercent = 0;

    for (var s in studentsSnap.docs) {
      final id = s.id;
      final p = (present[id] ?? 0);
      final t = (total[id] ?? 0);
      final percent = t == 0 ? 0 : (p / t) * 100;

      overallPercent += percent;

      students.add({
        'id': id,
        'name': s['name'],
        'rollNo': s['rollNo'],
        'percent': percent,
      });
    }

    overallPercent = students.isEmpty ? 0 : overallPercent / students.length;

    return {
      'students': students,
      'overall': overallPercent,
      'totalStudents': students.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(title: Text("${widget.className} Report")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _generateReport(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!;
          final students = data['students'] as List;
          final avg = data['overall'];

          // Students with <75% attendance
          final lowAttendance = students
              .where((s) => s['percent'] < 75)
              .toList();

          // Remaining students (>=75%)
          final normalAttendance = students
              .where((s) => s['percent'] >= 75)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 📅 Month
              Center(
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 📊 Summary Cards
              Row(
                children: [
                  _infoCard("Students", data['totalStudents'].toString()),
                  _infoCard("Average", "${avg.toStringAsFixed(1)}%"),
                ],
              ),

              const SizedBox(height: 20),

              /// ⚠️ Low Attendance
              Text(
                "Low Attendance (<75%)",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              if (lowAttendance.isEmpty)
                const Text("No low attendance students")
              else
                ...lowAttendance.map(
                  (s) => ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(s['name']),
                    subtitle: Text("Roll No: ${s['rollNo']}"),
                    trailing: Text(
                      "${s['percent'].toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentInfoScreen(
                            classId: widget.classId,
                            studentId: s['id'],
                            studentName: s['name'],
                            rollNo: s['rollNo'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 10),

              /// 📄 Other Students (>=75%)
              if (normalAttendance.isNotEmpty)
                Text(
                  "Other Students",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 8),

              ...normalAttendance.map(
                (s) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(s['name']),
                  subtitle: Text("Roll No: ${s['rollNo']}"),
                  trailing: Text(
                    "${s['percent'].toStringAsFixed(0)}%",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentInfoScreen(
                          classId: widget.classId,
                          studentId: s['id'],
                          studentName: s['name'],
                          rollNo: s['rollNo'].toString(),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              /// 📤 Export (future ready)
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Export Report (PDF / Excel)"),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Export feature coming soon")),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
