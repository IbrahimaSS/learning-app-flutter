import 'package:flutter/material.dart';
import '../../services/course_service.dart';
import 'add_course_screen.dart';
import 'edit_course_screen.dart';
import 'teacher_course_detail_screen.dart';

class ManageCoursesScreen extends StatelessWidget {
  const ManageCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CourseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des Cours',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCourseScreen()),
            );
          },
          backgroundColor: const Color(0xFF667eea),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: service.getCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF667eea),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 50,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez par créer votre premier cours',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }

          final courses = snapshot.data!.docs;

          // Liste des cours avec SingleChildScrollView
          return SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 120, // Espace suffisant en bas
            ),
            child: Column(
              children: [
                // Afficher le nombre de cours disponible (optionnel)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${courses.length} cours disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                
                for (var i = 0; i < courses.length; i++)
                  _buildCourseCard(
                    context: context,
                    course: courses[i],
                    index: i,
                    service: service,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required dynamic course,
    required int index,
    required CourseService service,
  }) {
    final courseTitle = course['title'] ?? 'Sans titre';
    final courseCategory = course['category'] ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherCourseDetailScreen(
                  courseId: course.id,
                  courseData: course,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Badge de catégorie avec ombre plus marquée
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: _getCategoryGradient(index),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(index).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(courseTitle),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations du cours - Adaptation de la typographie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        courseCategory,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Menu d'actions
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherCourseDetailScreen(
                            courseId: course.id,
                            courseData: course,
                          ),
                        ),
                      );
                    } else if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditCourseScreen(
                            courseId: course.id,
                            courseData: course,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, service, course.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Afficher'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fonction pour afficher la boîte de dialogue de suppression
  void _showDeleteDialog(BuildContext context, CourseService service, String courseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce cours ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteCourse(courseId);
              Navigator.pop(context);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour obtenir le gradient en fonction de l'index
  LinearGradient _getCategoryGradient(int index) {
    final List<List<Color>> gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Violet
      [const Color(0xFF10B981), const Color(0xFF059669)], // Vert
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Orange
      [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Rouge
    ];
    
    return LinearGradient(
      colors: gradients[index % gradients.length],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Fonction pour obtenir la couleur principale du gradient
  Color _getCategoryColor(int index) {
    final List<Color> colors = [
      const Color(0xFF667eea), // Violet
      const Color(0xFF10B981), // Vert
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Rouge
    ];
    
    return colors[index % colors.length];
  }

  // Fonction pour obtenir l'icône en fonction du titre du cours
  IconData _getCategoryIcon(String title) {
    if (title.toLowerCase().contains('flutter')) {
      return Icons.phone_android_rounded;
    } else if (title.toLowerCase().contains('react')) {
      return Icons.web_rounded;
    } else if (title.toLowerCase().contains('multimedia')) {
      return Icons.videocam_rounded;
    } else if (title.toLowerCase().contains('python')) {
      return Icons.code_rounded;
    } else if (title.toLowerCase().contains('artificielle')) {
      return Icons.smart_toy_rounded;
    }
    return Icons.menu_book_rounded;
  }
}