import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LessonService {
  final _db = FirebaseFirestore.instance;
  final Dio _dio = Dio();

  // 🔁 Stream des leçons
  Stream<QuerySnapshot> getLessons(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .orderBy('createdAt')
        .snapshots();
  }

  // ✅ Compteur dynamique (stream)
  Stream<int> lessonCountStream(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ➕ Ajouter
  Future<void> addLesson(String courseId, Map<String, dynamic> data) async {
    data['createdAt'] = Timestamp.now();
    await _db.collection('courses').doc(courseId).collection('lessons').add(data);
  }

  // ❌ Supprimer
  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .doc(lessonId)
        .delete();

    // Optionnel : supprimer le cache local lié
    if (!kIsWeb) {
      final pdf = await getLocalFile(courseId: courseId, lessonId: lessonId, ext: 'pdf');
      if (pdf.existsSync()) pdf.deleteSync();

      final mp4 = await getLocalFile(courseId: courseId, lessonId: lessonId, ext: 'mp4');
      if (mp4.existsSync()) mp4.deleteSync();
    }
  }

  // =========================
  // 📥 OFFLINE HELPERS
  // =========================

  Future<Directory> _baseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final base = Directory(p.join(dir.path, 'edulearn_cache'));
    if (!base.existsSync()) base.createSync(recursive: true);
    return base;
  }

  Future<File> getLocalFile({
    required String courseId,
    required String lessonId,
    required String ext, // 'pdf' | 'mp4'
  }) async {
    final base = await _baseDir();
    final folder = Directory(p.join(base.path, 'courses', courseId));
    if (!folder.existsSync()) folder.createSync(recursive: true);

    return File(p.join(folder.path, '$lessonId.$ext'));
  }

  Future<bool> isDownloaded({
    required String courseId,
    required String lessonId,
    required String ext,
  }) async {
    if (kIsWeb) return false;
    final f = await getLocalFile(courseId: courseId, lessonId: lessonId, ext: ext);
    return f.existsSync() && f.lengthSync() > 0;
  }

  Future<File?> downloadToLocal({
    required String courseId,
    required String lessonId,
    required String url,
    required String ext, // 'pdf' | 'mp4'
    void Function(int received, int total)? onProgress,
  }) async {
    if (kIsWeb) return null; // offline fichier impossible sur web (comme mobile)

    final file = await getLocalFile(courseId: courseId, lessonId: lessonId, ext: ext);

    // si déjà présent, on renvoie
    if (file.existsSync() && file.lengthSync() > 0) return file;

    await _dio.download(
      url,
      file.path,
      onReceiveProgress: onProgress,
      options: Options(
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );

    return file;
  }
}