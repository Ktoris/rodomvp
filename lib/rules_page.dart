import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RulesPage extends StatefulWidget {
  final String uid;
  final bool isOnboarding;

  const RulesPage({super.key, required this.uid, this.isOnboarding = false});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  bool _agreed = false;
  bool _isLoading = false;

  Future<void> _submitAgreement() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'agreedToRules': {
          'agreed': true,
          'agreedAt': FieldValue.serverTimestamp(),
        }
      });
      if (mounted) {
        if (widget.isOnboarding) {
          Navigator.pop(context);
        } else {
          // If forced from dashboard, we might want to refresh or pop
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving agreement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Guidelines'),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'For Teens',
              Icons.person,
              [
                'Be on time for every job.',
                'Communicate issues or delays early.',
                'Keep all contact within the Rodo app.',
                'No sharing personal addresses with strangers.',
                'Complete jobs fully and professionally.',
              ],
            ),
            _buildSection(
              'For Adults',
              Icons.person_outline,
              [
                'Treat teens with respect and kindness.',
                'Pay the agreed amount promptly.',
                'Never request inappropriate or dangerous tasks.',
                'Ensure a safe environment for the work.',
              ],
            ),
            _buildSection(
              'Safety Rules',
              Icons.security,
              [
                'All payments must go through the platform.',
                'Report any suspicious behavior immediately.',
                'No in-person contact without a confirmed job code.',
                'Parental supervision is recommended for younger teens.',
              ],
            ),
            _buildSection(
              'Prohibited Tasks',
              Icons.block,
              [
                'Adult content or orientation.',
                'Anything illegal or involving hazardous materials.',
                'Unaccompanied overnight tasks for those under 16.',
                'Tasks requiring specialized licenses (e.g., driving heavy machinery).',
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (val) => setState(() => _agreed = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the community guidelines and safety rules.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_agreed && !_isLoading) ? _submitAgreement : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Agree & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> rules) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(rule, style: const TextStyle(height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
