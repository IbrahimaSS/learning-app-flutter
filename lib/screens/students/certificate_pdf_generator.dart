import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

Future<File> generateCertificatePdf({
  required String name,
  required String courseTitle,
  required int percent,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'CERTIFICAT DE RÉUSSITE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Décerné à', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Text(
              name,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Pour avoir réussi le cours',
              style: pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              courseTitle,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Score obtenu : $percent%',
              style: pw.TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/certificat_${DateTime.now().millisecondsSinceEpoch}.pdf');

  await file.writeAsBytes(await pdf.save());
  return file;
}