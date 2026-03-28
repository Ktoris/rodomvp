import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'chat_page.dart';
import 'teen_edit_profile_page.dart';
import 'notifications_page.dart';
import 'support_page.dart';
import 'learn_page.dart';
import 'rules_page.dart';

class TeenDashboard extends StatefulWidget {
  final String teenId;

  const TeenDashboard({super.key, required this.teenId});

  @override
  State<TeenDashboard> createState() => _TeenDashboardState();
}

class _TeenDashboardState extends State<TeenDashboard> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('teenId', isEqualTo: widget.teenId);

    final acceptedRequests = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('teenId', isEqualTo: widget.teenId);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.darkBlue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage())),
          ),
          _buildNotificationBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildCurrentTab(pendingRequests, acceptedRequests),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeenEditProfilePage(teenId: widget.teenId))),
        backgroundColor: AppTheme.darkBlue,
        child: const Icon(Icons.edit, color: Colors.white),
      ) : null,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'My Profile';
      case 1: return 'My Jobs';
      case 2: return 'Learn & Earn';
      default: return 'Dashboard';
    }
  }

  Widget _buildCurrentTab(Query pendingQuery, Query acceptedQuery) {
    switch (_currentIndex) {
      case 0: return _buildProfileTab();
      case 1: return _buildJobsTab(pendingQuery, acceptedQuery);
      case 2: return LearnPage(teenId: widget.teenId, isEmbed: true);
      default: return const Center(child: Text('Tab not found'));
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.darkBlue,
        unselectedItemColor: Colors.black26,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.business_center_outlined), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.teenId)
          .collection('items')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.darkBlue),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage(uid: widget.teenId))),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.teenId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final teenData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        // Note: Redundant rules check removed. RoleRouter ensures teens agree to rules before this build is triggered.

        final skills = List<String>.from(teenData['skills'] ?? []);
        final double rating = (teenData['avgRating'] ?? 0).toDouble();
        final int reviewCount = ((teenData['reviewCount'] ?? 0) as num).toInt();
        final stats = teenData['stats'] ?? {};
        final portfolio = List<String>.from(teenData['portfolio'] ?? []);
        final badges = List<String>.from(teenData['badges'] ?? []);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.darkBlue.withOpacity(0.1),
                      backgroundImage: teenData['profilePhotoUrl'] != null ? NetworkImage(teenData['profilePhotoUrl']) : null,
                      child: teenData['profilePhotoUrl'] == null ? const Icon(Icons.person, size: 50, color: AppTheme.darkBlue) : null,
                    ),
                    const SizedBox(height: 16),
                    Text('${teenData['name'] ?? ''} ${teenData['surname'] ?? ''}', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
                    Text('${teenData['age'] ?? '17'} yrs • ${teenData['city'] ?? 'NYC'}', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text('$rating ★ ($reviewCount reviews)', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Stats
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MetricCard(icon: Icons.check_circle_outline, title: 'Jobs Done', value: '${stats['jobsDone'] ?? 0}'),
                    _MetricCard(icon: Icons.attach_money, title: 'Earned', value: '\$${((stats['totalEarned'] ?? 0) / 100).toStringAsFixed(2)}'),
                    _MetricCard(icon: Icons.menu_book, title: 'Lessons', value: '${stats['lessonsCompleted'] ?? 0}'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Skills
              if (skills.isNotEmpty) ...[
                Text('Skills', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => _buildModernChip(s)).toList()),
                const SizedBox(height: 32),
              ],

              // Bio
              if (teenData['bio']?.toString().isNotEmpty ?? false) ...[
                Text('Bio', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
                const SizedBox(height: 12),
                Text(teenData['bio'], style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black54, height: 1.5)),
                const SizedBox(height: 32),
              ],

              // Portfolio
              if (portfolio.isNotEmpty) ...[
                Text('Portfolio', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: portfolio.length,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 120,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(portfolio[index]), fit: BoxFit.cover)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Badges
              Text('Badges', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
              const SizedBox(height: 12),
              _buildBadgesSection(badges),
              const SizedBox(height: 32),

              // Reviews
              Text('Reviews', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
              const SizedBox(height: 12),
              _buildReviewsSection(teenData['reviews'] as List<dynamic>? ?? []),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobsTab(Query pendingQuery, Query acceptedQuery) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pending Requests', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
          const SizedBox(height: 16),
          _buildJobsList(pendingQuery.where('status', isEqualTo: 'pending')),
          const SizedBox(height: 32),
          Text('Active Jobs', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
          const SizedBox(height: 16),
          _buildJobsList(acceptedQuery.where('status', isEqualTo: 'accepted')),
        ],
      ),
    );
  }

  Widget _buildModernChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blue)),
    );
  }

  Widget _buildBadgesSection(List<String> badges) {
    if (badges.isEmpty) return Text('No badges earned yet. Keep it up!', style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w600));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.map((badgeId) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('badges').doc(badgeId).snapshots(),
          builder: (context, badgeSnap) {
            if (!badgeSnap.hasData) return const SizedBox();
            final badgeData = badgeSnap.data!.data() as Map<String, dynamic>?;
            if (badgeData == null) return _buildModernChip(badgeId);

            return Tooltip(
              message: badgeData['description'] ?? '',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withOpacity(0.2))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(badgeData['name'] ?? badgeId, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildReviewsSection(List<dynamic> reviews) {
    if (reviews.isEmpty) return Text('No reviews yet', style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontWeight: FontWeight.w600));
    
    final sortedReviews = List<Map<String, dynamic>>.from(reviews.whereType<Map<String, dynamic>>())
      ..sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

    return Column(
      children: sortedReviews.take(5).map((review) {
        final double rating = (review['rating'] ?? 0).toDouble();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.05))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(review['adultName'] ?? 'Anonymous', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
                  Row(children: [const Icon(Icons.star_rounded, color: Colors.orange, size: 16), const SizedBox(width: 4), Text('$rating', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700))]),
                ],
              ),
              const SizedBox(height: 8),
              Text('"${review['comment'] ?? ''}"', style: GoogleFonts.plusJakartaSans(color: Colors.black54, fontSize: 14, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Text(_formatDate(review['createdAt']), style: GoogleFonts.plusJakartaSans(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJobsList(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return Text('No jobs here yet', style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontWeight: FontWeight.w600));

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool isPending = data['status'] == 'pending';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isPending ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(data['jobTitle'] ?? 'Job', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue))),
                      Text('\$${data['budget'] ?? 0}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data['jobDescription'] ?? '', style: GoogleFonts.plusJakartaSans(color: Colors.black54, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Colors.black45),
                      const SizedBox(width: 8),
                      Text(data['adultName'] ?? 'Hiring Manager', style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.black45),
                      const SizedBox(width: 8),
                      Text(data['date'] != null ? _formatDate(data['date']) : 'Anytime', style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPending) ...[
                        TextButton(onPressed: () => _ignoreJob(doc.id), child: Text('Ignore', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.w800))),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await doc.reference.update({'status': 'accepted'});
                            await FirebaseFirestore.instance.collection('chats').doc(doc.id).set({
                              'adultId': data['adultId'],
                              'teenId': widget.teenId,
                              'jobTitle': data['jobTitle'],
                              'lastMessage': '',
                              'lastMessageAt': Timestamp.now(),
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Accept', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(chatId: doc.id, title: data['jobTitle'] ?? 'Chat'))),
                          child: Text('Chat', style: GoogleFonts.plusJakartaSans(color: AppTheme.darkBlue, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _finishJob(doc),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Finish Job', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _finishJob(DocumentSnapshot jobDoc) async {
    final data = jobDoc.data() as Map<String, dynamic>;
    final teenRef = FirebaseFirestore.instance.collection('users').doc(widget.teenId);
    final jobRef = jobDoc.reference;
    final double budget = (data['budget'] ?? 0.0).toDouble();
    final int budgetInCents = (budget * 100).toInt();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Update Job Status
        transaction.update(jobRef, {
          'status': 'completed',
          'completedAt': Timestamp.now(),
          'canReview': true,
          'reviewed': false,
        });

        // 2. Update Teen Stats in their user document
        transaction.update(teenRef, {
          'stats.jobsDone': FieldValue.increment(1),
          'stats.totalEarned': FieldValue.increment(budgetInCents),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job completed! Experience and earnings updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
                        .where('teenId', isEqualTo: widget.teenId)
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