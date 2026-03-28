import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailSent = false;
  Timer? _timer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // ⏱️ Start Heartbeat: Check verification status every 3 seconds automatically
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerificationStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    
    if (user.emailVerified) {
      _timer?.cancel(); // Stop checking once verified
      
      // Update Firestore so RoleRouter knows we are good to go
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'verified': true,
      });
      // The parent RoleRouter will now auto-rebuild and show the Profile Page
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
      setState(() => errorMessage = "Too many requests. Please wait a moment.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Verification', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkBlue,
        actions: [
          TextButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: Text('Logout', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 PREMIUM ICON
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Check Your Inbox',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'We sent a link to ${user?.email ?? 'your email'}.\nClick it to unlock your Rodo account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // 🔄 ANIMATED STATUS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.teal),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Waiting for verification...',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // 📧 RESEND BUTTON
              TextButton(
                onPressed: isEmailSent ? null : _resendVerificationEmail,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  isEmailSent ? 'Email Resent' : 'Didn\'t get it? Resend Email',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: isEmailSent ? Colors.grey : AppTheme.darkBlue,
                  ),
                ),
              ),
              
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
