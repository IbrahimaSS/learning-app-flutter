import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'take_quiz_screen.dart';

class StudentQuizListScreen extends StatelessWidget {
  final String courseId;

  const StudentQuizListScreen({
    super.key,
    required this.courseId,
  });

  /// 🔐 Vérifier si le quiz est disponible
  /// Retourne le nombre de minutes restantes avant de pouvoir reprendre
  Future<int?> _nextAvailableIn(String quizId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('quiz_results')
        .doc(quizId)
        .get();

    if (!doc.exists) return null;

    final Timestamp lastCompleted = doc['lastCompletedAt'];
    final int cooldownMinutes = doc['cooldownMinutes'] ?? 5;

    final diff = DateTime.now().difference(lastCompleted.toDate());
    final remaining = cooldownMinutes - diff.inMinutes;

    return remaining > 0 ? remaining : null;
  }

  @override
  Widget build(BuildContext context) {
    final quizzesRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('quizzes');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.black12,
        title: const Text(
          'Quiz disponibles',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: quizzesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2F3C7E),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun quiz disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final quizzes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              final data = quiz.data() as Map<String, dynamic>;

              final String title = data['title'] ?? 'Quiz';

              final dynamic ts = data['timerSeconds'];
              final int? timerSeconds =
                  (ts is int) ? ts : int.tryParse('$ts');

              return FutureBuilder<int?>(
                future: _nextAvailableIn(quiz.id),
                builder: (context, lockSnap) {
                  final int? nextAvailableIn = lockSnap.data;
                  final bool isLocked = nextAvailableIn != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (isLocked) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text(
                                  'Quiz indisponible',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                content: Text(
                                  'Veuillez revenir dans $nextAvailableIn minute(s) pour refaire ce quiz.',
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(
                                        color: Color(0xFF2F3C7E),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TakeQuizScreen(
                                courseId: courseId,
                                quizId: quiz.id,
                                quizTitle: title,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isLocked
                                  ? Colors.grey[300]!
                                  : const Color(0xFF2F3C7E).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? Colors.grey[100]
                                      : const Color(0xFF2F3C7E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.quiz_rounded,
                                  color: isLocked
                                      ? Colors.grey[500]
                                      : const Color(0xFF2F3C7E),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      timerSeconds != null && timerSeconds > 0
                                          ? 'Temps limité : $timerSeconds sec'
                                          : 'Sans limite de temps',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (isLocked)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFEBEE),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_clock,
                                                size: 14,
                                                color: Colors.red[700],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Disponible dans $nextAvailableIn min',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                isLocked
                                    ? Icons.lock_outline
                                    : Icons.arrow_forward_ios_rounded,
                                color: isLocked
                                    ? Colors.grey[500]
                                    : const Color(0xFF2F3C7E),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}