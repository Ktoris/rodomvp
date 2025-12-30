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
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While Firebase is checking the login status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If the user is already logged in, send them to the RoleRouter
          if (snapshot.hasData) {
            return const RoleRouter(); 
          }

          // If the user is NOT logged in, send them to the Login/Signup page
          return const IntroPage(); 
        },
      ),
    );
  }
}