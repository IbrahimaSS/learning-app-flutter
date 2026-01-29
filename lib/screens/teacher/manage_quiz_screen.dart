import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/course_service.dart';
import 'teacher_quiz_list_screen.dart';

class ManageQuizScreen extends StatelessWidget {
  const ManageQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseService = CourseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des Quiz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: courseService.getCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun cours disponible',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final courses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final title = course['title'] ?? 'Sans titre';
              final category = course['category'] ?? 'Non catégorisé';
              
              // Couleurs basées sur l'index pour la variété
              final colors = [
                Colors.blue.shade700,
                Colors.green.shade700,
                Colors.orange.shade700,
                Colors.purple.shade700,
                Colors.red.shade700,
                Colors.teal.shade700,
              ];
              final colorIndex = index % colors.length;
              final color = colors[colorIndex];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherQuizListScreen(
                            courseId: course.id,
                            courseTitle: title,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Icône colorée
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconForCategory(category),
                              color: color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Informations du cours
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                
                                // Catégorie
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Flèche
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.deepPurple,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('multimedia') ||
        categoryLower.contains('animation') ||
        categoryLower.contains('montage') ||
        categoryLower.contains('photo')) {
      return Icons.photo_camera_rounded;
    } else if (categoryLower.contains('react') ||
        categoryLower.contains('web') ||
        categoryLower.contains('frontend')) {
      return Icons.web_rounded;
    } else if (categoryLower.contains('flutter') ||
        categoryLower.contains('mobile')) {
      return Icons.phone_android_rounded;
    } else if (categoryLower.contains('python') ||
        categoryLower.contains('programmation')) {
      return Icons.code_rounded;
    } else {
      return Icons.menu_book_rounded;
    }
  }
}