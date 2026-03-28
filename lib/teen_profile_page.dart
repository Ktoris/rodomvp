import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'teen_dashboard.dart';
import 'availability_calendar.dart';

class TeenProfilePage extends StatefulWidget {
  const TeenProfilePage({super.key});

  @override
  State<TeenProfilePage> createState() => _TeenProfilePageState();
}

class _TeenProfilePageState extends State<TeenProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController skillInputController = TextEditingController();

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
        surnameController.text.isEmpty ||
        ageController.text.isEmpty ||
        cityController.text.isEmpty ||
        hourlyRateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Add any remaining text in the skill input field before saving
    final remainingSkill = skillInputController.text.trim();
    if (remainingSkill.isNotEmpty) {
      selectedSkills.add(remainingSkill);
      skillInputController.clear();
    }

    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;
    final age = int.tryParse(ageController.text.trim()) ?? 13;
    final rate = double.tryParse(hourlyRateController.text.trim()) ?? 10.0;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': nameController.text.trim(),
      'surname': surnameController.text.trim(),
      'displayName': '${nameController.text.trim()} ${surnameController.text.trim()}',
      'age': age,
      'city': cityController.text.trim(),
      'hourlyRate': rate,
      'bio': bioController.text.trim(),
      'availability': selectedAvailability.toList(),
      'skills': selectedSkills.toList(),
      'avgRating': 0.0,
      'reviewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    // Note: Manual navigation removed. RoleRouter now handles the transition reactively.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Teen Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tell us about yourself!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'First Name *'),
            ),
            TextField(
              controller: surnameController,
              decoration: const InputDecoration(labelText: 'Last Name *'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age *'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: hourlyRateController,
                    decoration: const InputDecoration(labelText: 'Hourly Rate (\$) *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City * (e.g. Austin, TX)'),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell adults a bit about yourself, your goals, and why you are a great hire.',
              ),
            ),

            const SizedBox(height: 20),
            const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AvailabilityCalendar(
              selectedSlots: selectedAvailability,
              onChanged: (newSlots) {
                setState(() {
                  selectedAvailability.clear();
                  selectedAvailability.addAll(newSlots);
                });
              },
            ),

            const SizedBox(height: 20),
            const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: skillInputController,
                    decoration: const InputDecoration(
                      labelText: 'Add a skill',
                      hintText: 'Example: Dog walking',
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
            Wrap(
              spacing: 6,
              children: selectedSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() => selectedSkills.remove(skill));
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Save Profile'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
