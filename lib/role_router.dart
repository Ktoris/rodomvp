import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'teen_profile_page.dart';
import 'teen_dashboard.dart';
import 'adult_profile_page.dart';
import 'adult_dashboard.dart';
import 'verify_email_page.dart';
import 'pending_parent_page.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    // 🔒 EMAIL VERIFICATION DISABLED — uncomment to re-enable
    // if (!user.emailVerified) {
    //   return const VerifyEmailPage();
    // }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'];
        final accountStatus = data.containsKey('accountStatus') ? data['accountStatus'] : null;

        // 🔒 GUARDIAN APPROVAL DISABLED — uncomment to re-enable
        // if (role == 'teen' && accountStatus == 'pending_parent') {
        //   return const PendingParentPage();
        // }

        // 🔹 TEEN FLOW
        if (role == 'teen') {
          if (data.containsKey('name')) {
            return TeenDashboard(teenId: user.uid);
          }
          return const TeenProfilePage();
        }

        // 🔹 ADULT FLOW
        if (role == 'adult') {
          if (data.containsKey('name')) {
            return AdultDashboard(adultId: user.uid);
          }
          return const AdultProfilePage();
        }

        // 🔹 Fallback for unknown role
        return const Scaffold(
          body: Center(child: Text('Unknown role')),
        );
      },
    );
  }
}
