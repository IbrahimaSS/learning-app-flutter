import 'package:flutter/material.dart';

enum LessonStatus { done, video, pdf }

class LessonTile extends StatelessWidget {
  final String title;
  final String duration;
  final LessonStatus status;

  const LessonTile({
    super.key,
    required this.title,
    required this.duration,
    required this.status,
  });

  IconData get icon {
    switch (status) {
      case LessonStatus.done:
        return Icons.check_circle;
      case LessonStatus.video:
        return Icons.play_circle;
      case LessonStatus.pdf:
        return Icons.picture_as_pdf;
    }
  }

  Color get iconColor {
    switch (status) {
      case LessonStatus.done:
        return Colors.green;
      case LessonStatus.video:
        return Colors.grey;
      case LessonStatus.pdf:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
