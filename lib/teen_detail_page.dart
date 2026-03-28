import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_job_request_page.dart';
import 'availability_calendar.dart';

class TeenDetailPage extends StatelessWidget {
  final String teenId;
  final String adultId;
  final String adultName;

  const TeenDetailPage({
    super.key,
    required this.teenId,
    required this.adultId,
    required this.adultName,
  });

  // 🔒 Prevent duplicate hire requests + open job form
  Future<void> hireTeen(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    final existingRequest = await firestore
        .collection('hire_requests')
        .where('adultId', isEqualTo: adultId)
        .where('teenId', isEqualTo: teenId)
        .where('status', whereIn: ['pending', 'accepted'])
        .get();

    if (existingRequest.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already have an active request with this teen.',
          ),
        ),
      );
      return;
    }

    final jobData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateJobRequestPage(),
      ),
    );

    if (jobData == null) return;

    final teenSnap = await firestore.collection('users').doc(teenId).get();
    final teenData = teenSnap.data() as Map<String, dynamic>? ?? {};

    await firestore.collection('hire_requests').add({
      'adultId': adultId,
      'adultName': adultName,
      'teenId': teenId,
      'teenName': '${teenData['name'] ?? ''} ${teenData['surname'] ?? ''}',
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'jobTitle': jobData['jobTitle'],
      'jobCategory': jobData['jobCategory'],
      'jobDescription': jobData['jobDescription'],
      'locationType': jobData['locationType'],
      'locationText': jobData['locationText'],
      'locationData': jobData['locationData'], 
      'date': jobData['date'] as DateTime, 
      'duration': jobData['duration'],
      'budget': jobData['budget'],
      'numTeens': jobData['numTeens'],
      'reviewed': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hire request sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teen Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(teenId).get(),
        builder: (context, teenSnapshot) {
          if (!teenSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!teenSnapshot.data!.exists) {
            return const Center(child: Text('Teen profile not found'));
          }

          final teenData = teenSnapshot.data!.data() as Map<String, dynamic>;
          final skills = List<String>.from(teenData['skills'] ?? []);
          final double rating = (teenData['avgRating'] ?? teenData['rating'] ?? 0).toDouble();
          final int reviewCount = ((teenData['reviewCount'] ?? teenData['ratingCount'] ?? 0) as num).toInt();

          final stats = teenData['stats'] ?? {};
          final int jobsDone = (stats['jobsDone'] ?? 0) as int;
          final int totalEarned = (stats['totalEarned'] ?? 0) as int;
          final int lessonsCompleted = (stats['lessonsCompleted'] ?? 0) as int;
          final badges = List<String>.from(teenData['badges'] ?? []);
          final portfolio = List<String>.from(teenData['portfolio'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 HEADER CARD (Centered)
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: teenData['profilePhotoUrl'] != null
                                ? NetworkImage(teenData['profilePhotoUrl'])
                                : null,
                            child: teenData['profilePhotoUrl'] == null
                                ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                                : null,
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${teenData['name'] ?? ''} ${teenData['surname'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (teenData['age'] != null && teenData['city'] != null)
                        Text(
                          '${teenData['age']} yrs • ${teenData['city']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StarRating(rating: rating),
                          const SizedBox(width: 8),
                          Text(
                            '${rating.toStringAsFixed(1)} ★ ($reviewCount)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black.withOpacity(0.4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (teenData['hourlyRate'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF9C4), // Light yellow
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xffFFF176).withOpacity(0.3)),
                          ),
                          child: Text(
                            '\$${teenData['hourlyRate']}/hr',
                            style: const TextStyle(
                              color: Color(0xffF57F17),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // 🔹 HIRE BUTTON (Centered & Smaller)
                      SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          onPressed: () => hireTeen(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff448AFF), // Lighter blue
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Hire This Teen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🔹 METRICS ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _MetricCard(icon: Icons.check_circle_outline, iconColor: Colors.blue, title: 'Jobs Done', value: '$jobsDone')),
                          const SizedBox(width: 12),
                          Expanded(child: _MetricCard(icon: Icons.menu_book, iconColor: const Color(0xff1A237E), title: 'Lessons', value: '$lessonsCompleted')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 🔹 SKILLS
                if (skills.isNotEmpty) ...[
                  const Text(
                    'Skills',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((s) => Chip(
                      label: Text(s),
                      backgroundColor: Colors.blue.shade50,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                // 🔹 BIO
                if (teenData['bio']?.toString().isNotEmpty ?? false) ...[
                  const Text(
                    'Bio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Text(
                      teenData['bio'],
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.7),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // 🔹 AVAILABILITY
                const Text(
                  'Availability',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blue.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.shade900.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: AvailabilityCalendar(
                    selectedSlots: Set<String>.from(teenData['availability'] ?? []),
                    isReadOnly: true,
                  ),
                ),
                const SizedBox(height: 32),

                // 🔹 PORTFOLIO / GALLERY
                if (portfolio.isNotEmpty) ...[
                  const Text(
                    'Portfolio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: portfolio.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(portfolio[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // 🔹 BADGES SECTION
                if (badges.isNotEmpty) ...[
                  const Text(
                    'Badges',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: badges.map((b) => Chip(
                      avatar: const Icon(Icons.military_tech, color: Colors.amber, size: 18),
                      label: Text(b),
                      backgroundColor: Colors.amber.shade50,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                // 🔹 REVIEWS SECTION
                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(teenId).snapshots(),
                  builder: (context, teenSnapshot) {
                    if (!teenSnapshot.hasData) return const SizedBox();
                    final data = teenSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final reviews = (data['reviews'] as List<dynamic>?) ?? [];

                    if (reviews.isEmpty) {
                      return Text('No reviews yet', style: TextStyle(color: Colors.black.withOpacity(0.3), fontStyle: FontStyle.italic));
                    }

                    final sortedReviews = List<Map<String, dynamic>>.from(reviews.whereType<Map<String, dynamic>>())
                      ..sort((a, b) {
                        final aTime = a['createdAt'] as Timestamp?;
                        final bTime = b['createdAt'] as Timestamp?;
                        if (aTime == null || bTime == null) return 0;
                        return bTime.compareTo(aTime);
                      });

                    return Column(
                      children: sortedReviews.take(3).map((review) {
                        final rRating = (review['rating'] ?? 0).toDouble();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.blue.withOpacity(0.1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(review['adultName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    _StarRating(rating: rRating),
                                  ],
                                ),
                                if (review['comment'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text('"${review['comment']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return const Icon(Icons.star, size: 18, color: Colors.amber);
        } else if (rating > index && rating < index + 1) {
          return const Icon(Icons.star_half, size: 18, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 18, color: Colors.amber);
        }
      }),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
