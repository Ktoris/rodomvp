import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_job_request_page.dart';

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

    await firestore.collection('hire_requests').add({
      'adultId': adultId,
      'adultName': adultName,
      'teenId': teenId,
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'jobTitle': jobData['jobTitle'],
      'jobCategory': jobData['jobCategory'],
      'jobDescription': jobData['jobDescription'],
      'locationType': jobData['locationType'],
      'locationText': jobData['locationText'],
      'locationData': jobData['locationData'], // 📍 NEW
      'date': jobData['date'] as DateTime, // 📅 NEW
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
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(teenId)
            .get(),
        builder: (context, teenSnapshot) {
          if (!teenSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!teenSnapshot.data!.exists) {
            return const Center(child: Text('Teen profile not found'));
          }

          final teenData =
              teenSnapshot.data!.data() as Map<String, dynamic>;
          final skills = List<String>.from(teenData['skills'] ?? []);
          final double rating =
              (teenData['avgRating'] ?? teenData['rating'] ?? 0).toDouble();
          final int reviewCount =
              ((teenData['reviewCount'] ?? teenData['ratingCount'] ?? 0) as num)
                  .toInt();

          final stats = teenData['stats'] ?? {};
          final int jobsDone = (stats['jobsDone'] ?? 0) as int;
          final int totalEarned = (stats['totalEarned'] ?? 0) as int;
          final int lessonsCompleted = (stats['lessonsCompleted'] ?? 0) as int;
          final int repeatHires = (stats['repeatHires'] ?? 0) as int;
          final badges = List<String>.from(teenData['badges'] ?? []);
          final portfolio = List<String>.from(teenData['portfolio'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 HEADER CARD
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: teenData['profilePhotoUrl'] != null
                            ? NetworkImage(teenData['profilePhotoUrl'])
                            : null,
                        child: teenData['profilePhotoUrl'] == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${teenData['name'] ?? ''} ${teenData['surname'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (teenData['age'] != null && teenData['city'] != null)
                        Text(
                          '${teenData['age']} yrs • ${teenData['city']}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StarRating(rating: rating),
                          const SizedBox(width: 8),
                          Text(
                            '${rating.toStringAsFixed(1)} ★ ($reviewCount)',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (repeatHires > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '✔ $repeatHires people would hire again',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (teenData['hourlyRate'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$${teenData['hourlyRate']}/hr',
                            style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 🔹 HIRE BUTTON (Top)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => hireTeen(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Hire This Teen'),
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 PERFORMANCE METRICS STRIP (Horizontal Scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MetricCard(icon: Icons.check_circle_outline, title: 'Jobs Done', value: '$jobsDone'),
                      _MetricCard(icon: Icons.attach_money, title: 'Earned', value: '\$${(totalEarned / 100).toStringAsFixed(2)}'),
                      _MetricCard(icon: Icons.menu_book, title: 'Lessons', value: '$lessonsCompleted'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 SKILLS
                if (skills.isNotEmpty) ...[
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((s) => Chip(
                              label: Text(s),
                              backgroundColor: Colors.blue.shade50,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // 🔹 BIO
                if (teenData['bio']?.toString().isNotEmpty ?? false) ...[
                  const Text(
                    'Bio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      teenData['bio'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 🔹 PORTFOLIO / GALLERY
                if (portfolio.isNotEmpty) ...[
                  const Text(
                    'Portfolio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: portfolio.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(portfolio[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 🔹 BADGES SECTION
                if (badges.isNotEmpty) ...[
                  const Text(
                    'Badges',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: badges.map((b) => Chip(
                      avatar: const Icon(Icons.military_tech, color: Colors.amber),
                      label: Text(b),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // 🔹 REVIEWS SECTION
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(teenId)
                      .snapshots(),
                  builder: (context, teenSnapshot) {
                    if (!teenSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final teenData =
                        teenSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final reviews = 
                        (teenData['reviews'] as List<dynamic>?) ?? [];

                    if (reviews.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No reviews yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    // Sort reviews by createdAt descending
                    final sortedReviews = List<Map<String, dynamic>>.from(
                      reviews.whereType<Map<String, dynamic>>()
                    )..sort((a, b) {
                      final aTime = a['createdAt'] as Timestamp?;
                      final bTime = b['createdAt'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    return Column(
                      children: sortedReviews.take(3).map((reviewData) { // Display top 3 reviews
                        final reviewRating =
                            (reviewData['rating'] ?? 0).toDouble();
                        final reviewComment =
                            reviewData['comment']?.toString() ?? '';
                        final createdAt = reviewData['createdAt'] as Timestamp?;
                        final reviewerName =
                            reviewData['adultName']?.toString() ?? 'Anonymous';

                        final children = <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reviewerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _StarRating(rating: reviewRating),
                              const SizedBox(width: 4),
                              Text(
                                reviewRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ];

                        if (createdAt != null) {
                          children.addAll([
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ]);
                        }

                        if (reviewComment.isNotEmpty) {
                          children.addAll([
                            const SizedBox(height: 8),
                            Text('"$reviewComment"', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ]);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 🔹 HIRE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => hireTeen(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Hire This Teen'),
                  ),
                ),
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

/// ⭐ Star rating widget
class _StarRating extends StatelessWidget {
  final double rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return const Icon(Icons.star, size: 20, color: Colors.amber);
        } else if (rating > index && rating < index + 1) {
          return const Icon(Icons.star_half, size: 20, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 20, color: Colors.amber);
        }
      }),
    );
  }
}

// 🔹 Metric Card for Profile Strip
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
