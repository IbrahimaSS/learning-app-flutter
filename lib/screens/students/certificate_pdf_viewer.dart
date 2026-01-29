import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CertificatePdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const CertificatePdfViewer({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<CertificatePdfViewer> createState() => _CertificatePdfViewerState();
}

class _CertificatePdfViewerState extends State<CertificatePdfViewer> {
  String? localPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur chargement PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : localPath == null
              ? const Center(child: Text('Impossible d’ouvrir le PDF'))
              : PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  autoSpacing: true,
                  pageFling: true,
                ),
    );
  }
}