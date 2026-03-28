import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class LessonDetailPage extends StatefulWidget {
  final String lessonId;
  final String teenId;
  final Map<String, dynamic> lessonData;

  const LessonDetailPage({
    super.key,
    required this.lessonId,
    required this.teenId,
    required this.lessonData,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  final Map<int, int?> _quizAnswers = {};
  final Map<int, Set<int>> _checklistItems = {};
  bool _isCompleted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkInitialCompletion();
  }

  Future<void> _checkInitialCompletion() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.teenId)
        .collection('lessonProgress')
        .doc(widget.lessonId)
        .get();
    
    if (doc.exists && doc.data()?['completed'] == true) {
      setState(() => _isCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> blocks = widget.lessonData['blocks'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.lessonData['title'] ?? 'Lesson', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkBlue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index] as Map<String, dynamic>;
                return _buildBlock(block, index);
              },
            ),
          ),
          
          // 🏆 COMPLETION FOOTER
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _isCompleted
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Text(
                            'Lesson Completed!',
                            style: GoogleFonts.plusJakartaSans(color: Colors.green, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _finishLesson,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff448AFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Complete Lesson (+${widget.lessonData['xpReward'] ?? 100} XP)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  final Set<int> _revealedAnswers = {};

  Widget _buildBlock(Map<String, dynamic> block, int index) {
    final String type = block['type'] ?? '';

    switch (type) {
      case 'text_block':
        final String body = block['body'] ?? '';
        final List<String> lines = body.split('\n');
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block['heading'] != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (block['icon'] != null) ...[
                      Icon(
                        block['icon'] as IconData,
                        size: 24,
                        color: AppTheme.darkBlue.withOpacity(0.8),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        block['heading'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              if (block['heading'] != null) const SizedBox(height: 14),
              ...lines.map((line) {
                final trimmed = line.trim();
                final bool isBullet = trimmed.startsWith('•') || trimmed.startsWith('-');
                
                if (isBullet) {
                  final text = trimmed.substring(1).trim();
                  // Cycle colors for bullets
                  final List<Color> bulletColors = [
                    const Color(0xff448AFF), // Blue
                    const Color(0xffFFAB40), // Orange
                    const Color(0xff69F0AE), // Green
                    const Color(0xffE040FB), // Purple
                  ];
                  final bulletColor = bulletColors[index % bulletColors.length];

                  return Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: bulletColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: bulletColor.withOpacity(0.3), blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: Colors.black.withOpacity(0.7),
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    line,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: Colors.black.withOpacity(0.65),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      
      case 'tip_block':
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xffF5F7FF), // Light Blue-ish
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffE0E7FF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xff448AFF), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRO TIP',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xff448AFF),
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      block['text'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.darkBlue.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'checklist_block':
        final items = List<String>.from(block['items'] ?? []);
        final checked = _checklistItems[index] ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xffF5F7FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffE0E7FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block['title'] ?? 'Checklist',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 16),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isChecked = checked.contains(idx);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isChecked) checked.remove(idx);
                        else checked.add(idx);
                        _checklistItems[index] = checked;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: isChecked ? const Color(0xff448AFF) : Colors.black26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: isChecked ? Colors.black38 : Colors.black87,
                              fontWeight: FontWeight.w600,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      
      case 'quiz_block':
        final questions = List<String>.from(block['questions'] ?? []);
        final answers = List<String>.from(block['answers'] ?? []);

        return Container(
          margin: const EdgeInsets.only(bottom: 32, top: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffE0E7FF), width: 2), // Light Blue Outline
            boxShadow: [
              BoxShadow(color: const Color(0xff448AFF).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_center_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'KNOWLEDGE CHECK',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.darkBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...questions.asMap().entries.map((entry) {
                final qIdx = entry.key;
                final question = entry.value;
                final answer = qIdx < answers.length ? answers[qIdx] : "Check the lesson content for the answer!";
                final isRevealed = _revealedAnswers.contains(qIdx);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)), // Inner Orange Outline
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${qIdx + 1}. $question',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.darkBlue.withOpacity(0.8),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isRevealed) _revealedAnswers.remove(qIdx);
                            else _revealedAnswers.add(qIdx);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.orange.withOpacity(0.1))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isRevealed ? 'HIDE ANSWER' : 'REVEAL ANSWER',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Icon(
                                isRevealed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isRevealed)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.02),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                          ),
                          child: Text(
                            answer,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      
      default:
        return const SizedBox();
    }
  }

  Future<void> _finishLesson() async {
    setState(() => _isLoading = true);
    final int xpReward = widget.lessonData['xpReward'] ?? 100;

    try {
      final teenRef = FirebaseFirestore.instance.collection('users').doc(widget.teenId);
      final progressRef = teenRef.collection('lessonProgress').doc(widget.lessonId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Mark lesson as completed
        transaction.set(progressRef, {
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
          'xpEarned': xpReward,
        });

        // 2. Update teen stats
        transaction.update(teenRef, {
          'stats.lessonsCompleted': FieldValue.increment(1),
          'stats.xp': FieldValue.increment(xpReward),
        });
      });

      setState(() {
        _isCompleted = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Awesome! You earned $xpReward XP! 🏆'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving progress: $e')),
        );
      }
    }
  }
}
