import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'notifications_screen.dart';
import 'classes_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _notificationCount = 0;
  String _userName = 'Teacher';

  String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get formattedDate {
    final now = DateTime.now();
    final day = DateFormat('EE').format(now); // Mon, Tue
    final date = DateFormat('dd MMM').format(now);
    final time = DateFormat('hh:mm a').format(now);
    return "$day · $date , $time";
  }

  late Stream<Map<String, int>> _attendanceStream;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchNotifications();
    _attendanceStream = _attendanceStats();
  }

  /// 🔹 Fetch user name from Firestore
  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _userName = doc['name'] ?? 'Teacher';
      });
    }
  }

  /// 🔹 Fetch notification count
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

  /// 🔹 Clear notifications when opened
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

    setState(() {
      _notificationCount = 0;
    });
  }

  /// 🔹 Attendance stats stream
  Stream<Map<String, int>> _attendanceStats() async* {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final classesQuery =
        FirebaseFirestore.instance.collection('classes').where('userId', isEqualTo: uid);

    await for (final classSnap in classesQuery.snapshots()) {
      final totalClasses = classSnap.docs.length;
      int todaySubmitted = 0;

      for (var cls in classSnap.docs) {
        final doc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(cls.id)
            .collection('attendance')
            .doc(today)
            .get();
        if (doc.exists) todaySubmitted++;
      }

      yield {
        'totalClasses': totalClasses,
        'todaySubmitted': todaySubmitted,
      };
    }
  }

  /// 🔹 Refresh manually
  Future<void> _refresh() async {
    setState(() {
      _attendanceStream = _attendanceStats();
      _fetchUserName();
      _fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Please Login"));

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Map<String, int>>(
          stream: _attendanceStream,
          builder: (context, snapshot) {
            int totalClasses = 0;
            int todaySubmitted = 0;
            if (snapshot.hasData) {
              totalClasses = snapshot.data!['totalClasses']!;
              todaySubmitted = snapshot.data!['todaySubmitted']!;
            }

            final attendancePercent =
                totalClasses == 0 ? 0 : (todaySubmitted / totalClasses) * 100;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 Top Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, $_userName",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.notifications_none, size: 30),
                              onPressed: () {
                                _clearNotifications();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen(),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 📊 Dashboard Cards
                    Row(
                      children: [
                        _infoCard(
                          title: "Today Attendance",
                          value: "$todaySubmitted / $totalClasses",
                          subtitle: "Submitted",
                          icon: Icons.how_to_reg,
                          color: Colors.indigo,
                        ),
                        const SizedBox(width: 12),
                        _infoCard(
                          title: "Total Classes",
                          value: "$totalClasses",
                          subtitle: "All Subjects",
                          icon: Icons.book,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _infoCard(
                          title: "Attendance %",
                          value: "${attendancePercent.toStringAsFixed(1)}%",
                          subtitle: "Today",
                          icon: Icons.bar_chart,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ⚡ Quick Actions
                    const Text(
                      "Quick Actions",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _actionButton(
                          icon: Icons.how_to_reg,
                          label: "Take Attendance",
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ClassesScreen(fromAttendance: true),
                              ),
                            );
                          },
                        ),
                        _actionButton(
                          icon: Icons.bar_chart,
                          label: "Reports",
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReportsScreen()),
                            );
                          },
                        ),
                        _actionButton(
                          icon: Icons.class_,
                          label: "Classes",
                          color: Colors.deepPurple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ClassesScreen()),
                            );
                          },
                        ),
                        _actionButton(
                          icon: Icons.settings,
                          label: "Settings",
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 150,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
