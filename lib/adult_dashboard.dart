import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'app_theme.dart';
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
  late Future<String> _adultNameFuture; // 🔹 Cached future to prevent loading on every rebuild

  
  @override
  void initState() {
    super.initState();
    _adultNameFuture = getAdultName(); // 🔹 Initialize once
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

  Future<String> getAdultName() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(adultId).get();
    return doc.data()?['name'] ?? 'User';
  }

  Future<void> hireTeen(BuildContext context, String teenId, String adultName) async {
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
        const SnackBar(content: Text('You already have an active request with this teen.')),
      );
      return;
    }

    if (!mounted) return;
    final jobData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateJobRequestPage()),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hire request sent')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _adultNameFuture,
      builder: (context, snapshot) {
        // Correcting loading state: 
        // Showing a proper full-screen loader until the identity is confirmed.
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final adultName = snapshot.data!;

        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: Text('Adult Dashboard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentIndex == 0 ? 'Find Teens' : 'Active Jobs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    if (_currentIndex == 0)
                      Text(
                        'Browse available teen profiles',
                        style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),

              // 🔹 VIEW CONTENT
              Expanded(
                child: _currentIndex == 0 
                    ? _buildFindTeens(adultName) 
                    : _buildManagement(adultName),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildFindTeens(String adultName) {
    return Column(
      children: [
        // 🔹 SEARCH BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Search by skill (e.g. Tutoring)',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.darkBlue),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'teen') // ← Restoring mandatory role filter for rule compliance
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Database Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData) return const Center(child: Text('No data from database.'));
              
              final allDocs = snapshot.data!.docs;

              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                
                // Firestore handles 'teen' role filter now; we only handle client-side search here.
                if (_searchQuery.isEmpty) return true;

                final String name = (data['name'] ?? '').toString().toLowerCase();
                final String surname = (data['surname'] ?? '').toString().toLowerCase();
                final List skills = data['skills'] as List? ?? [];
                
                final String fullName = '$name $surname'.toLowerCase();
                return fullName.contains(_searchQuery) || skills.any((s) => s.toString().toLowerCase().contains(_searchQuery));
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No teens found in database' : 'No matches for "$_searchQuery"',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                  return _buildModernTeenCard(filteredDocs[index].id, data, adultName);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManagement(String adultName) {
    // Logic: Active jobs (pending/accepted) AND Completed jobs that need review.
    final jobsQuery = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('adultId', isEqualTo: adultId)
        .where('status', whereIn: ['accepted', 'pending', 'completed']);

    return StreamBuilder<QuerySnapshot>(
      stream: jobsQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_history_rounded, size: 64, color: AppTheme.darkBlue.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text(
                  'No active jobs right now',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 0),
                  child: const Text('Start Hiring'),
                ),
              ],
            ),
          );
        }

        // Identify teens who have ALREADY been reviewed by this adult across any job
        final reviewedTeens = docs
            .where((doc) => (doc.data() as Map<String, dynamic>)['reviewed'] == true)
            .map((doc) => doc['teenId'] as String)
            .toSet();

        final activeJobs = docs.where((doc) => doc['status'] != 'completed').toList();
        final pendingReviews = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isCompleted = data['status'] == 'completed';
          final notReviewedInThisJob = data['reviewed'] != true;
          final neverReviewedBefore = !reviewedTeens.contains(data['teenId']);
          return isCompleted && notReviewedInThisJob && neverReviewedBefore;
        }).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            if (activeJobs.isNotEmpty) ...[
              Text('In Progress', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: activeJobs.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.black.withOpacity(0.05)),
                  itemBuilder: (context, index) {
                    final data = activeJobs[index].data() as Map<String, dynamic>;
                    return _buildModernJobCard(activeJobs[index].id, data, adultName);
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (pendingReviews.isNotEmpty) ...[
              Text('Pending Reviews', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
              const SizedBox(height: 12),
              ...pendingReviews.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['jobTitle'] ?? 'Job', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
                            if (data['teenName'] != null)
                              Text('Done by ${data['teenName']}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w600))
                            else
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(data['teenId']).get(),
                                builder: (context, snapshot) {
                                  String name = 'a Teen';
                                  if (snapshot.hasData && snapshot.data!.exists) {
                                    final d = snapshot.data!.data() as Map<String, dynamic>;
                                    name = '${d['name'] ?? ''} ${d['surname'] ?? ''}'.trim();
                                  }
                                  return Text('Done by $name', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w600));
                                },
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showReviewDialog(doc.id, data, adultName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Review', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildModernTeenCard(String teenId, Map<String, dynamic> data, String adultName) {
    final double rating = (data['avgRating'] ?? 0).toDouble();
    final skills = List<String>.from(data['skills'] ?? []);
    final String name = data['name'] ?? 'User';
    final String surname = data['surname'] ?? '';
    final String age = data['age']?.toString() ?? '17';
    final String initials = (name.isNotEmpty ? name[0] : '') + (surname.isNotEmpty ? surname[0] : '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800, 
                      color: AppTheme.darkBlue,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$name $surname, $age',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.black26, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data['city'] ?? 'NYC',
                  style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_outlined, color: Colors.black26, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Weekends',
                  style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: skills.take(2).map((s) => _buildModernChip(s)).toList(),
          ),
          const SizedBox(height: 12), // Replaced Spacer() with a fixed SizedBox to stabilize GridView rendering
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeenDetailPage(teenId: teenId, adultId: adultId, adultName: adultName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('View Profile', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernJobCard(String jobId, Map<String, dynamic> data, String adultName) {
    final status = data['status'] ?? 'pending';
    final String title = data['jobTitle'] ?? 'Task Engagement';
    final String location = data['locationText'] ?? 'Remote';
    final double budget = (data['budget'] ?? 0).toDouble();

    return InkWell(
      onTap: () => _showJobDetails(jobId, data),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.attach_money_rounded, color: Colors.orange, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.black26, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black38, 
                          fontSize: 13, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'accepted')
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(chatId: jobId, title: title),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 22, color: Colors.blue),
                              const SizedBox(height: 2),
                              Text(
                                'Chat',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Text(
                      '\$$budget/hr',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ],
                ),
                if (status == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'PENDING',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(color: AppTheme.teal, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildModernStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'accepted') color = AppTheme.teal;
    if (status == 'pending') color = AppTheme.accentOrange;
    if (status == 'completed') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _currentIndex == 0 ? Colors.blue : Colors.orange,
        unselectedItemColor: Colors.black26,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.group_outlined),
            ), 
            label: 'Find Teens',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.business_center_outlined),
            ), 
            label: 'Active Jobs',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(adultId)
          .collection('items')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_none_rounded, color: AppTheme.darkBlue, size: 28),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8)),
                  ),
                ),
            ],
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage(uid: adultId))),
        );
      },
    );
  }

  void _showReviewDialog(String jobId, Map<String, dynamic> data, String adultName) {
    double selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 32, right: 32, top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Performance', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
              const SizedBox(height: 8),
              Text('How was your experience with ${data['teenName'] ?? 'the teen'}?', style: GoogleFonts.plusJakartaSans(color: Colors.black45, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < selectedRating ? Colors.orange : Colors.grey.shade300,
                      size: 40,
                    ),
                    onPressed: () => setModalState(() => selectedRating = index + 1.0),
                  )),
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share more details (optional)...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _submitReview(jobId, data['teenId'], selectedRating, commentController.text, adultName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Submit Review', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview(String jobId, String teenId, double rating, String comment, String adultName) async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      await firestore.runTransaction((transaction) async {
        final teenRef = firestore.collection('users').doc(teenId);
        final teenSnap = await transaction.get(teenRef);
        final teenData = teenSnap.data() as Map<String, dynamic>? ?? {};

        // Recalculate Rating
        final int oldCount = ((teenData['reviewCount'] ?? 0) as num).toInt();
        final double oldAvg = (teenData['avgRating'] ?? 0).toDouble();
        final double newAvg = ((oldAvg * oldCount) + rating) / (oldCount + 1);

        // Update Teen
        transaction.update(teenRef, {
          'avgRating': newAvg,
          'reviewCount': FieldValue.increment(1),
          'reviews': FieldValue.arrayUnion([{
            'rating': rating,
            'comment': comment,
            'adultName': adultName,
            'createdAt': Timestamp.now(),
          }]),
        });

        // Update Job Request
        transaction.update(firestore.collection('hire_requests').doc(jobId), {
          'reviewed': true,
          'rating': rating,
          'comment': comment,
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted! Thank you.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showJobDetails(String jobId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Details', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkBlue)),
            const SizedBox(height: 24),
            _buildDetailRow('Description', data['jobDescription'] ?? 'N/A'),
            _buildDetailRow('Budget', '\$${data['budget'] ?? 0}'),
            _buildDetailRow('Date', data['date'] != null ? _formatDate(data['date'] as Timestamp?) : 'Anytime'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.black38, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
