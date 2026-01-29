import 'package:cloud_firestore/cloud_firestore.dart';

class CourseService {
  final CollectionReference _courses =
      FirebaseFirestore.instance.collection('courses');

  // ➕ Ajouter
  Future<void> addCourse({
    required String title,
    required String category,
    required String description,
    required int totalLessons,
    required String teacherId,
  }) async {
    await _courses.add({
      'title': title,
      'category': category,
      'description': description,
      'totalLessons': totalLessons,
      'teacherId': teacherId,
      'createdAt': Timestamp.now(),
    });
  }

  // 📥 Lire
  Stream<QuerySnapshot> getCourses() {
    return _courses.orderBy('createdAt', descending: true).snapshots();
  }

  // ✏ Modifier
  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    await _courses.doc(id).update(data);
  }

  // ❌ Supprimer
  Future<void> deleteCourse(String id) async {
    await _courses.doc(id).delete();
  }
}
