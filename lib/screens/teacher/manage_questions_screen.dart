import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageQuestionsScreen extends StatelessWidget {
  final String courseId;
  final String quizId;

  const ManageQuestionsScreen({
    super.key,
    required this.courseId,
    required this.quizId,
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
        title: const Text('Questions du quiz'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 👉 écran ajout question (déjà fait étape 4)
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: questionsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;

          if (questions.isEmpty) {
            return const Center(child: Text('Aucune question'));
          }

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(q['text']),
                  subtitle: Text(
                    'Score : ${q['score']} | Bonne réponse : ${q['correctIndex'] + 1}',
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await q.reference.delete();
                      }
                      if (value == 'edit') {
                        _editQuestionDialog(
                          context,
                          q.reference,
                          q,
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ======================================================
  // ✏️ MODIFIER QUESTION
  // ======================================================
  void _editQuestionDialog(
    BuildContext context,
    DocumentReference ref,
    QueryDocumentSnapshot q,
  ) {
    final textCtrl = TextEditingController(text: q['text']);
    final scoreCtrl =
        TextEditingController(text: q['score'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier la question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration:
                  const InputDecoration(labelText: 'Question'),
            ),
            TextField(
              controller: scoreCtrl,
              decoration:
                  const InputDecoration(labelText: 'Score'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.update({
                'text': textCtrl.text.trim(),
                'score': int.parse(scoreCtrl.text),
              });
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}