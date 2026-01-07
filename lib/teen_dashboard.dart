import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ✅ IMPORT ADDED
import 'chat_page.dart';
import 'teen_edit_profile_page.dart';

class TeenDashboard extends StatelessWidget {
  final String teenId;

  const TeenDashboard({super.key, required this.teenId});

  @override
  Widget build(BuildContext context) {
    final pendingRequests = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('teenId', isEqualTo: teenId)
        .where('status', isEqualTo: 'pending');

    final acceptedRequests = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('teenId', isEqualTo: teenId)
        .where('status', isEqualTo: 'accepted');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeenEditProfilePage(teenId: teenId),
            ),
          );
        },
        tooltip: 'Edit Profile',
        child: const Icon(Icons.edit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 FULL PROFILE VIEW
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
                final skills = List<String>.from(teenData['skills'] ?? []);
                final double rating =
                    (teenData['avgRating'] ?? teenData['rating'] ?? 0)
                        .toDouble();
                final int reviewCount =
                    ((teenData['reviewCount'] ??
                            teenData['ratingCount'] ??
                            0) as num)
                        .toInt();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 HEADER: Name and Rating
                    Text(
                      '${teenData['name'] ?? ''} ${teenData['surname'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                    Text(
                      'Reviews ($reviewCount)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Builder(
                      builder: (context) {
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
                            final createdAt =
                                reviewData['createdAt'] as Timestamp?;
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
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Colors.grey.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: children,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            // 🔹 PENDING REQUESTS
            const Text(
              'Pending Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream: pendingRequests.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'No pending requests',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['jobTitle'] ?? 'Job',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(data['jobDescription'] ?? ''),
                            const SizedBox(height: 6),

                            Text(
                              'From: ${data['adultName']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              data['locationType'] == 'remote'
                                  ? 'Remote'
                                  : 'Location: ${data['locationText']}',
                            ),

                            Text(
                              data['dateType'] == 'anytime'
                                  ? 'Anytime'
                                  : 'From ${_formatDate(data['startDate'])} to ${_formatDate(data['endDate'])}',
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  tooltip: 'Accept',
                                  // 🔄 UPDATED ACCEPT LOGIC
                                  onPressed: () async {
                                    await doc.reference.update({
                                      'status': 'accepted',
                                    });

                                    // ✅ CREATE CHAT (once)
                                    await FirebaseFirestore.instance
                                        .collection('chats')
                                        .doc(doc.id)
                                        .set({
                                      'adultId': data['adultId'],
                                      'teenId': teenId,
                                      'jobTitle': data['jobTitle'],
                                      'lastMessage': '',
                                      'lastMessageAt': Timestamp.now(),
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Ignore',
                                  onPressed: () {
                                    doc.reference.update({
                                      'status': 'ignored',
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // 🔹 ACCEPTED JOBS
            const Text(
              'Accepted Jobs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream: acceptedRequests.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'No active jobs',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['jobTitle'] ?? 'Job',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(data['jobDescription'] ?? ''),
                            const SizedBox(height: 6),
                            Text(
                              'Working for ${data['adultName']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 🔄 UPDATED BUTTON SECTION (CHAT + COMPLETE)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          chatId: doc.id,
                                          title: data['jobTitle'] ?? 'Chat',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Chat'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    doc.reference.update({
                                      'status': 'completed',
                                      'completedAt': Timestamp.now(),
                                      'canReview': true,
                                      'reviewed': false,
                                    });
                                  },
                                  child: const Text('Mark as Completed'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper to format Firestore Timestamp
  static String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
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