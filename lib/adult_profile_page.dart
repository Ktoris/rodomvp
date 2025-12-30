import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'adult_dashboard.dart';

class AdultProfilePage extends StatefulWidget {
  const AdultProfilePage({super.key});

  @override
  State<AdultProfilePage> createState() => _AdultProfilePageState();
}

class _AdultProfilePageState extends State<AdultProfilePage> {
  final TextEditingController nameController = TextEditingController();

  Future<void> saveProfile() async {
    if (nameController.text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('adults').doc(uid).set({
      'name': nameController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AdultDashboard(adultId: uid)), //just one const
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('adults').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🚫 Profile already exists → skip setup forever
        if (snapshot.data!.exists) {
          return AdultDashboard(adultId: uid);
        }

        // ✅ First-time setup
        return Scaffold(
          appBar: AppBar(title: const Text('Create Adult Profile')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveProfile,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
