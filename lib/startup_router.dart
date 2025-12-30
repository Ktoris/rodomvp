import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this

import 'account_selection_page.dart';
import 'teen_dashboard.dart';
import 'adult_dashboard.dart'; // 1. Change the import

class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});

  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final user = FirebaseAuth.instance.currentUser; // 2. Get current Firebase user

    if (role == 'teen') {
      final teenId = prefs.getString('teenId');
      if (teenId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeenDashboard(teenId: teenId)),
        );
        return;
      }
    }

    if (role == 'adult' && user != null) {
      // 3. Send to AdultDashboard with the UID
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdultDashboard(adultId: user.uid)),
      );
      return;
    }

    // Default fallback
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AccountSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}