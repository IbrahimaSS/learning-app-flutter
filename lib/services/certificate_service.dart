import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';            // ✅ OBLIGATOIRE
import 'package:pdf/widgets.dart' as pw;

class CertificateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> generateCertificate({
    required String quizId,
    required String quizTitle,
    required int percent,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final pdf = pw.Document();

    final String studentName =
        user.displayName?.isNotEmpty == true
            ? user.displayName!
            : (user.email ?? 'Apprenant');

    final String date =
        DateTime.now().toLocal().toString().split(' ')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // ✅ CORRECTION FINALE
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 3, color: PdfColors.grey700),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [

                // 🔷 TITRE
                pw.Text(
                  'CERTIFICAT DE RÉUSSITE',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                pw.SizedBox(height: 8),
                pw.Text(
                  'Plateforme E-learning',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),

                pw.SizedBox(height: 24),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 24),

                // 👤 NOM
                pw.Text(
                  'Ce certificat est décerné à',
                  style: pw.TextStyle(fontSize: 14),
                ),

                pw.SizedBox(height: 10),
                pw.Text(
                  studentName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),

                pw.SizedBox(height: 24),

                // 📘 QUIZ
                pw.Text(
                  'Pour avoir validé avec succès le quiz',
                  style: pw.TextStyle(fontSize: 14),
                ),

                pw.SizedBox(height: 8),
                pw.Text(
                  quizTitle,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 24),

                // 📊 SCORE
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.indigo200),
                  ),
                  child: pw.Text(
                    'Score obtenu : $percent%',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                ),

                pw.Spacer(),

                // 📅 DATE + SIGNATURE
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date'),
                        pw.Text(
                          date,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Signature'),
                        pw.SizedBox(height: 20),
                        pw.Container(
                          width: 140,
                          height: 1,
                          color: PdfColors.grey700,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // 💾 SAUVEGARDE LOCALE
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/certificat_$quizId.pdf');
    await file.writeAsBytes(await pdf.save());

    // 🔥 SAUVEGARDE FIRESTORE
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('certificates')
        .doc(quizId)
        .set({
      'quizId': quizId,
      'quizTitle': quizTitle,
      'percent': percent,
      'issuedAt': FieldValue.serverTimestamp(),
      'pdfPath': file.path,
    }, SetOptions(merge: true));

    return file.path;
  }
}