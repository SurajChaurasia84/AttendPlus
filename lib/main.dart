import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth/email_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AttendPlusApp());
}

class AttendPlusApp extends StatelessWidget {
  const AttendPlusApp({super.key});

  Future<bool> _isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seen_welcome') ?? false;
    return !seen;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFF7FA),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF7FA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: SafeArea(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Attend Plus',
          theme: ThemeData(
            primarySwatch: Colors.indigo,
          ),

          /// 🔑 APP ENTRY LOGIC
          home: FutureBuilder<bool>(
            future: _isFirstLaunch(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              /// 🟡 FIRST TIME USERS
              if (snapshot.data == true) {
                return const WelcomeScreen();
              }

              /// 🔵 AUTH + EMAIL VERIFICATION CHECK
              return StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, authSnapshot) {
                  if (authSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  /// 🟢 USER LOGGED IN
                  if (authSnapshot.hasData) {
                    final user = authSnapshot.data!;

                    /// ❌ EMAIL NOT VERIFIED → BLOCK ACCESS
                    if (!user.emailVerified) {
                      return EmailVerificationScreen(user: user);
                    }

                    /// ✅ EMAIL VERIFIED → ENTER APP
                    return const MainScreen();
                  }

                  /// 🔴 USER LOGGED OUT
                  return const LoginScreen();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
