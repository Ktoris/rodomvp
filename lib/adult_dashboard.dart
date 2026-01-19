import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_job_request_page.dart';
import 'chat_page.dart';
import 'teen_detail_page.dart';

class AdultDashboard extends StatefulWidget {
  final String adultId;

  const AdultDashboard({super.key, required this.adultId});

  @override
  State<AdultDashboard> createState() => _AdultDashboardState();
}

class _AdultDashboardState extends State<AdultDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get adultId => widget.adultId;

  // 🔹 Get adult name once
  Future<String> getAdultName() async {
    final doc = await FirebaseFirestore.instance
        .collection('adults')
        .doc(adultId)
        .get();

    return doc.data()?['name'] ?? '';
  }

  // 🔒 Prevent duplicate hire requests + open job form
  Future<void> hireTeen(
    BuildContext context,
    String teenId,
    String adultName,
  ) async {
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
    final teensCollection = FirebaseFirestore.instance.collection('teens');

    final activeJobsQuery = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('adultId', isEqualTo: adultId)
        .where('status', isEqualTo: 'accepted');

    final completedJobsQuery = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('adultId', isEqualTo: adultId)
        .where('status', isEqualTo: 'completed');

    return FutureBuilder<String>(
      future: getAdultName(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final adultName = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Adult Dashboard')),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                'Browse Teens',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 🔹 SEARCH BAR
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by skill (e.g., Dog walking, Tutoring)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 TEEN BROWSER
              StreamBuilder<QuerySnapshot>(
                stream: teensCollection.snapshots(),
                builder: (context, teenSnapshot) {
                  if (!teenSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final teenDocs = teenSnapshot.data!.docs;
                  if (teenDocs.isEmpty) return const Text('No teens available');

                  final filteredTeens = teenDocs.where((teen) {
                    if (_searchQuery.isEmpty) return true;
                    final data = teen.data() as Map<String, dynamic>;
                    final skills = List<String>.from(data['skills'] ?? []);
                    return skills.any((skill) =>
                        skill.toLowerCase().contains(_searchQuery));
                  }).toList();

                  if (filteredTeens.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No teens found with that skill',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: filteredTeens.map((teen) {
                      final data = teen.data() as Map<String, dynamic>;
                      final skills = List<String>.from(data['skills'] ?? []);
                      final double rating =
                          (data['avgRating'] ?? data['rating'] ?? 0).toDouble();
                      final int reviewCount =
                          ((data['reviewCount'] ?? data['ratingCount'] ?? 0)
                                  as num)
                              .toInt();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeenDetailPage(
                                  teenId: teen.id,
                                  adultId: adultId,
                                  adultName: adultName,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data['name']} ${data['surname']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _StarRating(rating: rating),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${rating.toStringAsFixed(1)} ★ ($reviewCount)',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                if (skills.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: skills
                                        .map((s) => Chip(label: Text(s)))
                                        .toList(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => hireTeen(
                                      context,
                                      teen.id,
                                      adultName,
                                    ),
                                    child: const Text('Hire'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 🔹 ACTIVE JOBS (UPDATED WITH CLICKABLE NAME)
              const Text(
                'Active Jobs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: activeJobsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  if (snapshot.data!.docs.isEmpty) {
                    return const Text('No active jobs',
                        style: TextStyle(color: Colors.grey));
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        color: Colors.blue.shade50,
                        child: ListTile(
                          title: Text(data['jobTitle'] ?? 'Job'),
                          subtitle: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('teens')
                                .doc(data['teenId'])
                                .get(),
                            builder: (context, teenSnapshot) {
                              if (!teenSnapshot.hasData) {
                                return const Text('Loading teen...');
                              }

                              final teenData = teenSnapshot.data?.data()
                                  as Map<String, dynamic>?;
                              final teenName = teenData != null
                                  ? '${teenData['name']} ${teenData['surname']}'
                                  : 'Unknown Teen';

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeenDetailPage(
                                        teenId: data['teenId'],
                                        adultId: adultId,
                                        adultName: adultName,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Teen: $teenName',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('Chat'),
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
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 🔹 COMPLETED JOBS + REVIEWS
              const Text(
                'Completed Jobs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: completedJobsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Text(
                      'No completed jobs yet',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final teenId = data['teenId'] as String;

                      return Card(
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('teens')
                              .doc(teenId)
                              .get(),
                          builder: (context, teenSnapshot) {
                            String teenName = 'Loading...';
                            bool hasReviewedTeen = false;

                            if (teenSnapshot.hasData &&
                                teenSnapshot.data!.exists) {
                              final teenData = teenSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              teenName =
                                  '${teenData['name'] ?? ''} ${teenData['surname'] ?? ''}'
                                      .trim();
                              if (teenName.isEmpty) teenName = 'Unknown Teen';

                              final reviews =
                                  (teenData['reviews'] as List<dynamic>?) ?? [];
                              hasReviewedTeen = reviews
                                  .any((r) => r['adultId'] == adultId);
                            } else if (teenSnapshot.hasData &&
                                !teenSnapshot.data!.exists) {
                              teenName = 'Teen not found';
                            }

                            return ListTile(
                              title: Text(data['jobTitle'] ?? 'Job'),
                              subtitle: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeenDetailPage(
                                        teenId: teenId,
                                        adultId: adultId,
                                        adultName: adultName,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Teen: $teenName',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              trailing:
                                  (data['reviewed'] == true || hasReviewedTeen)
                                      ? ElevatedButton(
                                          onPressed: null, // Disabled
                                          style: ElevatedButton.styleFrom(
                                            disabledBackgroundColor:
                                                Colors.grey.shade300,
                                            disabledForegroundColor:
                                                Colors.grey.shade600,
                                          ),
                                          child: const Text('Already reviewed'),
                                        )
                                      : ElevatedButton(
                                          onPressed: () =>
                                              _handleLeaveReviewTap(
                                            context,
                                            doc.id,
                                            teenId,
                                          ),
                                          child: const Text('Leave Review'),
                                        ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔒 Ensure only one review per adult–teen pair
  Future<void> _handleLeaveReviewTap(
    BuildContext context,
    String hireRequestId,
    String teenId,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final teenDoc = await firestore.collection('teens').doc(teenId).get();
    final teenData = teenDoc.data() ?? {};
    final reviews = teenData['reviews'] as List<dynamic>? ?? [];

    final hasReviewed = reviews.any((review) =>
        review is Map<String, dynamic> && review['adultId'] == adultId);

    if (hasReviewed) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Already reviewed'),
            content: const Text('You have already reviewed this person.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    _openReviewDialog(context, hireRequestId, teenId);
  }

  // ⭐ Review dialog + Firestore transaction
  void _openReviewDialog(
    BuildContext context,
    String hireRequestId,
    String teenId,
  ) async {
    final adultName = await getAdultName();

    double ratingValue = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<double>(
                value: ratingValue,
                items: [1, 2, 3, 4, 5]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v.toDouble(),
                        child: Text('$v Stars'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => ratingValue = v!),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final firestore = FirebaseFirestore.instance;

                await firestore.runTransaction((tx) async {
                  final teenRef = firestore.collection('teens').doc(teenId);
                  final teenSnap = await tx.get(teenRef);
                  final teenData = teenSnap.data() ?? {};

                  final double oldAvg =
                      (teenData['avgRating'] ?? teenData['rating'] ?? 0)
                          .toDouble();
                  final int oldCount =
                      ((teenData['reviewCount'] ?? teenData['ratingCount'] ?? 0)
                              as num)
                          .toInt();

                  final newAvg =
                      ((oldAvg * oldCount) + ratingValue) / (oldCount + 1);

                  final existingReviews =
                      (teenData['reviews'] as List<dynamic>?) ?? [];

                  final newReview = {
                    'adultId': adultId,
                    'adultName': adultName,
                    'rating': ratingValue,
                    'comment': commentController.text.trim(),
                    'createdAt': Timestamp.now(),
                    'hireRequestId': hireRequestId,
                  };

                  final updatedReviews = [...existingReviews, newReview];

                  tx.update(teenRef, {
                    'avgRating': double.parse(newAvg.toStringAsFixed(1)),
                    'reviewCount': oldCount + 1,
                    'reviews': updatedReviews,
                  });

                  tx.update(
                    firestore.collection('hire_requests').doc(hireRequestId),
                    {'reviewed': true},
                  );
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ⭐ Simple star renderer
class _StarRating extends StatelessWidget {
  final double rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return const Icon(Icons.star, size: 16, color: Colors.amber);
        } else if (rating > index && rating < index + 1) {
          return const Icon(Icons.star_half, size: 16, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 16, color: Colors.amber);
        }
      }),
    );
  }
}