import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> pickAndUploadFile({
    required String courseId,
    required String type,
  }) async {
    // 1️⃣ Ouvrir l’explorateur de fichiers
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: type == 'pdf' ? ['pdf'] : ['mp4'],
    );

    if (result == null) return null;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    // 2️⃣ Upload vers Firebase Storage
    final ref = _storage
        .ref()
        .child('courses/$courseId/$type/$fileName');

    await ref.putFile(file);

    // 3️⃣ Récupérer URL publique
    final url = await ref.getDownloadURL();

    return url;
  }
}
