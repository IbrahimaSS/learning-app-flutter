import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/lesson_service.dart';
import '../../services/progress_service.dart';

class LessonPlayerScreen extends StatefulWidget {
  final String courseId;
  final dynamic lesson; // QueryDocumentSnapshot

  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.lesson,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  final LessonService _lessonService = LessonService();
  final ProgressService _progressService = ProgressService();

  bool _downloading = false;
  double _progress = 0.0;

  VideoPlayerController? _videoController;
  bool _markedDone = false; // ✅ éviter double écriture Firestore

  bool get _isPdf => widget.lesson['type'] == 'pdf';
  bool get _isVideo => widget.lesson['type'] == 'video';

  String get _url => (widget.lesson['url'] ?? '').toString();
  String get _title => (widget.lesson['title'] ?? 'Leçon').toString();
  String get _lessonId => widget.lesson.id;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // ======================================================
  // ✅ MARQUER LA LEÇON COMME TERMINÉE (UNE SEULE FOIS)
  // ======================================================
  void _markLessonAsDoneOnce() {
    if (_markedDone) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _markedDone = true;

    _progressService.markLessonDone(
      userId: user.uid,
      courseId: widget.courseId,
      lessonId: _lessonId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _isPdf ? _pdfBody() : _videoBody(),
    );
  }

  // ======================================================
  // 📄 PDF (ONLINE / OFFLINE)
  // ======================================================
  Widget _pdfBody() {
    return FutureBuilder<bool>(
      future: _lessonService.isDownloaded(
        courseId: widget.courseId,
        lessonId: _lessonId,
        ext: 'pdf',
      ),
      builder: (context, snap) {
        final downloaded = snap.data ?? false;

        // 🌐 WEB
        if (kIsWeb) {
          _markLessonAsDoneOnce();
          return SfPdfViewer.network(_url);
        }

        return Column(
          children: [
            _downloadBar(downloaded: downloaded, ext: 'pdf'),
            Expanded(
              child: FutureBuilder<File>(
                future: _lessonService.getLocalFile(
                  courseId: widget.courseId,
                  lessonId: _lessonId,
                  ext: 'pdf',
                ),
                builder: (context, fileSnap) {
                  if (!fileSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final file = fileSnap.data!;
                  _markLessonAsDoneOnce();

                  if (downloaded && file.existsSync()) {
                    return SfPdfViewer.file(file);
                  }

                  return SfPdfViewer.network(_url);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // 🎥 VIDÉO (YouTube / MP4)
  // ======================================================
  Widget _videoBody() {
    final youtubeId = YoutubePlayer.convertUrlToId(_url);

    // ▶️ YOUTUBE
    if (youtubeId != null) {
      _markLessonAsDoneOnce();

      return YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: youtubeId,
          flags: const YoutubePlayerFlags(autoPlay: true),
        ),
        showVideoProgressIndicator: true,
      );
    }

    // ▶️ MP4
    return FutureBuilder<bool>(
      future: _lessonService.isDownloaded(
        courseId: widget.courseId,
        lessonId: _lessonId,
        ext: 'mp4',
      ),
      builder: (context, snap) {
        final downloaded = snap.data ?? false;

        return Column(
          children: [
            _downloadBar(downloaded: downloaded, ext: 'mp4'),
            Expanded(
              child: FutureBuilder<File>(
                future: _lessonService.getLocalFile(
                  courseId: widget.courseId,
                  lessonId: _lessonId,
                  ext: 'mp4',
                ),
                builder: (context, fileSnap) {
                  if (kIsWeb) {
                    _markLessonAsDoneOnce();
                    return _mp4PlayerNetwork(_url);
                  }

                  if (!fileSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final file = fileSnap.data!;
                  _markLessonAsDoneOnce();

                  if (downloaded && file.existsSync()) {
                    return _mp4PlayerFile(file);
                  }

                  return _mp4PlayerNetwork(_url);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // ⬇️ BARRE DE TÉLÉCHARGEMENT
  // ======================================================
  Widget _downloadBar({required bool downloaded, required String ext}) {
    if (kIsWeb) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            downloaded ? Icons.download_done : Icons.download,
            color: downloaded ? Colors.green : Colors.black87,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              downloaded
                  ? 'Disponible hors connexion'
                  : 'Télécharger pour lecture hors connexion',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_downloading)
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(value: _progress),
            )
          else
            ElevatedButton(
              onPressed: downloaded ? null : () => _download(ext),
              child: const Text('Télécharger'),
            ),
        ],
      ),
    );
  }

  Future<void> _download(String ext) async {
    setState(() {
      _downloading = true;
      _progress = 0.0;
    });

    try {
      await _lessonService.downloadToLocal(
        courseId: widget.courseId,
        lessonId: _lessonId,
        url: _url,
        ext: ext,
        onProgress: (received, total) {
          if (total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement terminé ✅')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // ======================================================
  // 🎬 MP4 PLAYERS
  // ======================================================
  Widget _mp4PlayerNetwork(String url) {
    return _mp4Player(
      controller: VideoPlayerController.networkUrl(Uri.parse(url)),
    );
  }

  Widget _mp4PlayerFile(File file) {
    return _mp4Player(
      controller: VideoPlayerController.file(file),
    );
  }

  Widget _mp4Player({required VideoPlayerController controller}) {
    _videoController?.dispose();
    _videoController = controller;

    return FutureBuilder(
      future: _videoController!.initialize(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        _videoController!.play();

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            VideoProgressIndicator(_videoController!, allowScrubbing: true),
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}