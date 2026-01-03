import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceUtils {
  static Future<double> calculateMonthlyAttendance({
    required String classId,
    required String studentId,
    required DateTime month,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final attendanceSnap = await firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .get();

    int totalDays = 0;
    int presentDays = 0;

    for (final doc in attendanceSnap.docs) {
      final date = DateTime.tryParse(doc.id);
      if (date == null) continue;

      // ✅ filter by selected month
      if (date.year != month.year || date.month != month.month) {
        continue;
      }

      final records =
          Map<String, dynamic>.from(doc.data()['records'] ?? {});

      if (!records.containsKey(studentId)) continue;

      totalDays++;

      if (records[studentId] == 'P') {
        presentDays++;
      }
    }

    if (totalDays == 0) return 0;

    return (presentDays / totalDays) * 100;
  }
}
