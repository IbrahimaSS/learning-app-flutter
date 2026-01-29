import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/progress_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final progressService = ProgressService();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Ma progression',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🔥 QUIZ STATS
          _sectionTitle('Quiz'),
          _statGrid([
            _quizStat(
              title: 'Quiz résolus',
              icon: Icons.quiz,
              stream: progressService.totalQuizzesDoneStream(user.uid),
            ),
            _quizStat(
              title: 'Score moyen',
              icon: Icons.trending_up,
              suffix: '%',
              stream: progressService.averageQuizScoreStream(user.uid),
            ),
          ]),

          const SizedBox(height: 20),

          // 🕒 DERNIER QUIZ
          _lastQuizCard(progressService, user.uid),

          const SizedBox(height: 28),

          // 📚 COURS
          _sectionTitle('Cours & Leçons'),
          _statGrid([
            _quizStat(
              title: 'Cours suivis',
              icon: Icons.menu_book,
              stream:
                  progressService.followedCoursesCountStream(user.uid),
            ),
            _quizStat(
              title: 'Leçons terminées',
              icon: Icons.check_circle,
              stream:
                  progressService.totalDoneLessonsStream(user.uid),
            ),
          ]),

          const SizedBox(height: 28),

          // 📊 PROGRESSION GLOBALE
          _globalProgressCard(progressService, user.uid),
        ],
      ),
    );
  }

  // ======================================================
  // 🧩 UI COMPONENTS
  // ======================================================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _statGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: children,
    );
  }

  Widget _quizStat({
    required String title,
    required IconData icon,
    required Stream<num> stream,
    String suffix = '',
  }) {
    return StreamBuilder<num>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 30),
              const Spacer(),
              Text(
                '$value$suffix',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======================================================
  // 🕒 DERNIER QUIZ
  // ======================================================
  Widget _lastQuizCard(
      ProgressService service, String userId) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.lastQuizStream(userId),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (data == null) {
          return _emptyCard('Aucun quiz passé pour le moment');
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.history,
                  size: 32, color: Color(0xFF6C63FF)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['quizTitle'] ?? 'Quiz',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score : ${data['percent']}%',
                      style: TextStyle(color: Colors.grey[600]),
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

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  // ======================================================
  // 📊 PROGRESSION GLOBALE
  // ======================================================
  Widget _globalProgressCard(
      ProgressService service, String userId) {
    return StreamBuilder<int>(
      stream: service.totalLessonsFollowedStream(userId),
      builder: (context, totalSnap) {
        final total = totalSnap.data ?? 0;

        return StreamBuilder<int>(
          stream: service.totalDoneLessonsStream(userId),
          builder: (context, doneSnap) {
            final done = doneSnap.data ?? 0;
            final progress =
                total == 0 ? 0.0 : done / total;

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progression globale',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toInt()} %'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}