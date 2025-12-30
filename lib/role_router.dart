import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'teen_profile_page.dart';
import 'teen_dashboard.dart';
import 'adult_profile_page.dart';
import 'adult_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

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

        final role = snapshot.data!['role'];

        // 🔹 TEEN FLOW
        if (role == 'teen') {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('teens')
                .doc(user.uid)
                .get(),
            builder: (context, teenSnapshot) {
              if (!teenSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (teenSnapshot.data!.exists) {
                // Teen has profile → go to dashboard
                return TeenDashboard(teenId: user.uid);
              }

              // Teen has no profile → create profile
              return const TeenProfilePage();
            },
          );
        }

        // 🔹 ADULT FLOW
        if (role == 'adult') {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('adults')
                .doc(user.uid)
                .get(),
            builder: (context, adultSnapshot) {
              if (!adultSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (adultSnapshot.data!.exists) {
                // Adult has profile → go to dashboard
                return AdultDashboard(adultId: user.uid);
              }

              // Adult has no profile → create profile
              return const AdultProfilePage();
            },
          );
        }

        // 🔹 Fallback for unknown role
        return const Scaffold(
          body: Center(child: Text('Unknown role')),
        );
      },
    );
  }
}
