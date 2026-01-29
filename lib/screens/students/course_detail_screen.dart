import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/lesson_service.dart';
import '../../services/progress_service.dart';
import 'lesson_player_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String title;
  final String description;
  final String category;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.description,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final lessonService = LessonService();
    final progressService = ProgressService();
    final user = FirebaseAuth.instance.currentUser;

    final totalStream = lessonService.lessonCountStream(courseId);
    final doneStream = user == null ? Stream<int>.value(0) : progressService.doneCountStream(user.uid, courseId);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 18),

            // ✅ Progression
            StreamBuilder<int>(
              stream: totalStream,
              builder: (context, totalSnap) {
                final total = totalSnap.data ?? 0;

                return StreamBuilder<int>(
                  stream: doneStream,
                  builder: (context, doneSnap) {
                    final done = doneSnap.data ?? 0;
                    final progress = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Progression', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(12),
                                backgroundColor: Colors.grey.shade200,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${(progress * 100).toInt()}%'),
                          ],
                        ),
                        const SizedBox(height: 22),
                      ],
                    );
                  },
                );
              },
            ),

            const Text('Leçons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder(
                stream: lessonService.getLessons(courseId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final lessons = snapshot.data!.docs;

                  if (lessons.isEmpty) {
                    return const Center(child: Text('Aucune leçon'));
                  }

                  return ListView.builder(
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final bool isPdf = (lesson['type'] == 'pdf');

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.play_circle_fill,
                            color: isPdf ? Colors.red : Colors.blue,
                          ),
                          title: Text((lesson['title'] ?? 'Sans titre').toString()),
                          subtitle: Text((lesson['duration'] ?? '').toString()),
                          onTap: () async {
                            // ✅ progression auto
                            if (user != null) {
                              await progressService.markLessonDone(
                                userId: user.uid,
                                courseId: courseId,
                                lessonId: lesson.id,
                              );
                            }

                            // ✅ ouvre lecteur intégré
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LessonPlayerScreen(
                                    courseId: courseId,
                                    lesson: lesson,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
