import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
      backgroundColor: AppTheme.backgroundGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 1. PREMIUM HERO SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
              decoration: BoxDecoration(
                color: AppTheme.darkBlue,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkBlue,
                    AppTheme.darkBlue.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT SIDE: TEXT CONTENT
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LOGO AREA (Top Left)
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: AppTheme.teal, size: 22),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'RODO',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          Text(
                            'Your First Job\nStarts Here',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              _words[_wordIndex],
                              key: ValueKey<String>(_words[_wordIndex]),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.teal,
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          ElevatedButton(
                            onPressed: () => _navigateToAuth(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Get Started'),
                          ),
                        ],
                      ),
                    ),
                    // RIGHT SIDE: LARGE LOGO
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          height: 320, // More impactful height
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 2. VALUE PROPOSITIONS (EDITORIAL STYLE)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Column(
                children: [
                  _buildEditorialValueProp(
                    Icons.payments_rounded,
                    'Earn',
                    'Connect with local businesses and neighbors for rewarding work opportunities.',
                  ),
                  const SizedBox(height: 48),
                  _buildEditorialValueProp(
                    Icons.import_contacts_rounded,
                    'Learn',
                    'Access curated lessons and build real-world skills that matter.',
                  ),
                  const SizedBox(height: 48),
                  _buildEditorialValueProp(
                    Icons.trending_up_rounded,
                    'Grow',
                    'Track your progress, build your resume, and unlock your potential.',
                  ),
                ],
              ),
            ),

            // 🔹 3. TOP TEENS SHOWCASE
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VETTED TALENT',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.teal,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Top Teens This Week',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 240,
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
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return _buildModernTeenCard(data);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 4. HIRING SECTION
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBlue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.handshake_rounded, color: AppTheme.teal, size: 48),
                        const SizedBox(height: 24),
                        Text(
                          'Looking to Hire?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Find verified, local teen talent for tasks, tutoring, and more. Safe, professional, and impactful.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => _navigateToAuth(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.darkBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Post a Job'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 FOOTER LITE
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: TextButton(
                onPressed: () => _navigateToAuth(context),
                child: Text(
                  'Already have an account? Log In',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialValueProp(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.teal, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTeenCard(Map<String, dynamic> data) {
    final double rating = (data['avgRating'] ?? 0).toDouble();
    final int jobs = (data['stats']?['jobsDone'] ?? 0);
    final String city = data['city'] ?? 'Local';

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.darkBlue.withOpacity(0.1),
            backgroundImage: data['profilePhotoUrl'] != null
                ? NetworkImage(data['profilePhotoUrl'])
                : null,
            child: data['profilePhotoUrl'] == null
                ? const Icon(Icons.person, size: 40, color: AppTheme.darkBlue)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            data['name'] ?? 'Teen',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.darkBlue,
            ),
          ),
          Text(
            city,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppTheme.accentOrange, size: 16),
                    Text(
                      ' $rating',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$jobs jobs',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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


