import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'attendance_screen.dart';
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
  String _userName = '';
  DateTime _selectedDate = DateTime.now();

  String get selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  List<DateTime> get _last7Days =>
      List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

  late Stream<Map<String, int>> _attendanceStream;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
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

  Stream<Map<String, int>> _attendanceStats() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('classes')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((classSnap) async {
          final totalClasses = classSnap.docs.length;
          int submitted = 0;

          for (var cls in classSnap.docs) {
            final docSnap = await FirebaseFirestore.instance
                .collection('classes')
                .doc(cls.id)
                .collection('attendance')
                .doc(selectedDateKey)
                .get();
            if (docSnap.exists) submitted++;
          }

          return {'totalClasses': totalClasses, 'submitted': submitted};
        });
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
                                child: const Icon(Icons.chevron_left, size: 24),
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
                                          horizontal: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.indigo
                                              : const Color.fromARGB(
                                                  186,
                                                  223,
                                                  223,
                                                  223,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          // border: Border.all(
                                          //   color: Colors.indigo,
                                          //   width: isSelected ? 2 : 1,
                                          // ),
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

                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      controller: _pageController,
                      padEnds: false, // ends pe padding remove
                      itemCount: 2,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        double gap = 12; // gap between cards

                        Widget child;
                        if (index == 0) {
                          child = _infoCard(
                            'Submitted Classes',
                            '$submitted / $total',
                            Icons.how_to_reg,
                            // Colors.indigo,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubmittedClassesScreen(
                                    date: _selectedDate,
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          child = _attendanceCircle(percent);
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: gap / 2),
                          child: child,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) {
                      final active = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 8,
                        width: active ? 22 : 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.indigo : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var action in [
                            {
                              'label': 'Attendance',
                              'asset': 'assets/src/attendance.png',
                              'color': Colors.indigo,
                              'onTap': () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ClassesScreen(
                                      fromAttendance: true,
                                    ),
                                  ),
                                );
                              },
                            },
                            {
                              'label': 'Classes',
                              'asset': 'assets/src/classes.png',
                              'color': Colors.deepPurple,
                              'onTap': () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ClassesScreen(),
                                  ),
                                );
                              },
                            },
                            {
                              'label': 'Reports',
                              'asset': 'assets/src/report.png',
                              'color': Colors.deepPurple,
                              'onTap': () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReportsScreen(),
                                  ),
                                );
                              },
                            },

                            {
                              'label': 'Settings',
                              'asset': 'assets/src/settings.png',
                              'color': Colors.indigo,
                              'onTap': () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            },
                          ])
                            SizedBox(
                              width: itemWidth,
                              child: _action(
                                label: action['label'] as String,
                                assetPath: action['asset'] as String,
                                color: action['color'] as Color,
                                onTap: action['onTap'] as VoidCallback,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  /// REMAINING CLASSES HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remaining Classes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ClassesScreen(fromAttendance: true),
                            ),
                          );
                        },
                        child: const Text('Show All'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const _RemainingClassesList(),
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
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color.fromARGB(61, 63, 81, 181),
          // gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.indigo),
            Text(
              value,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  Widget _attendanceCircle(double percent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(61, 255, 153, 0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Attendance", style: TextStyle(fontWeight: FontWeight.w600)),
              Icon(Icons.pie_chart, color: Colors.orange),
            ],
          ),

          const SizedBox(height: 16),

          // Linear progress with labels
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                  Text(
                    "${percent.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 6,
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.orange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action({
    required String label,
    required String assetPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),

          // 🔥 MATCHING BORDER
          border: Border.all(
            color: color, // same as card color
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 35,
              width: 35,
              fit: BoxFit.contain,
              color: color, // optional: icon bhi same color
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemainingClassesList extends StatelessWidget {
  const _RemainingClassesList();

  String get todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, classSnap) {
        if (!classSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = classSnap.data!.docs;

        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _getRemainingClasses(classes),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final remainingClasses = snapshot.data!;

            /// ✅ EMPTY STATE
            if (remainingClasses.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "No remaining classes",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "All attendance is taken for today.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            /// ❌ SHOW REMAINING CLASSES
            return Column(
              children: remainingClasses.map((cls) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.red.withOpacity(0.08),
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      cls['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Attendance not taken',
                      style: TextStyle(color: Colors.red),
                    ),
                    trailing: const Icon(Icons.chevron_right),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceScreen(
                            classId: cls.id,
                            className: cls['name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  /// 🔍 FILTER ONLY NOT-SUBMITTED CLASSES (TODAY)
  Future<List<QueryDocumentSnapshot>> _getRemainingClasses(
    List<QueryDocumentSnapshot> classes,
  ) async {
    final List<QueryDocumentSnapshot> remaining = [];

    for (final cls in classes) {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(cls.id)
          .collection('attendance')
          .doc(todayKey)
          .get();

      if (!doc.exists) {
        remaining.add(cls);
      }
    }

    return remaining;
  }
}
