import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning/screens/teacher/preview_quiz_screen.dart';
import 'package:learning/screens/teacher/teacher_quiz_questions_screen.dart';
import 'create_quiz_screen.dart';

class TeacherQuizListScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const TeacherQuizListScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    final quizzesRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('quizzes');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz – $courseTitle',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ➕ CRÉER QUIZ
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateQuizScreen(courseId: courseId),
            ),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: quizzesRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur Firestore : ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = snapshot.data!.docs;

          if (quizzes.isEmpty) {
            return const Center(
              child: Text('Aucun quiz pour ce cours'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quizDoc = quizzes[index];
              final data = quizDoc.data() as Map<String, dynamic>;

              final title = (data['title'] ?? 'Quiz').toString();
              final timer = data['timerSeconds'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.quiz),

                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: (timer != null && timer > 0)
                      ? Text('Timer : $timer sec')
                      : const Text('Sans limite de temps'),

                  // 🔽 MENU ACTIONS ENSEIGNANT
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _editQuizTitleDialog(
                          context,
                          quizDoc.reference,
                          title,
                        );
                      }
                      if (value == 'delete') {
                        await _deleteQuiz(context, quizDoc.reference);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('✏️ Modifier le titre'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('🗑 Supprimer le quiz'),
                      ),
                    ],
                  ),

                  // 👉 ouvrir questions
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherQuizQuestionsScreen(
                          courseId: courseId,
                          quizId: quizDoc.id,
                          quizTitle: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ======================================================
  // ✏️ MODIFIER TITRE DU QUIZ
  // ======================================================
  void _editQuizTitleDialog(
    BuildContext context,
    DocumentReference quizRef,
    String currentTitle,
  ) {
    final ctrl = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le titre du quiz'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Titre du quiz',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = ctrl.text.trim();
              if (newTitle.isEmpty) return;

              await quizRef.update({'title': newTitle});
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🗑 SUPPRIMER QUIZ
  // ======================================================
  Future<void> _deleteQuiz(
    BuildContext context,
    DocumentReference quizRef,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le quiz'),
        content: const Text(
          'Cette action supprimera le quiz et toutes ses questions.\n\nContinuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await quizRef.delete();
    }
  }
}