import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background color is inherited from AppTheme.backgroundGrey
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. BRAND NAME (Rodo)
              Text(
                'Rodo',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryMint, // Using your nice green
                  letterSpacing: -2.0,
                ),
              ),
              const SizedBox(height: 40),

              // 2. MISSION STATEMENT & DESCRIPTION
              const Text(
                'Rodo is a service marketplace designed to empower teenagers to work, earn money, gain real-world experience, and build useful skills.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Many young people want to start working but don’t know where to begin—they lack connections, guidance, and opportunities. Our platform solves this problem by connecting teenagers with individuals, families, and businesses that need help with everyday tasks, creative projects, and community activities.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Through our app, adults and companies can easily hire teenagers for tasks such as washing cars, mowing lawns, babysitting, tutoring, designing logos, organizing items, and more. Beyond paid work, Rodo includes a community and charity section for volunteer tasks and youth entrepreneurship.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'To support learning and growth, the platform features a dedicated Learn tab where teenagers can access simple skill-building lessons—helping them gain confidence and increase their earning potential.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              
              const SizedBox(height: 60),

              // 3. AUTHENTICATION BUTTONS
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthPage()),
                        );
                      },
                      child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                      );
                    },
                    child: Text(
                      'Already have an account? Log In',
                      style: TextStyle(
                        color: AppTheme.primaryMint,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}