import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ======================================================
  // ✅ Marquer une leçon comme terminée
  // ======================================================
  Future<void> markLessonDone({
    required String userId,
    required String courseId,
    required String lessonId,
  }) async {
    final courseRef = _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(courseId);

    await courseRef.set({
      'courseId': courseId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await courseRef.collection('lessons').doc(lessonId).set({
      'done': true,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // ======================================================
  // 🔁 Leçons terminées POUR UN COURS
  // ======================================================
  Stream<int> doneCountStream(String userId, String courseId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(courseId)
        .collection('lessons')
        .where('done', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.size);
  }

  // ======================================================
  // 🔁 TOTAL leçons terminées (TOUS les cours)
  // ======================================================
  Stream<int> totalDoneLessonsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .snapshots()
        .asyncMap((coursesSnap) async {
      int total = 0;

      for (final course in coursesSnap.docs) {
        final lessonsSnap = await course.reference
            .collection('lessons')
            .where('done', isEqualTo: true)
            .get();

        total += lessonsSnap.size;
      }
      return total;
    });
  }

  // ======================================================
  // 📚 Nombre de cours suivis
  // ======================================================
  Stream<int> followedCoursesCountStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .snapshots()
        .map((snap) => snap.size);
  }

  // ======================================================
  // 📊 TOTAL DES LEÇONS RÉELLES
  // ======================================================
  Stream<int> totalLessonsFollowedStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .snapshots()
        .asyncMap((coursesSnap) async {
      int total = 0;

      for (final course in coursesSnap.docs) {
        final lessonsSnap = await _db
            .collection('courses')
            .doc(course.id)
            .collection('lessons')
            .get();

        total += lessonsSnap.size;
      }
      return total;
    });
  }

  // ======================================================
  // 🧠 NOMBRE TOTAL DE QUIZ RÉSOLUS
  // ======================================================
  Stream<int> totalQuizzesDoneStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('quiz_results')
        .snapshots()
        .map((snap) => snap.size);
  }

  // ======================================================
  // 📊 SCORE MOYEN DES QUIZ (%)
  // ======================================================
  Stream<num> averageQuizScoreStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('quiz_results')
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return 0;

          num totalPercent = 0;
          for (final doc in snap.docs) {
            totalPercent += (doc['percent'] ?? 0);
          }

          return (totalPercent / snap.docs.length).round();
        });
  }

  // ======================================================
  // 🕒 DERNIER QUIZ PASSÉ
  // ======================================================
  Stream<Map<String, dynamic>?> lastQuizStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('quiz_results')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return snap.docs.first.data();
        });
  }

  // ======================================================
// 📜 CERTIFICAT AUTOMATIQUE (moyenne ≥ 70 %)
// ======================================================
  Future<void> checkAndGrantCertificate(String userId) async {
    final certRef =
        _db.collection('users').doc(userId).collection('certificate').doc('main');

    // ❌ certificat déjà attribué
    final certSnap = await certRef.get();
    if (certSnap.exists) return;

    // 📊 calcul moyenne
    final quizSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('quiz_results')
        .get();

    if (quizSnap.docs.isEmpty) return;

    num total = 0;
    for (final doc in quizSnap.docs) {
      total += (doc['percent'] ?? 0);
    }

    final average = total / quizSnap.docs.length;

    // ✅ condition réussite
    if (average >= 70) {
      await certRef.set({
        'title': 'Certificat de réussite',
        'averageScore': average.round(),
        'earnedAt': Timestamp.now(),
        'status': 'valid',
      });
    }
  }
}