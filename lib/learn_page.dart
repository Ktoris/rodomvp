import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lesson_detail_page.dart';
import 'lessons_data.dart';
import 'app_theme.dart';

class LearnPage extends StatelessWidget {
  final String teenId;
  final bool isEmbed;

  const LearnPage({super.key, required this.teenId, this.isEmbed = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(teenId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final stats = userData['stats'] ?? {};
        final int xp = (stats['xp'] ?? 0) as int;
        
        // Level calculation logic (Step of 500 XP per level)
        final int level = (xp / 500).floor() + 1;
        final int xpIntoLevel = xp % 500;
        final double progress = xpIntoLevel / 500;
        
        // Level titles (Mocked for premium feel)
        final String levelTitle = _getLevelTitle(level);

        Widget content = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏆 HEADER CARD (Concept Design Style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xff448AFF), // Premium Blue
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff448AFF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT LEVEL',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level $level — $levelTitle',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$xpIntoLevel / 500 XP to Level ${level + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 📚 AVAILABLE LESSONS SECTION
              Text(
                'Available Lessons',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 16),
              
              // 🚀 LESSONS LIST
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(teenId)
                    .collection('lessonProgress')
                    .snapshots(),
                builder: (context, progressSnapshot) {
                  final completedIds = progressSnapshot.hasData 
                    ? progressSnapshot.data!.docs.map((d) => d.id).toSet() 
                    : <String>{};

                  return Column(
                    children: allLessons.map((lesson) {
                      final bool isCompleted = completedIds.contains(lesson.id);
                      return _buildLessonCard(context, lesson, isCompleted);
                    }).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        );

        if (isEmbed) return content;

        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: const Text('Learn & Earn'),
            centerTitle: false,
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildLessonCard(BuildContext context, LessonData lesson, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonDetailPage(
                lessonId: lesson.id,
                teenId: teenId,
                lessonData: {
                  'id': lesson.id,
                  'title': lesson.title,
                  'description': lesson.description,
                  'xpReward': lesson.xpReward,
                  'blocks': lesson.blocks,
                },
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: lesson.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(lesson.icon, color: lesson.color, size: 24),
        ),
        title: Text(
          lesson.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkBlue,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${lesson.xpReward} XP',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black38,
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.darkBlue.withOpacity(0.3),
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level < 2) return 'Beginner';
    if (level < 3) return 'Rookie';
    if (level < 4) return 'Go-Getter';
    if (level < 5) return 'Professional';
    if (level < 6) return 'Expert';
    return 'Master Master';
  }
}
