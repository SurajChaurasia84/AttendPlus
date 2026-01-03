import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'home_screen.dart';
import 'classes_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ClassesScreen(fromAttendance: true), // 👈 choose class for attendance
    ClassesScreen(),                     // 👈 normal class management
    GlobalReportsScreen(),
    // ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF7925F6),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Iconsax.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Iconsax.tick_circle),
                label: "Attendance",
              ),
              BottomNavigationBarItem(
                icon: Icon(Iconsax.book),
                label: "Classes",
              ),
              BottomNavigationBarItem(
                icon: Icon(Iconsax.chart_2),
                label: "Reports",
              ),
              BottomNavigationBarItem(
                icon: Icon(Iconsax.setting_2),
                label: "Settings",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
