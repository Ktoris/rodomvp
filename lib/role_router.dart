import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'teen_profile_page.dart';
import 'teen_dashboard.dart';
import 'adult_profile_page.dart';
import 'adult_dashboard.dart';
import 'verify_email_page.dart';
import 'pending_parent_page.dart';

import 'role_router.dart';
import 'rules_page.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Database Error: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Sign Out & Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snapshot.data!;
        if (!doc.exists) {
          return const Scaffold(
            body: Center(child: Text('User record not found')),
          );
        }

        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'];
        final hasName = data.containsKey('name');
        
        // Check if the user has agreed to rules
        final agreedToRules = data['agreedToRules']?['agreed'] == true;

        // 🔹 TEEN FLOW (3-Step Onboarding)
        if (role == 'teen') {
          if (!hasName) return const TeenProfilePage();
          if (!agreedToRules) return RulesPage(uid: user.uid, isOnboarding: true);
          return TeenDashboard(teenId: user.uid);
        }

        // 🔹 ADULT FLOW (2-Step Onboarding)
        // Restored as perfectly working previously
        if (role == 'adult') {
          if (!hasName) return const AdultProfilePage();
          return AdultDashboard(adultId: user.uid);
        }

        // 🔹 Fallback for unknown role
        return const Scaffold(
          body: Center(child: Text('Unknown role')),
        );
      },
    );
  }
}
