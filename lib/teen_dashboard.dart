import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ✅ IMPORT ADDED
import 'package:intl/intl.dart';
import 'chat_page.dart';
import 'teen_edit_profile_page.dart';
import 'notifications_page.dart';
import 'support_page.dart';
import 'learn_page.dart';
import 'rules_page.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help & Support',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportPage()),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .doc(teenId)
                .collection('items')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsPage(uid: teenId),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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
                  .collection('users')
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

                final stats = teenData['stats'] ?? {};
                final int jobsDone = (stats['jobsDone'] ?? 0) as int;
                final int totalEarned = (stats['totalEarned'] ?? 0) as int;
                final int lessonsCompleted = (stats['lessonsCompleted'] ?? 0) as int;
                final int repeatHires = (stats['repeatHires'] ?? 0) as int;
                final badges = List<String>.from(teenData['badges'] ?? []);
                final portfolio = List<String>.from(teenData['portfolio'] ?? []);

                // 🔹 RULES AGREEMENT CHECK
                final agreedData = teenData['agreedToRules'] as Map<String, dynamic>?;
                final bool hasAgreed = agreedData != null && agreedData['agreed'] == true;

                if (!hasAgreed) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RulesPage(uid: teenId, isOnboarding: true),
                      ),
                    );
                  });
                  return const Scaffold(
                    body: Center(
                      child: Text('Please review community guidelines...'),
                    ),
                  );
                }

                return Column(
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

                    // 🔹 ACTION CARDS
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.school,
                            title: 'Learn',
                            subtitle: 'Earn XP & Skills',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LearnPage(teenId: teenId),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.edit,
                            title: 'Profile',
                            subtitle: 'Update Bio',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeenEditProfilePage(teenId: teenId),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
                    const Text(
                        'Badges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (badges.isEmpty)
                        const Text('No badges earned yet. Keep it up!', style: TextStyle(color: Colors.grey, fontSize: 14))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: badges.map((badgeId) {
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('badges').doc(badgeId).snapshots(),
                              builder: (context, badgeSnap) {
                                if (!badgeSnap.hasData) return const SizedBox();
                                final badgeData = badgeSnap.data!.data() as Map<String, dynamic>?;
                                if (badgeData == null) return Chip(label: Text(badgeId));

                                final name = badgeData['name'] ?? badgeId;
                                final description = badgeData['description'] ?? '';
                                final iconName = badgeData['icon'] ?? 'stars';

                                // Map string icon names to Material Icons
                                final iconMap = {
                                  'stars': Icons.stars,
                                  'thumb_up': Icons.thumb_up,
                                  'workspace_premium': Icons.workspace_premium,
                                  'verified': Icons.verified,
                                  'school': Icons.school,
                                  'auto_stories': Icons.auto_stories,
                                };

                                return Tooltip(
                                  message: description,
                                  child: Chip(
                                    avatar: Icon(iconMap[iconName] ?? Icons.stars, color: Colors.amber, size: 18),
                                    label: Text(name),
                                    backgroundColor: Colors.amber.shade50,
                                    side: BorderSide(color: Colors.amber.shade200),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
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
                          children: sortedReviews.take(3).map((reviewData) { // Display top 3 reviews
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
                                Text('"$reviewComment"', style: const TextStyle(fontStyle: FontStyle.italic)),
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
                    const SizedBox(height: 24),

                    // 🔹 ACTION CARDS
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.school,
                            title: 'Learn',
                            subtitle: 'Earn XP & Skills',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LearnPage(teenId: teenId),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.edit,
                            title: 'Profile',
                            subtitle: 'Update Bio',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeenEditProfilePage(teenId: teenId),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

            // 🔹 PENDING REQUESTS
            const Text(
              'Pending Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream: pendingRequests
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
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
                                  : 'Location: ${data['locationText'] ?? "Not specified"}',
                            ),
                            if (data['locationData'] != null) ...[
                              Text(
                                'Address: ${data['locationData']['address']}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              TextButton.icon(
                                onPressed: () => _openMapDialog(context, data['locationData']),
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text('View on Map', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                              ),
                            ],

                            Text(
                              data['date'] != null
                                  ? 'Date: ${_formatDate(data['date'])}'
                                  : 'Date: Anytime',
                            ),

                            Text(
                              'Duration: ${data['duration'] ?? "Not specified"}',
                            ),

                            Text(
                              'Pay: \$${data['budget'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
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
                                  onPressed: () => _ignoreJob(doc.id),
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
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _showIgnoredOffers(context),
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('View Ignored Offers'),
              ),
            ),
            const SizedBox(height: 24),

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
                              data['locationType'] == 'remote'
                                  ? 'Remote'
                                  : 'Location: ${data['locationText'] ?? "Not specified"}',
                            ),
                            if (data['locationData'] != null) ...[
                              Text(
                                'Address: ${data['locationData']['address']}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              TextButton.icon(
                                onPressed: () => _openMapDialog(context, data['locationData']),
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text('View on Map', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                              ),
                            ],
                            const SizedBox(height: 4),
                            ElevatedButton.icon(
                              onPressed: () {}, // Simulation: would open external maps
                              icon: const Icon(Icons.directions, size: 18),
                              label: const Text('Get Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),

                            Text(
                              data['date'] != null
                                  ? 'Date: ${_formatDate(data['date'])}'
                                  : 'Date: Anytime',
                            ),

                            Text(
                              'Duration: ${data['duration'] ?? "Not specified"}',
                            ),

                            Text(
                              'Pay: \$${data['budget'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
        );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ignoreJob(String docId) async {
    await FirebaseFirestore.instance
        .collection('hire_requests')
        .doc(docId)
        .update({
      'status': 'ignored',
      'ignoredAt': FieldValue.serverTimestamp(),
    });
  }

  void _showIgnoredOffers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Ignored Offers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hire_requests')
                        .where('teenId', isEqualTo: teenId)
                        .where('status', isEqualTo: 'ignored')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No ignored offers', style: TextStyle(color: Colors.grey)),
                        );
                      }

                      return ListView(
                        controller: scrollController,
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final ignoredAt = data['ignoredAt'] as Timestamp?;
                          final bool canUnignore = ignoredAt != null &&
                              DateTime.now().difference(ignoredAt.toDate()).inHours < 24;

                          return ListTile(
                            title: Text(data['jobTitle'] ?? 'Job'),
                            subtitle: Text('From: ${data['adultName']}\nIgnored: ${ignoredAt != null ? _formatDate(ignoredAt) : "Unknown"}'),
                            isThreeLine: true,
                            trailing: canUnignore
                                ? TextButton(
                                    onPressed: () {
                                      doc.reference.update({'status': 'pending'});
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Restore'),
                                  )
                                : const Text('Expired', style: TextStyle(color: Colors.red, fontSize: 12)),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openMapDialog(BuildContext context, Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Job Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.blue.shade100,
              child: const Icon(Icons.map, size: 80, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Text(
              location['address'] ?? 'Specific Address',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              'Lat: ${location['lat']?.toStringAsFixed(4)}, Lng: ${location['lng']?.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

// 🔹 Action Card for Teen Dashboard
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
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