import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'auth_page.dart';
import 'dart:async';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with SingleTickerProviderStateMixin {
  final List<String> _words = ['Earn.', 'Learn.', 'Grow.'];
  int _wordIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _wordIndex = (_wordIndex + 1) % _words.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // 🔹 1. HERO SECTION (Animated)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      'Your First Job Starts Here',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        _words[_wordIndex],
                        key: ValueKey<String>(_words[_wordIndex]),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // 🔹 2. VALUE PROPOSITIONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildValueProp(Icons.location_on, 'Find Local\nWork'),
                    _buildValueProp(Icons.school, 'Build Real\nSkills'),
                    _buildValueProp(Icons.payments, 'Get Paid\nFast'),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // 🔹 3. TOP TEENS SECTION
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Top Teens This Week',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'teen')
                      .where('accountStatus', isEqualTo: 'active')
                      .orderBy('discoveryScore', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Coming soon!'));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _buildTeenCard(data);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 60),

              // 🔹 4. CTA BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    _buildCTAButton(
                      'I\'m a Teen',
                      'Find work and build your career',
                      AppTheme.primaryBlue,
                      () => _navigateToAuth(context),
                    ),
                    const SizedBox(height: 16),
                    _buildCTAButton(
                      'I\'m Hiring',
                      'Find the best local help',
                      Colors.black87,
                      () => _navigateToAuth(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 LOGIN LINK
              TextButton(
                onPressed: () => _navigateToAuth(context),
                child: Text(
                  'Already have an account? Log In',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueProp(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 32),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTeenCard(Map<String, dynamic> data) {
    final double rating = (data['avgRating'] ?? 0).toDouble();
    final int jobs = (data['stats']?['jobsDone'] ?? 0);
    final String city = data['city'] ?? 'Local';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 35,
            backgroundImage: data['profilePhotoUrl'] != null
                ? NetworkImage(data['profilePhotoUrl'])
                : null,
            child: data['profilePhotoUrl'] == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            data['name'] ?? 'Teen',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            city,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(
                      ' $rating',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  '$jobs jobs',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }
}