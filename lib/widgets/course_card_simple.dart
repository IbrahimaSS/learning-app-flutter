import 'package:flutter/material.dart';

class CourseCardSimple extends StatelessWidget {
  final String category;
  final String title;
  final String lessons;

  const CourseCardSimple({
    super.key,
    required this.category,
    required this.title,
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone image bleue
          Container(
            height: 140,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              gradient: LinearGradient(
                colors: [Color(0xFF2F3C7E), Color(0xFF4A5FC1)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.menu_book, color: Colors.white, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(lessons),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
