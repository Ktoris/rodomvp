import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeenEditProfilePage extends StatefulWidget {
  final String teenId;

  const TeenEditProfilePage({super.key, required this.teenId});

  @override
  State<TeenEditProfilePage> createState() => _TeenEditProfilePageState();
}

class _TeenEditProfilePageState extends State<TeenEditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController qualificationsController =
      TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController skillInputController = TextEditingController();

  final List<String> availabilityOptions = const [
    'Weekdays',
    'Weekends',
    'Evenings',
    'Anytime',
  ];
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
    // Extra safety: only allow editing own profile
    if (uid == null || uid != widget.teenId) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('teens')
        .doc(widget.teenId)
        .get();

    final data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      nameController.text = data['name'] ?? '';
      surnameController.text = data['surname'] ?? '';
      qualificationsController.text = data['qualifications'] ?? '';
      bioController.text = data['bio'] ?? '';

      final availability = data['availability'];
      if (availability is List) {
        selectedAvailability
          ..clear()
          ..addAll(availability.whereType<String>());
      }

      final skills = data['skills'];
      if (skills is List) {
        selectedSkills
          ..clear()
          ..addAll(skills.whereType<String>());
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty || surnameController.text.isEmpty) return;

    // Add any remaining text in the skill input field before saving
    final remainingSkill = skillInputController.text.trim();
    if (remainingSkill.isNotEmpty) {
      selectedSkills.add(remainingSkill);
      skillInputController.clear();
    }

    await FirebaseFirestore.instance
        .collection('teens')
        .doc(widget.teenId)
        .update({
      'name': nameController.text.trim(),
      'surname': surnameController.text.trim(),
      'qualifications': qualificationsController.text.trim(),
      'bio': bioController.text.trim(),
      'availability': selectedAvailability.toList(),
      'skills': selectedSkills.toList(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              decoration: const InputDecoration(labelText: 'Qualifications'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell adults a bit about yourself',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Availability',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: availabilityOptions.map((option) {
                final selected = selectedAvailability.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedAvailability.add(option);
                      } else {
                        selectedAvailability.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
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


