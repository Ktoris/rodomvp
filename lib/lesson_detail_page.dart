import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<dynamic> blocks = widget.lessonData['blocks'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonData['title'] ?? 'Lesson')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index] as Map<String, dynamic>;
                return _buildBlock(block, index);
              },
            ),
          ),
          if (!_isCompleted)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _finishLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Complete Lesson', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.green.shade50,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Lesson Completed!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlock(Map<String, dynamic> block, int index) {
    final String type = block['type'] ?? '';

    switch (type) {
      case 'text_block':
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block['heading'] != null)
                Text(block['heading'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (block['heading'] != null) const SizedBox(height: 8),
              Text(block['body'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
          ),
        );
      case 'tip_block':
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRO TIP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(block['text'] ?? '', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'quiz_block':
        final options = List<String>.from(block['options'] ?? []);
        final correctIndex = block['correctIndex'] as int? ?? 0;
        final selected = _quizAnswers[index];
        final showFeedback = selected != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(block['question'] ?? 'Question', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ...options.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                Color color = Colors.white;
                if (showFeedback) {
                  if (idx == correctIndex) color = Colors.green.shade100;
                  else if (idx == selected) color = Colors.red.shade100;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: showFeedback ? null : () => setState(() => _quizAnswers[index] = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: showFeedback && idx == correctIndex ? Colors.green : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(opt)),
                          if (showFeedback && idx == correctIndex) const Icon(Icons.check, color: Colors.green, size: 18),
                          if (showFeedback && idx == selected && idx != correctIndex) const Icon(Icons.close, color: Colors.red, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (showFeedback) ...[
                const SizedBox(height: 12),
                Text(block['explanation'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ],
          ),
        );
      case 'checklist_block':
        final items = List<String>.from(block['items'] ?? []);
        final checked = _checklistItems[index] ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(block['title'] ?? 'Checklist', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isChecked = checked.contains(idx);

                return CheckboxListTile(
                  title: Text(item, style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : null)),
                  value: isChecked,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) checked.add(idx);
                      else checked.remove(idx);
                      _checklistItems[index] = checked;
                    });
                  },
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
    setState(() => _isCompleted = true);

    // Save progress to Firestore
    await FirebaseFirestore.instance 
        .collection('users')
        .doc(widget.teenId)
        .collection('lessonProgress')
        .doc(widget.lessonId)
        .set({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'xpEarned': widget.lessonData['xpReward'] ?? 50,
    });

    // Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nicely done! You earned ${widget.lessonData['xpReward'] ?? 50} XP'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
