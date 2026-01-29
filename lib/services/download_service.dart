import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<File> downloadPdf(String url, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.pdf');

    if (await file.exists()) return file;

    await Dio().download(url, file.path);
    return file;
  }
}
