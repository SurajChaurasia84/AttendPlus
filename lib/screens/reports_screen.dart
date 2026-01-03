import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GlobalReportsScreen extends StatefulWidget {
  const GlobalReportsScreen({super.key});

  @override
  State<GlobalReportsScreen> createState() => _GlobalReportsScreenState();
}

class _GlobalReportsScreenState extends State<GlobalReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime selectedMonth = DateTime.now();

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

  String get monthLabel => DateFormat('MMMM yyyy').format(selectedMonth);

  /// Load all classes + students + attendance for the selected month
  Future<List<Map<String, dynamic>>> _loadGlobalReport() async {
    final classesSnap = await _firestore.collection('classes').get();
    final List<Map<String, dynamic>> allClasses = [];

    for (final classDoc in classesSnap.docs) {
      final classId = classDoc.id;
      final subjectName = classDoc['subjects'] ?? classDoc['name'] ?? "Class";

      // Students
      final studentsSnap = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      final studentStats = <Map<String, dynamic>>[];

      // Attendance
      final attendanceSnap = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('attendance')
          .get();

      // Filter attendance by selected month
      final monthlyAttendanceDocs = attendanceSnap.docs.where((doc) {
        final createdAt = doc['createdAt'];
        if (createdAt == null) return false;
        final date = (createdAt as Timestamp).toDate();
        return date.year == selectedMonth.year &&
            date.month == selectedMonth.month;
      }).toList();

      final attendanceDays = monthlyAttendanceDocs.length;

      for (final studentDoc in studentsSnap.docs) {
        final studentId = studentDoc.id;
        final studentName = studentDoc['name'];
        final rollNo = studentDoc['rollNo'];

        int present = 0;

        for (final attDoc in monthlyAttendanceDocs) {
          final records = Map<String, dynamic>.from(attDoc['records'] ?? {});
          if (records[studentId] == 'P') present++;
        }

        final percent = attendanceDays == 0 ? 0.0 : (present / attendanceDays) * 100;

        studentStats.add({
          'studentId': studentId,
          'name': studentName,
          'rollNo': rollNo,
          'present': present,
          'absent': attendanceDays - present,
          'attendancePercent': percent,
        });
      }

      final daysInMonth = DateUtils.getDaysInMonth(
          selectedMonth.year, selectedMonth.month);
      final holidays = daysInMonth - attendanceDays;

      allClasses.add({
        'classId': classId,
        'subjectName': subjectName,
        'students': studentStats,
        'totalStudents': studentsSnap.docs.length,
        'holidays': holidays < 0 ? 0 : holidays,
        'attendanceDays': attendanceDays,
      });
    }

    return allClasses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Reports"),
      ),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth),
                Text(
                  monthLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadGlobalReport(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}"));
                }

                final classes = snapshot.data ?? [];

                if (classes.isEmpty) {
                  return const Center(child: Text("No classes found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    final students = cls['students'] as List<dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Text(cls['subjectName'],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Students: ${cls['totalStudents']} • Holidays: ${cls['holidays']} • Attendance Days: ${cls['attendanceDays']}"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Student Attendance Details",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                ...students.map<Widget>((s) {
                                  final percent = s['attendancePercent'] as double;
                                  return ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(s['name']),
                                    subtitle: Text(
                                        "Roll: ${s['rollNo']} • P: ${s['present']}  A: ${s['absent']}"),
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
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
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
