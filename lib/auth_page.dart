import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rodo_mvp/role_router.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final parentEmailController = TextEditingController();

  String role = 'teen'; // teen or adult
  bool isLogin = true;
  String error = '';

  Future<void> submit() async {
    try {
      UserCredential userCredential;

      if (isLogin) {
        // 🔹 LOGIN
        userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final uid = userCredential.user!.uid;
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(uid);

        final snapshot = await userDoc.get();

        // 🔥 SAFETY NET: recreate user doc if missing
        if (!snapshot.exists) {
          await userDoc.set({
            'email': emailController.text.trim(),
            'role': 'teen', // default fallback (or handle later)
            'createdAt': FieldValue.serverTimestamp(),
            'recovered': true, // optional debug flag
          });
        }
      } else {
        // 🔹 SIGN UP
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final uid = userCredential.user!.uid;

        // ✅ ALWAYS create users/{uid}
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': role,
          'email': emailController.text.trim(),
          'verified': false,
          'accountStatus': 'active', // was 'pending_email' — changed while email verification is disabled
          // if (role == 'teen') 'parentEmail': parentEmailController.text.trim(), // 🔒 GUARDIAN DISABLED
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 📧 EMAIL VERIFICATION DISABLED — uncomment to re-enable
        // await userCredential.user!.sendEmailVerification();
      }
      if (mounted) {
        // Removed manual navigation to RoleRouter. 
        // main.dart's StreamBuilder will catch the auth state change and show RoleRouter.
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🎨 HEADER
                  Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin 
                        ? 'Sign in to continue to Rodo' 
                        : 'Join us and start managing tasks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 📦 AUTH CARD
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'I am a:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'teen',
                                  label: Text('Teen'),
                                  icon: Icon(Icons.person_outline),
                                ),
                                ButtonSegment(
                                  value: 'adult',
                                  label: Text('Adult'),
                                  icon: Icon(Icons.supervisor_account_outlined),
                                ),
                              ],
                              selected: {role},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  role = newSelection.first;
                                });
                              },
                            ),
                            // 🔒 GUARDIAN EMAIL FIELD DISABLED — uncomment to re-enable
                            // if (role == 'teen') ...[
                            //   const SizedBox(height: 20),
                            //   TextField(
                            //     controller: parentEmailController,
                            //     decoration: const InputDecoration(
                            //       labelText: 'Parent/Guardian Email',
                            //       prefixIcon: Icon(Icons.family_restroom),
                            //     ),
                            //     keyboardType: TextInputType.emailAddress,
                            //   ),
                            // ],
                          ],
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(isLogin ? 'Login' : 'Get Started'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔄 TOGGLE AUTH MODE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin ? "Don't have an account?" : "Already have an account?",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            error = '';
                          });
                        },
                        child: Text(
                          isLogin ? 'Sign Up' : 'Log In',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
