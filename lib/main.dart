import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'role_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'intro_page.dart';
import 'app_theme.dart'; // Integrated custom theme file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rodo MVP',
      // Removes the red debug banner from the top right corner
      debugShowCheckedModeBanner: false, 
      
      // Applies your professional "Modern SaaS" theme globally
      theme: AppTheme.lightTheme, 
      
      home: StreamBuilder<User?>(
        // OPTIMIZATION 1: Use idTokenChanges for more reliable triggers on web
        stream: FirebaseAuth.instance.idTokenChanges(),
        builder: (context, snapshot) {
          // While Firebase is checking the login status (e.g., loading from LocalStorage)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // OPTIMIZATION 2: Explicitly check if the user is authenticated
          // This snapshot.hasData check determines the persistent landing page
          if (snapshot.hasData && snapshot.data != null) {
            return const RoleRouter(); 
          }

          // If the user is NOT logged in, show the Intro/Auth flow
          return const IntroPage(); 
        },
      ),
    );
  }
}