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
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RoleRouter()),
        );
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
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (!isLogin) ...[
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'teen', child: Text('Teen')),
                  DropdownMenuItem(value: 'adult', child: Text('Adult')),
                ],
                onChanged: (value) {
                  setState(() {
                    role = value!;
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submit,
              child: Text(isLogin ? 'Login' : 'Create Account'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(
                isLogin ? 'Create an account' : 'Already have an account?',
              ),
            ),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
