import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'notifications_screen.dart';
import 'classes_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'submitted_classes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _notificationCount = 0;
  String _userName = 'Teacher';

  DateTime _selectedDate = DateTime.now();

  String get selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  List<DateTime> get _last7Days =>
      List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

  late Stream<Map<String, int>> _attendanceStream;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchNotifications();
    _attendanceStream = _attendanceStats();
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        _userName = doc['name'] ?? 'Teacher';
      });
    }
  }

  void _fetchNotifications() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      setState(() {
        _notificationCount = snap.docs.length;
      });
    });
  }

  void _clearNotifications() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({'read': true});
    }

    setState(() => _notificationCount = 0);
  }

  Stream<Map<String, int>> _attendanceStats() async* {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final classesQuery = FirebaseFirestore.instance
        .collection('classes')
        .where('userId', isEqualTo: uid);

    await for (final classSnap in classesQuery.snapshots()) {
      final totalClasses = classSnap.docs.length;
      int submitted = 0;

      for (var cls in classSnap.docs) {
        final doc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(cls.id)
            .collection('attendance')
            .doc(selectedDateKey)
            .get();
        if (doc.exists) submitted++;
      }

      yield {'totalClasses': totalClasses, 'submitted': submitted};
    }
  }

  Future<void> _pickDateFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _attendanceStream = _attendanceStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Map<String, int>>(
          stream: _attendanceStream,
          builder: (context, snapshot) {
            final total = snapshot.data?['totalClasses'] ?? 0;
            final submitted = snapshot.data?['submitted'] ?? 0;
            final percent = total == 0 ? 0.0 : (submitted / total) * 100;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $_userName',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE, dd MMM').format(_selectedDate),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none, size: 30),
                            onPressed: () {
                              _clearNotifications();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          if (_notificationCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_notificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// DATE PUNCH STRIP
                  SizedBox(
                    height: 58,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final iconWidth = 32.0;
                        final spacing = 4.0;
                        final dateWidth =
                            (totalWidth - iconWidth - spacing) / 7;

                        return Row(
                          children: [
                            SizedBox(
                              width: iconWidth,
                              child: GestureDetector(
                                onTap: _pickDateFromCalendar,
                                child:
                                    const Icon(Icons.chevron_left, size: 24),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.zero,
                                itemCount: _last7Days.length,
                                itemBuilder: (context, i) {
                                  final d = _last7Days[i];
                                  final isSelected = DateUtils.isSameDay(
                                    d,
                                    _selectedDate,
                                  );

                                  return SizedBox(
                                    width: dateWidth,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDate = d;
                                          _attendanceStream =
                                              _attendanceStats();
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              DateFormat('EEE').format(d),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${d.day}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Today's Overview",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _infoCard(
                        'Submitted',
                        '$submitted / $total',
                        Icons.how_to_reg,
                        Colors.indigo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SubmittedClassesScreen(date: _selectedDate),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _attendanceCircle(percent),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _action(
                        'Take Attendance',
                        Icons.how_to_reg,
                        Colors.indigo,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClassesScreen(
                                  fromAttendance: true),
                            ),
                          );
                        },
                      ),
                      _action('Reports', Icons.bar_chart, Colors.green, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );
                      }),
                      _action('Classes', Icons.class_, Colors.deepPurple, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClassesScreen(),
                          ),
                        );
                      }),
                      _action('Settings', Icons.settings, Colors.orange, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 122,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(title, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceCircle(double percent) {
    return Expanded(
      child: Container(
        height: 122,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 7,
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.orange),
                  ),
                  Text('${percent.toStringAsFixed(0)}%'),
                ],
              ),
            ),
            // const SizedBox(height: 8),
            const Text('Attendance', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _action(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 150,
      height: 100,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
