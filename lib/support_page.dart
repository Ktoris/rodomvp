import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _category = 'Other';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Bug',
    'Payment',
    'Safety',
    'Account',
    'Other'
  ];

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('support').add({
        'uid': user.uid,
        'email': user.email,
        'category': _category,
        'description': _descriptionController.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How can we help?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please describe the issue you are facing and we will get back to you as soon as possible.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Minimum 20 characters...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 20) {
                    return 'Please enter at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Fallback: support@rodomvp.com',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
