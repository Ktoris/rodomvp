import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'create_job_request_page.dart';
import 'chat_page.dart';
import 'teen_detail_page.dart';
import 'notifications_page.dart';
import 'support_page.dart';

class AdultDashboard extends StatefulWidget {
  final String adultId;

  const AdultDashboard({super.key, required this.adultId});

  @override
  State<AdultDashboard> createState() => _AdultDashboardState();
}

class _AdultDashboardState extends State<AdultDashboard> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedSkills = [];
  double _minRating = 0.0;
  int _minAge = 13;
  int _maxAge = 17;
  bool _remoteOnly = false;
  bool _sortByDistance = false;
  
  // Simulated "My Location" (NYC)
  final double _myLat = 40.7128;
  final double _myLng = -74.0060;

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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Anytime";
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String get adultId => widget.adultId;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // 🔹 Get adult name once
  Future<String> getAdultName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already have an active request with this teen.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final jobData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateJobRequestPage(),
      ),
    );

    if (jobData == null) return;
    if (!mounted) return;

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
      'date': jobData['date'] != null ? Timestamp.fromDate(jobData['date']) : null,
      'duration': jobData['duration'],
      'budget': jobData['budget'],
      'numTeens': jobData['numTeens'],
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hire request sent')),
    );
  }

  @override
  Widget build(BuildContext context) {

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
          appBar: AppBar(
            title: const Text('Adult Dashboard'),
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
                    .doc(adultId)
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
                              builder: (_) => NotificationsPage(uid: adultId),
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
          body: _buildBody(adultName),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find Teens'),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'My Teens'),
              BottomNavigationBarItem(icon: Icon(Icons.work), label: 'My Jobs'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(String adultName) {
    if (_currentIndex == 0) return _buildFindTeens(adultName);
    if (_currentIndex == 1) return _buildMyTeens(adultName);
    return _buildMyJobs(adultName);
  }

  Widget _buildFindTeens(String adultName) {
    final teensCollection = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teen');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Find Teens',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
              const SizedBox(height: 8),

              // 🔹 SEARCH BAR & FILTERS
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by skill...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: (_selectedSkills.isNotEmpty || _minRating > 0 || _minAge > 13 || _maxAge < 17 || _remoteOnly)
                          ? Colors.blue
                          : null,
                    ),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ],
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
                    final data = teen.data() as Map<String, dynamic>;
                    
                    // Basic search (keyword in skills or name)
                    final name = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.toLowerCase();
                    final skills = List<String>.from(data['skills'] ?? []).map((s) => s.toLowerCase()).toList();
                    
                    bool matchesSearch = _searchQuery.isEmpty || 
                                        name.contains(_searchQuery) || 
                                        skills.any((s) => s.contains(_searchQuery));
                    if (!matchesSearch) return false;

                    // Skill filters (exact match or list inclusion)
                    if (_selectedSkills.isNotEmpty) {
                      if (!skills.any((s) => _selectedSkills.contains(s))) return false;
                    }

                    // Rating filter
                    final double rating = (data['avgRating'] ?? data['rating'] ?? 0).toDouble();
                    if (rating < _minRating) return false;

                    // Age filter
                    final int age = (data['age'] ?? 0) as int;
                    if (age < _minAge || age > _maxAge) return false;

                    // Remote filter
                    final bool isRemote = data['workRemote'] ?? false;
                    if (_remoteOnly && !isRemote) return false;

                    // Account status filter (Only active)
                    if (data['accountStatus'] != 'active') return false;

                    return true;
                  }).toList();

                  // 🔹 SORTING LOGIC
                  filteredTeens.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;

                    if (_sortByDistance) {
                      final locA = dataA['location'] as Map<String, dynamic>?;
                      final locB = dataB['location'] as Map<String, dynamic>?;

                      final distA = (locA != null) 
                          ? _calculateDistance(_myLat, _myLng, locA['lat'], locA['lng'])
                          : 999999.0;
                      final distB = (locB != null)
                          ? _calculateDistance(_myLat, _myLng, locB['lat'], locB['lng'])
                          : 999999.0;
                      
                      return distA.compareTo(distB); // Ascending (closest first)
                    } else {
                      // Default: Sort by Discovery Score (Ranking)
                      final scoreA = (dataA['discoveryScore'] ?? 0).toDouble();
                      final scoreB = (dataB['discoveryScore'] ?? 0).toDouble();
                      return scoreB.compareTo(scoreA); // Descending
                    }
                  });

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
            ],
          );
  }

  Widget _buildMyTeens(String adultName) {
    // For now, this could fetch teens the adult has previously hired.
    final previouslyHiredTeensQuery = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('adultId', isEqualTo: adultId)
        .where('status', isEqualTo: 'completed');
        
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'My Teens (Previously Hired)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: previouslyHiredTeensQuery.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Text('You haven\'t hired any teens yet.', style: TextStyle(color: Colors.grey));
            }
            
            // Extract unique teen IDs
            final teenIds = docs.map((doc) => doc.data() as Map<String, dynamic>).map((data) => data['teenId'] as String).toSet().toList();

            return Column(
              children: teenIds.map((teenId) {
                return Card(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(teenId).get(),
                    builder: (context, teenSnapshot) {
                      if (!teenSnapshot.hasData || !teenSnapshot.data!.exists) {
                        return const ListTile(title: Text('Loading...'));
                      }
                      
                      final data = teenSnapshot.data!.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['profilePhotoUrl'] != null 
                              ? NetworkImage(data['profilePhotoUrl']) 
                              : null,
                          child: data['profilePhotoUrl'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text('${data['name']} ${data['surname']}'),
                        subtitle: Text(data['city'] ?? 'Unknown Location'),
                        trailing: ElevatedButton(
                          onPressed: () {
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
                          child: const Text('View Profile'),
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
    );
  }

  Widget _buildMyJobs(String adultName) {
    final activeJobsQuery = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('adultId', isEqualTo: adultId)
        .where('status', isEqualTo: 'accepted');

    final completedJobsQuery = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('adultId', isEqualTo: adultId)
        .where('status', isEqualTo: 'completed');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 🔹 ACTIVE JOBS
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
                                .collection('users')
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

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
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
                                  ),
                                  const SizedBox(height: 4),
                                  Text(data['date'] != null ? 'Date: ${_formatDate(data['date'] as Timestamp?)}' : 'Date: Anytime'),
                                  Text('Pay: \$${data['budget'] ?? 0}'),
                                ],
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
                              .collection('users')
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
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
                                  const SizedBox(height: 4),
                                  Text(data['date'] != null ? 'Date: ${_formatDate(data['date'] as Timestamp?)}' : 'Date: Anytime'),
                                  Text('Pay: \$${data['budget'] ?? 0}'),
                                ]
                              ),
                              trailing: (data['reviewed'] == true || hasReviewedTeen) ? 
                                  ElevatedButton(
                                    onPressed: null, // Disabled
                                    style: ElevatedButton.styleFrom(
                                      disabledBackgroundColor:
                                          Colors.grey.shade300,
                                      disabledForegroundColor:
                                          Colors.grey.shade600,
                                    ),
                                    child: const Text('Already reviewed'),
                                  ) : 
                                  ElevatedButton(
                                    onPressed: () => _handleLeaveReviewTap(
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
          );
  }

  // 🔒 Ensure only one review per adult–teen pair
  Future<void> _handleLeaveReviewTap(
    BuildContext context,
    String hireRequestId,
    String teenId,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final teenDoc = await firestore.collection('users').doc(teenId).get();
    final teenData = teenDoc.data() ?? {};
    final reviews = teenData['reviews'] as List<dynamic>? ?? [];

    final hasReviewed = reviews.any((review) =>
        review is Map<String, dynamic> && review['adultId'] == widget.adultId);

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
    final firestore = FirebaseFirestore.instance;
    // For demo purposes, we can get name from AdultDashboard fields or Firestore
    final adultDoc = await firestore.collection('users').doc(widget.adultId).get();
    final adultName = adultDoc.data()?['name'] ?? 'Adult';

    double ratingValue = 5;
    bool wouldHireAgain = true; // default 
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
                onChanged: (v) => setState(() {
                  ratingValue = v!;
                  if (ratingValue <= 3) {
                    wouldHireAgain = false;
                  } else {
                    wouldHireAgain = true;
                  }
                }),
              ),
              TextField(
                controller: commentController,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Would you hire again?'),
                value: wouldHireAgain,
                onChanged: (bool value) => setState(() => wouldHireAgain = value),
              )
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
                  final teenRef = firestore.collection('users').doc(teenId);
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
                    'adultId': widget.adultId,
                    'adultName': adultName,
                    'rating': ratingValue,
                    'comment': commentController.text.trim(),
                    'wouldHireAgain': wouldHireAgain,
                    'createdAt': Timestamp.now(),
                    'hireRequestId': hireRequestId,
                  };

                  final updatedReviews = [...existingReviews, newReview];

                  final stats = Map<String, dynamic>.from((teenData['stats'] as Map<String, dynamic>?) ?? {});
                  if (wouldHireAgain) {
                    stats['repeatHires'] = (stats['repeatHires'] as num? ?? 0).toInt() + 1;
                  }

                  tx.update(teenRef, {
                    'avgRating': double.parse(newAvg.toStringAsFixed(1)),
                    'reviewCount': oldCount + 1,
                    'reviews': updatedReviews,
                    'stats': stats,
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
  final List<String> _allSkills = [
    'Lawn Care',
    'Car Wash',
    'Babysitting',
    'Tutoring',
    'Design',
    'Errands',
    'Events',
  ];

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedSkills = [];
                            _minRating = 0.0;
                            _minAge = 13;
                            _maxAge = 17;
                            _remoteOnly = false;
                          });
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allSkills.map((skill) {
                      final isSelected = _selectedSkills.contains(skill.toLowerCase());
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              _selectedSkills.add(skill.toLowerCase());
                            } else {
                              _selectedSkills.remove(skill.toLowerCase());
                            }
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: '${_minRating.toStringAsFixed(1)}+ Stars',
                    onChanged: (val) {
                      setModalState(() => _minRating = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Age Range', style: TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                    min: 13,
                    max: 17,
                    divisions: 4,
                    labels: RangeLabels('$_minAge', '$_maxAge'),
                    onChanged: (val) {
                      setModalState(() {
                        _minAge = val.start.round();
                        _maxAge = val.end.round();
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Remote Work Only'),
                    value: _remoteOnly,
                    onChanged: (val) {
                      setModalState(() => _remoteOnly = val);
                      if (mounted) setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Sort by Distance'),
                    subtitle: const Text('Closest teenagers first'),
                    value: _sortByDistance,
                    onChanged: (val) {
                      setModalState(() => _sortByDistance = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
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