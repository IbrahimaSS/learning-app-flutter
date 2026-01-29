import 'package:cloud_firestore/cloud_firestore.dart';
import 'progress_service.dart';

class BadgeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProgressService _progressService = ProgressService();

  Future<void> checkAndGrantBadges(String userId) async {
    final badgesRef = _db.collection('users').doc(userId).collection('badges');

    // 🔢 Stats réelles
    final totalDone = await _progressService
        .totalDoneLessonsStream(userId)
        .first;

    final coursesFollowed = await _progressService
        .followedCoursesCountStream(userId)
        .first;

    final totalLessons = await _progressService
        .totalLessonsFollowedStream(userId)
        .first;

    final progress =
        totalLessons == 0 ? 0.0 : totalDone / totalLessons;

    // 🏆 BADGES
    await _grantOnce(badgesRef,
        id: 'first_step',
        condition: totalDone >= 1,
        title: 'Premier pas',
        icon: 'first_step');

    await _grantOnce(badgesRef,
        id: 'active',
        condition: totalDone >= 5,
        title: 'Apprenant actif',
        icon: 'active');

    await _grantOnce(badgesRef,
        id: 'engaged',
        condition: coursesFollowed >= 3,
        title: 'Engagé',
        icon: 'engaged');

    await _grantOnce(badgesRef,
        id: 'expert',
        condition: totalDone > 0 && progress >= 1.0,
        title: 'Expert',
        icon: 'expert');

    await _grantOnce(badgesRef,
        id: 'master',
        condition: progress >= 1.0 && totalLessons >= 10,
        title: 'Master',
        icon: 'master');
  }

  Future<void> _grantOnce(
    CollectionReference badgesRef, {
    required String id,
    required bool condition,
    required String title,
    required String icon,
  }) async {
    if (!condition) return;

    final doc = await badgesRef.doc(id).get();
    if (doc.exists) return;

    await badgesRef.doc(id).set({
      'title': title,
      'icon': icon,
      'earnedAt': Timestamp.now(),
    });
  }

  // 🔁 stream badges
  Stream<QuerySnapshot> badgesStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('badges')
        .snapshots();
  }
}
