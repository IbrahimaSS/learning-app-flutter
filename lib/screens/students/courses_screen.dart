import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/course_service.dart';
import '../../services/lesson_service.dart';
import '../../services/progress_service.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  final bool isTeacher;
  const CoursesScreen({super.key, this.isTeacher = false});

  @override
  Widget build(BuildContext context) {
    final courseService = CourseService();
    final lessonService = LessonService();
    final progressService = ProgressService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        centerTitle: false,
        title: Text(
          isTeacher ? 'Gestion des Cours' : 'Tous les Cours',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: isTeacher
            ? null
            : [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list_rounded, size: 20),
                  ),
                  onPressed: () => _showFilterOptions(context),
                ),
              ],
      ),
      // Bouton flottant "Nouveau Cours" seulement pour les enseignants
      floatingActionButton: isTeacher ? _buildAddCourseFAB(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adapte le padding en fonction de la largeur de l'écran
          final double horizontalPadding = constraints.maxWidth > 600
              ? (constraints.maxWidth - 600) / 2
              : 24;
          
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600, // Largeur maximale pour le contenu
              ),
              child: StreamBuilder(
                stream: courseService.getCourses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState(constraints);
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(constraints);
                  }

                  final courses = snapshot.data?.docs ?? [];
                  if (courses.isEmpty) {
                    return _buildEmptyState(constraints);
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header avec statistiques
                        if (!isTeacher) _buildHeaderStats(courses.length, constraints),
                        if (!isTeacher) const SizedBox(height: 28),

                        // Liste des cours
                        if (!isTeacher) ...[
                          Text(
                            'Découvrir les cours'.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        ...courses.map((course) {
                          final courseId = course.id;
                          final category = (course['category'] ?? '—').toString();
                          final title = (course['title'] ?? 'Sans titre').toString();
                          final description =
                              (course['description'] ?? 'Aucune description').toString();

                          return _CourseCardPremium(
                            courseId: courseId,
                            title: title,
                            category: category,
                            description: description,
                            lessonCountStream: lessonService.lessonCountStream(courseId),
                            doneCountStream: user == null
                                ? Stream<int>.value(0)
                                : progressService.doneCountStream(user.uid, courseId),
                            isTeacher: isTeacher,
                            onOpen: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      CourseDetailScreen(
                                    courseId: courseId,
                                    title: title,
                                    category: category,
                                    description: description,
                                  ),
                                  transitionsBuilder:
                                      (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOutCubic;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    var offsetAnimation = animation.drive(tween);
                                    return SlideTransition(
                                        position: offsetAnimation, child: child);
                                  },
                                  transitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 80), // Espace pour le FAB
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Bouton flottant "Nouveau Cours" - IDENTIQUE à "Nouveau Quiz"
  Widget _buildAddCourseFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton.extended(
        onPressed: () {
          // LOGIQUE POUR CRÉER UN NOUVEAU COURS
          // À REMPLACER PAR VOTRE LOGIQUE EXISTANTE
        },
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'Nouveau Cours',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ==================== ÉTATS DE L'INTERFACE ====================

  Widget _buildLoadingState(BoxConstraints constraints) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BoxConstraints constraints) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth > 400 ? 80 : 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: constraints.maxWidth > 400 ? 140 : 120,
              height: constraints.maxWidth > 400 ? 140 : 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger les cours. Vérifiez votre connexion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: constraints.maxWidth > 400 ? 16 : 15,
                color: const Color(0xFF64748B).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 400 ? 40 : 32,
                  vertical: 16,
                ),
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BoxConstraints constraints) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth > 400 ? 80 : 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: constraints.maxWidth > 400 ? 140 : 120,
              height: constraints.maxWidth > 400 ? 140 : 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Aucun cours disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isTeacher
                  ? 'Créez votre premier cours en cliquant sur le bouton "Nouveau Cours"'
                  : 'Les cours apparaîtront ici une fois créés par vos enseignants.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: constraints.maxWidth > 400 ? 16 : 15,
                color: const Color(0xFF64748B).withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== COMPOSANTS D'INTERFACE ====================

  Widget _buildHeaderStats(int courseCount, BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(constraints.maxWidth > 400 ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$courseCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cours disponibles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Apprentissage actif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        margin: EdgeInsets.only(
          left: MediaQuery.of(context).size.width > 600 ? 
            (MediaQuery.of(context).size.width - 600) / 2 : 16,
          right: MediaQuery.of(context).size.width > 600 ? 
            (MediaQuery.of(context).size.width - 600) / 2 : 16,
          bottom: 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Filtrer les cours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              ...['Tous les cours', 'En cours', 'Terminés', 'Nouveaux']
                  .map((option) => _buildFilterOption(option))
                  .toList(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Text(
                  'Appliquer les filtres',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const SizedBox(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCardPremium extends StatelessWidget {
  final String courseId;
  final String title;
  final String category;
  final String description;
  final Stream<int> lessonCountStream;
  final Stream<int> doneCountStream;
  final bool isTeacher;
  final VoidCallback onOpen;

  const _CourseCardPremium({
    required this.courseId,
    required this.title,
    required this.category,
    required this.description,
    required this.lessonCountStream,
    required this.doneCountStream,
    required this.isTeacher,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: lessonCountStream,
      builder: (context, lessonSnap) {
        final total = lessonSnap.data ?? 0;

        return StreamBuilder<int>(
          stream: doneCountStream,
          builder: (context, doneSnap) {
            final done = doneSnap.data ?? 0;
            final progress = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(20),
                highlightColor: const Color(0xFF3B82F6).withOpacity(0.05),
                splashColor: const Color(0xFF3B82F6).withOpacity(0.1),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 40,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge du cours avec gradient
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.9),
                              const Color(0xFF1D4ED8).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Catégorie
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Titre
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Description
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF64748B).withOpacity(0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Progress bar et statistiques (masqué pour enseignant)
                            if (!isTeacher)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Barre de progression
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Informations de progression
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$done/$total leçons terminées',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}