import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learning/screens/students/certificate_pdf_generator.dart';
import 'package:learning/screens/students/certificate_pdf_screen.dart';

import 'certificate_pdf_viewer.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    final certsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('certificates')
        .orderBy('issuedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes certificats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: certsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Aucun certificat obtenu pour le moment'),
            );
          }

          final certs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certs.length,
            itemBuilder: (context, index) {
              final data = certs[index].data() as Map<String, dynamic>;

              final String title = data['quizTitle'] ?? 'Certificat';
              final int percent = data['percent'] ?? 0;
              final String? pdfUrl = data['pdfPath'];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.green,
                    size: 32,
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Score obtenu : $percent%'),
                  trailing: const Icon(Icons.picture_as_pdf_rounded),
                  onTap: () async {
                    final file = await generateCertificatePdf(
                      name: user.displayName ?? 'Apprenant',
                      courseTitle: data['courseTitle'],
                      percent: percent,
                    );
                    //Le clique ouvre le PDF généré
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CertificatePdfScreen(
                          pdfPath: file.path,
                          title: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}