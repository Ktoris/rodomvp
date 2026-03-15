import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rodo_mvp/auth_page.dart';
import 'package:rodo_mvp/role_router.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailSent = false;
  String? errorMessage;

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final role = doc.data()?['role'];
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'verified': true,
            'accountStatus': role == 'teen' ? 'pending_parent' : 'active',
          });
        }
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const RoleRouter()),
          );
        }
      } else {
        setState(() {
          errorMessage = "Email not verified yet. Please check your inbox.";
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        setState(() {
          isEmailSent = true;
          errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!')),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify your email address',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A verification email has been sent to ${user?.email ?? 'your email'}. Please click the link in the email to continue.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkVerificationStatus,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('I HAVE VERIFIED MY EMAIL'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: isEmailSent ? null : _resendVerificationEmail,
              child: Text(isEmailSent ? 'Email Resent' : 'Resend Verification Email'),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
