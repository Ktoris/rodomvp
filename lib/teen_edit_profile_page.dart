import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'availability_calendar.dart';

class TeenEditProfilePage extends StatefulWidget {
  final String teenId;
  const TeenEditProfilePage({super.key, required this.teenId});

  @override
  State<TeenEditProfilePage> createState() => _TeenEditProfilePageState();
}

class _TeenEditProfilePageState extends State<TeenEditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController skillInputController = TextEditingController();

  final Set<String> selectedAvailability = {};
  final Set<String> selectedSkills = {};

  bool _loading = true;

  void _addSkillFromInput([String? value]) {
    final raw = (value ?? skillInputController.text).trim();
    if (raw.isEmpty) return;
    setState(() {
      selectedSkills.add(raw);
      skillInputController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid != widget.teenId) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.teenId).get();
    final data = doc.data();

    if (data != null) {
      nameController.text = data['name'] ?? '';
      surnameController.text = data['surname'] ?? '';
      bioController.text = data['bio'] ?? '';
      cityController.text = data['city'] ?? '';
      hourlyRateController.text = (data['hourlyRate'] ?? '').toString();

      final availability = data['availability'];
      if (availability is List) {
        selectedAvailability.clear();
        selectedAvailability.addAll(availability.whereType<String>());
      }
      final skills = data['skills'];
      if (skills is List) {
        selectedSkills.clear();
        selectedSkills.addAll(skills.whereType<String>());
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty || surnameController.text.isEmpty) return;

    final remainingSkill = skillInputController.text.trim();
    if (remainingSkill.isNotEmpty) {
      selectedSkills.add(remainingSkill);
      skillInputController.clear();
    }

    final rate = double.tryParse(hourlyRateController.text.trim()) ?? 10.0;

    await FirebaseFirestore.instance.collection('users').doc(widget.teenId).update({
      'name': nameController.text.trim(),
      'surname': surnameController.text.trim(),
      'displayName': '${nameController.text.trim()} ${surnameController.text.trim()}',
      'bio': bioController.text.trim(),
      'city': cityController.text.trim(),
      'hourlyRate': rate,
      'availability': selectedAvailability.toList(),
      'skills': selectedSkills.toList(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'First Name')),
            TextField(controller: surnameController, decoration: const InputDecoration(labelText: 'Last Name')),
            Row(
              children: [
                Expanded(child: TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City'))),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: hourlyRateController,
                    decoration: const InputDecoration(labelText: 'Hourly Rate (\$)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio', hintText: 'Tell adults a bit about yourself'),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: skillInputController,
                    decoration: const InputDecoration(labelText: 'Add a skill'),
                    onSubmitted: _addSkillFromInput,
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: () => _addSkillFromInput()),
              ],
            ),
            Wrap(
              spacing: 6,
              children: selectedSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => selectedSkills.remove(skill)),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
