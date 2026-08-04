import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/sos/sos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const ResQApp());
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQ AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Immediately bypass waiting state if user is present or stream hasn't fired yet
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null || snapshot.hasData) {
            return const SosScreen();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show brief initial view or default to SosScreen/LoginScreen to avoid infinite loading
            return const SosScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
