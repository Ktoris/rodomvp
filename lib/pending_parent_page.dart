import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rodo_mvp/auth_page.dart';
import 'package:rodo_mvp/role_router.dart';

class PendingParentPage extends StatelessWidget {
  const PendingParentPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  Future<void> _refresh(BuildContext context) async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RoleRouter()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Approval Required'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Waiting for Parent Approval',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We have sent an email to your parent/guardian. You will be able to access your dashboard as soon as they approve your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _refresh(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
