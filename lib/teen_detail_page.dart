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
      'jobDescription': jobData['jobDescription'],
      'locationType': jobData['locationType'],
      'locationText': jobData['locationText'],
      'dateType': jobData['dateType'],
      'startDate': jobData['startDate'],
      'endDate': jobData['endDate'],
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
            .collection('teens')
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 HEADER: Name and Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${teenData['name']} ${teenData['surname']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StarRating(rating: rating),
                    const SizedBox(width: 8),
                    Text(
                      '${rating.toStringAsFixed(1)} ★ ($reviewCount reviews)',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
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

                // 🔹 QUALIFICATIONS
                if (teenData['qualifications']?.toString().isNotEmpty ?? false) ...[
                  const Text(
                    'Qualifications',
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
                      teenData['qualifications'],
                      style: const TextStyle(fontSize: 14),
                    ),
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
                      .collection('teens')
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
                      children: sortedReviews.map((reviewData) {
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
                            Text(reviewComment),
                          ]);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
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

