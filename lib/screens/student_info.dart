import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentInfoScreen extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String rollNo;

  const StudentInfoScreen({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.rollNo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(studentName),
            Text(
              'Roll No: $rollNo',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<_MonthGroup>>(
        future: _loadData(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final monthGroups = snap.data!;

          return ListView.builder(
            itemCount: monthGroups.length,
            itemBuilder: (_, i) {
              final month = monthGroups[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      month.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Month summary (below month title)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Classes Taken: ${month.attendanceTakenCount}, Present: ${month.presentCount}, Attendance (in%): ${month.attendanceTakenCount == 0 ? 0 : ((month.presentCount / month.attendanceTakenCount) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),

                  // Column header
                  _headerRow(month.attendanceTakenCount, month.presentCount),

                  // Month rows
                  ...month.rows.map(_dataRow).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// ===================== DATA =====================
  Future<List<_MonthGroup>> _loadData() async {
    final attendanceSnap = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .get();

    final attendanceMap = {
      for (var d in attendanceSnap.docs) d.id: d['records'] as Map<String, dynamic>? ?? {}
    };

    if (attendanceMap.isEmpty) return [];

    final dates = attendanceMap.keys.map((e) => DateTime.parse(e)).toList();
    dates.sort();

    final startDate = dates.first;
    final endDate = DateTime.now();

    final Map<String, _MonthGroup> grouped = {};

    for (DateTime d = endDate; !d.isBefore(startDate); d = d.subtract(const Duration(days: 1))) {
      final monthKey = DateFormat('MMMM yyyy').format(d);
      grouped.putIfAbsent(monthKey, () => _MonthGroup(title: monthKey));

      final docId = DateFormat('yyyy-MM-dd').format(d);
      final isSunday = d.weekday == DateTime.sunday;
      final attendanceDoc = attendanceMap[docId];

      if (isSunday) {
        grouped[monthKey]!.rows.add(_RowData(
          date: d,
          attendanceTaken: true,
          status: 'Holiday',
          isHoliday: true,
        ));
        continue;
      }

      if (attendanceDoc == null) {
        grouped[monthKey]!.rows.add(_RowData(date: d, attendanceTaken: false));
      } else {
        grouped[monthKey]!.attendanceTakenCount++;
        final status = attendanceDoc[studentId] == 'P' ? 'Present' : 'Absent';
        if (status == 'Present') grouped[monthKey]!.presentCount++;
        grouped[monthKey]!.rows.add(_RowData(
          date: d,
          attendanceTaken: true,
          status: status,
        ));
      }
    }

    return grouped.values.toList();
  }

  /// ===================== UI ROWS =====================
  Widget _headerRow(int attendanceCount, int presentCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          _cell('Date', flex: 3, bold: true),
          _cell('Attendance', flex: 3, bold: true),
          _cell('Status', flex: 2, bold: true),
        ],
      ),
    );
  }

  Widget _dataRow(_RowData row) {
    final attColor = row.attendanceTaken
        ? row.isHoliday
            ? Colors.orange
            : Colors.green
        : Colors.grey;
    final statusColor = row.status == 'Present'
        ? Colors.green
        : row.status == 'Absent'
            ? Colors.red
            : row.isHoliday
                ? Colors.orange
                : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _cell(
            '${DateFormat('dd MMM yyyy').format(row.date)} (${DateFormat('E').format(row.date)})',
            flex: 3,
          ),
          _cell(
            row.isHoliday ? 'Holiday' : (row.attendanceTaken ? 'Taken' : 'Not Taken'),
            flex: 3,
            color: attColor,
          ),
          _cell(
            row.isHoliday ? 'Holiday' : (row.status ?? '--'),
            flex: 2,
            color: statusColor,
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {int flex = 1, bool bold = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}

/// ===================== MODELS =====================
class _MonthGroup {
  final String title;
  final List<_RowData> rows = [];
  int attendanceTakenCount = 0;
  int presentCount = 0;

  _MonthGroup({required this.title});
}

class _RowData {
  final DateTime date;
  final bool attendanceTaken;
  final String? status;
  final bool isHoliday;

  _RowData({
    required this.date,
    this.attendanceTaken = false,
    this.status,
    this.isHoliday = false,
  });
}
