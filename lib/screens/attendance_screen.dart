import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// studentId -> "P" | "A"
  final Map<String, String> _attendance = {};

  bool _submitting = false;
  bool _alreadySubmitted = false;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  int get presentCount =>
      _attendance.values.where((e) => e == 'P').length;

  int get absentCount =>
      _attendance.values.where((e) => e == 'A').length;

  bool get _allMarked =>
      _attendance.isNotEmpty &&
      _attendance.values.every((v) => v == 'P' || v == 'A');

  /// 🔒 Check if already submitted
  Future<void> _checkExistingAttendance() async {
    final doc = await _firestore
        .collection('classes')
        .doc(widget.classId)
        .collection('attendance')
        .doc(today)
        .get();

    if (doc.exists) {
      final records =
          Map<String, dynamic>.from(doc['records'] ?? {});
      setState(() {
        _alreadySubmitted = true;
        records.forEach((k, v) => _attendance[k] = v);
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_alreadySubmitted) return;

    setState(() => _submitting = true);

    try {
      await _firestore
          .collection('classes')
          .doc(widget.classId)
          .collection('attendance')
          .doc(today)
          .set({
        'createdAt': FieldValue.serverTimestamp(),
        'records': _attendance,
      });

      setState(() => _alreadySubmitted = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance submitted")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _submitting = false);
  }

  @override
  void initState() {
    super.initState();
    _checkExistingAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance • ${widget.className}"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('classes')
            .doc(widget.classId)
            .collection('students')
            .orderBy('addedAt')
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return Column(
            children: [
              // 🔢 COUNTER HEADER (LEFT SIDE)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _counterChip("Present", presentCount, Colors.green),
                    const SizedBox(width: 10),
                    _counterChip("Absent", absentCount, Colors.red),
                    const Spacer(),
                    Text(
                      today,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, index) {
                    final doc = students[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = _attendance[doc.id];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(data['name']),
                        subtitle:
                            Text("Roll: ${data['rollNo'] ?? '-'}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _statusButton(
                              label: "P",
                              selected: status == 'P',
                              color: Colors.green,
                              disabled: _alreadySubmitted,
                              onTap: () => setState(
                                  () => _attendance[doc.id] = 'P'),
                            ),
                            const SizedBox(width: 8),
                            _statusButton(
                              label: "A",
                              selected: status == 'A',
                              color: Colors.red,
                              disabled: _alreadySubmitted,
                              onTap: () => setState(
                                  () => _attendance[doc.id] = 'A'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🔘 SUBMIT BUTTON
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_allMarked &&
                            !_submitting &&
                            !_alreadySubmitted)
                        ? _submitAttendance
                        : null,
                    child: _submitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            _alreadySubmitted
                                ? "Attendance Already Submitted"
                                : "Submit Attendance",
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _counterChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusButton({
    required String label,
    required bool selected,
    required Color color,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
