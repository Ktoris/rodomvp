import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_detail_page.dart';

class LearnPage extends StatelessWidget {
  final String teenId;

  const LearnPage({super.key, required this.teenId});

  @override
  Widget build(BuildContext context) {
    final tracks = [
      {'id': 'prof', 'title': 'Professionalism', 'icon': Icons.business_center, 'color': Colors.blue},
      {'id': 'outdoor', 'title': 'Lawn & Outdoor', 'icon': Icons.grass, 'color': Colors.green},
      {'id': 'childcare', 'title': 'Childcare', 'icon': Icons.child_care, 'color': Colors.orange},
      {'id': 'tutoring', 'title': 'Tutoring & Teaching', 'icon': Icons.menu_book, 'color': Colors.teal},
      {'id': 'creative', 'title': 'Creative & Design', 'icon': Icons.brush, 'color': Colors.pink},
      {'id': 'tech', 'title': 'Tech & Digital', 'icon': Icons.computer, 'color': Colors.cyan},
      {'id': 'money', 'title': 'Money & Finance', 'icon': Icons.savings, 'color': Colors.purple},
      {'id': 'safety', 'title': 'Safety & Contracts', 'icon': Icons.security, 'color': Colors.red},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn & Grow'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(teenId).snapshots(),
        builder: (context, userSnapshot) {
          final stats = (userSnapshot.data?.data() as Map<String, dynamic>?)?['stats'] ?? {};
          final xp = stats['xp'] ?? 0;
          final level = (xp / 500).floor() + 1;
          final xpIntoLevel = xp % 500;
          final progress = xpIntoLevel / 500;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP & Level Header
                _buildLevelHeader(level, xpIntoLevel, progress),
                const SizedBox(height: 24),

                const Text(
                  'Skill Tracks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Tracks Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return _buildTrackCard(context, track);
                  },
                ),

                const SizedBox(height: 32),
                const Text(
                  'Recommended Lessons',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Lessons List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();

                    final lessons = snapshot.data!.docs;
                    if (lessons.isEmpty) {
                      return const Text('No lessons available yet. Check back soon!', style: TextStyle(color: Colors.grey));
                    }

                    return Column(
                      children: lessons.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildLessonTile(context, doc.id, data);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelHeader(int level, int xp, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Level', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Level $level', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('$xp / 500 XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(BuildContext context, Map<String, dynamic> track) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filter lessons by ${track['title']}')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: (track['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (track['color'] as Color).withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(track['icon'] as IconData, size: 40, color: track['color'] as Color),
            const SizedBox(height: 8),
            Text(track['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, String lessonId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.play_lesson, color: Colors.blue),
        ),
        title: Text(data['title'] ?? 'Lesson', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${data['duration'] ?? '5 min'} • ${data['xpReward'] ?? 50} XP'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonDetailPage(lessonId: lessonId, teenId: teenId, lessonData: data),
            ),
          );
        },
      ),
    );
  }
}
