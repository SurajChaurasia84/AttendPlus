import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'class_report_screen.dart'; // make sure you have this screen

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  DateTime selectedMonth = DateTime.now();

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  /// 📊 Fetch monthly attendance stats (current user's classes only)
  Future<Map<String, double>> _monthlyStats() async {
    if (_user == null) return {'present': 0, 'total': 0, 'percent': 0};

    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final classesSnap = await _db
        .collection('classes')
        .where('userId', isEqualTo: _user.uid)
        .get();

    double totalPresent = 0;
    double totalEntries = 0;

    for (var c in classesSnap.docs) {
      final attendanceSnap = await _db
          .collection('classes')
          .doc(c.id)
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

      for (var d in attendanceSnap.docs) {
        final records = Map<String, dynamic>.from(d.data()['records'] ?? {});
        for (var v in records.values) {
          totalEntries++;
          if (v == 'P') totalPresent++;
        }
      }
    }

    final percent = totalEntries == 0 ? 0 : (totalPresent / totalEntries) * 100;

    return {
      'present': totalPresent.toDouble(),
      'total': totalEntries.toDouble(),
      'percent': percent.toDouble(),
    };
  }

  /// 📊 Bar Chart Data
  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 14,
          borderRadius: BorderRadius.circular(4),
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text("Reports"), centerTitle: false),
      body: FutureBuilder<Map<String, double>>(
        future: _monthlyStats(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final percent = snap.data!['percent'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 📅 Month Filter
              GestureDetector(
                onTap: _pickMonth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 8),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 📈 Summary Cards
              Row(
                children: [
                  _statCard(
                    "Attendance",
                    "${percent.toStringAsFixed(1)}%",
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    "Status",
                    percent >= 75
                        ? "Excellent"
                        : percent >= 50
                            ? "Average"
                            : "Poor",
                    percent >= 75
                        ? Colors.green
                        : percent >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// 📊 Attendance Graph
              const Text(
                "Monthly Attendance Overview",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: 100,
                    barGroups: [_bar(0, percent)],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 25,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (_, __) =>
                              const Text("Attendance"),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// 📚 Class-wise Reports
              const Text(
                "Class-wise Summary",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('classes')
                    .where('userId', isEqualTo: _user.uid)
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) return const SizedBox();

                  return Column(
                    children: snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>? ??
                          <String, dynamic>{};
                      final className = d['name'] ?? 'Class';
                      final totalStudents = d['totalStudents'] ?? 0;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.class_),
                          title: Text(className),
                          subtitle: Text("$totalStudents Students"),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassReportScreen(
                                  classId: doc.id,
                                  className: className,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
