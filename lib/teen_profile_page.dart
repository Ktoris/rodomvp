import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'teen_dashboard.dart';

class TeenProfilePage extends StatefulWidget {
  const TeenProfilePage({super.key});

  @override
  State<TeenProfilePage> createState() => _TeenProfilePageState();
}

class _TeenProfilePageState extends State<TeenProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController qualificationsController =
      TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController skillInputController = TextEditingController();

  // 🔹 Structured availability (for filtering later)
  final List<String> availabilityOptions = [
    'Weekdays',
    'Weekends',
    'Evenings',
    'Anytime',
  ];
  final Set<String> selectedAvailability = {};

  final Set<String> selectedSkills = {};

  void _addSkillFromInput([String? value]) {
    final raw = (value ?? skillInputController.text).trim();
    if (raw.isEmpty) return;

    setState(() {
      selectedSkills.add(raw);
      skillInputController.clear();
    });
  }

  Future<void> saveProfile() async {
    if (nameController.text.isEmpty ||
        surnameController.text.isEmpty) return;

    // Add any remaining text in the skill input field before saving
    final remainingSkill = skillInputController.text.trim();
    if (remainingSkill.isNotEmpty) {
      selectedSkills.add(remainingSkill);
      skillInputController.clear();
    }

    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    await FirebaseFirestore.instance.collection('teens').doc(uid).set({
      'name': nameController.text.trim(),
      'surname': surnameController.text.trim(),
      'qualifications': qualificationsController.text.trim(),
      'bio': bioController.text.trim(),
      'availability': selectedAvailability.toList(),
      'skills': selectedSkills.toList(),
      // unified rating fields for reviews
      'avgRating': 0.0,
      'reviewCount': 0,
      'reviews': [], // Initialize empty reviews array
      'profilePhotoUrl': null, // later
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TeenDashboard(teenId: uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('teens').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🚫 Profile already exists → skip creation
        if (snapshot.data!.exists) {
          return TeenDashboard(teenId: uid);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Create Teen Profile')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 BASIC INFO
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: surnameController,
                  decoration: const InputDecoration(labelText: 'Surname'),
                ),
                TextField(
                  controller: qualificationsController,
                  decoration:
                      const InputDecoration(labelText: 'Qualifications'),
                ),

                const SizedBox(height: 16),

                // 🔹 BIO
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell adults a bit about yourself',
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 AVAILABILITY
                const Text(
                  'Availability',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: availabilityOptions.map((option) {
                    final selected =
                        selectedAvailability.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          value
                              ? selectedAvailability.add(option)
                              : selectedAvailability.remove(option);
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 🔹 SKILLS (free text tags)
                const Text(
                  'Skills',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skillInputController,
                        decoration: const InputDecoration(
                          labelText: 'Add a skill',
                          hintText:
                              'Example: Dog walking, Computer Repairing (one skill at a time)',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: _addSkillFromInput,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addSkillFromInput(),
                      tooltip: 'Add skill',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: selectedSkills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          selectedSkills.remove(skill);
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                Center(
                  child: ElevatedButton(
                    onPressed: saveProfile,
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
