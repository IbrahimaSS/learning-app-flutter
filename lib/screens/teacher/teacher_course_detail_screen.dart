import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/lesson_service.dart';

class TeacherCourseDetailScreen extends StatelessWidget {
  final String courseId;
  final dynamic courseData;

  const TeacherCourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseData,
  });

  @override
  Widget build(BuildContext context) {
    final lessonService = LessonService();

    return Scaffold(
      appBar: AppBar(
        title: Text(courseData['title'] ?? 'Cours'),
      ),

      // ➕ AJOUTER UNE LEÇON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddLessonDialog(context, lessonService);
        },
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📘 Infos cours
            Text(
              courseData['category'] ?? '—',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              courseData['description'] ?? '—',
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),

            const Text(
              'Leçons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 📚 LISTE DES LEÇONS
            Expanded(
              child: StreamBuilder(
                stream: lessonService.getLessons(courseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Aucune leçon pour le moment'),
                    );
                  }

                  final lessons = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final bool isPdf = lesson['type'] == 'pdf';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            isPdf
                                ? Icons.picture_as_pdf
                                : Icons.play_circle_fill,
                            color: isPdf ? Colors.red : Colors.blue,
                            size: 32,
                          ),
                          title: Text(lesson['title'] ?? 'Sans titre'),
                          subtitle: Text(lesson['duration'] ?? '—'),

                          // 🗑 SUPPRIMER
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await lessonService.deleteLesson(
                                courseId,
                                lesson.id,
                              );
                            },
                          ),

                          // 👁 OUVRIR LIEN (enseignant)
                          onTap: () async {
                            final uri = Uri.parse(lesson['url']);
                            await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                              webOnlyWindowName: '_blank',
                            );
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

  // =====================================================
  // 🧩 DIALOG AJOUT LEÇON — LIEN EN LIGNE UNIQUEMENT
  // =====================================================
  void _showAddLessonDialog(
    BuildContext context,
    LessonService lessonService,
  ) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final durationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter une leçon'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lien (PDF / YouTube / MP4)',
                ),
              ),
              TextField(
                controller: durationCtrl,
                decoration:
                    const InputDecoration(labelText: 'Durée (ex: 10 min)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlCtrl.text.trim();

              if (url.isEmpty) return;

              final type = _detectType(url);

              await lessonService.addLesson(courseId, {
                'title': titleCtrl.text.trim(),
                'url': url,
                'type': type, // 🔥 clé utilisée côté apprenant
                'duration': durationCtrl.text.trim().isEmpty
                    ? '—'
                    : durationCtrl.text.trim(),
              });

              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 🔎 DÉTECTION AUTOMATIQUE DU TYPE
  // =====================================================
  String _detectType(String url) {
    final lower = url.toLowerCase();

    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return 'video';
    }
    if (lower.endsWith('.mp4')) {
      return 'video';
    }
    if (lower.endsWith('.pdf')) {
      return 'pdf';
    }
    return 'video';
  }
}