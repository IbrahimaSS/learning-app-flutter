import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_question_screen.dart';

class TeacherQuizQuestionsScreen extends StatelessWidget {
  final String courseId;
  final String quizId;
  final String quizTitle;

  const TeacherQuizQuestionsScreen({
    super.key,
    required this.courseId,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    final questionsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Questions – $quizTitle',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ➕ AJOUTER QUESTION
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateQuestionScreen(
                courseId: courseId,
                quizId: quizId,
              ),
            ),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: questionsRef.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;

          if (questions.isEmpty) {
            return const Center(
              child: Text(
                'Aucune question pour ce quiz',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(q['question']),
                  subtitle: Text('Score : ${q['score']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await q.reference.delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}