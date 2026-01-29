import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final int timeSpent; // en secondes
  final int correctAnswers;
  final int wrongAnswers;
  final int? nextAvailableIn; // minutes restantes avant de pouvoir reprendre

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    this.timeSpent = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.nextAvailableIn,
  });

  @override
  Widget build(BuildContext context) {
    final int percent = total == 0 ? 0 : ((score / total) * 100).round();
    final bool isPassed = percent >= 70;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        centerTitle: false,
        title: const Text(
          'Résultats du Quiz',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              // Carte principale avec résultat
              _buildResultCard(isPassed, percent),
              const SizedBox(height: 32),

              // Statistiques détaillées
              if (timeSpent > 0 || correctAnswers > 0 || wrongAnswers > 0)
                _buildStatisticsSection(),
              
              // Message d'attente si applicable
              if (nextAvailableIn != null && nextAvailableIn! > 0)
                _buildWaitMessage(),
              const SizedBox(height: 32),

              // Bouton d'action
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== COMPOSANTS D'INTERFACE ====================

  /// Carte principale avec résultat
  Widget _buildResultCard(bool isPassed, int percent) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPassed
              ? [
                  const Color(0xFF10B981).withOpacity(0.9),
                  const Color(0xFF10B981).withOpacity(0.7),
                  const Color(0xFF059669).withOpacity(0.9),
                ]
              : [
                  const Color(0xFF3B82F6).withOpacity(0.9),
                  const Color(0xFF2563EB).withOpacity(0.7),
                  const Color(0xFF1D4ED8).withOpacity(0.9),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                .withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône résultat
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
            child: Icon(
              isPassed ? Icons.emoji_events_rounded : Icons.auto_graph_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 28),

          // Score principal
          Text(
            '$score / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),

          // Pourcentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Message
          Text(
            isPassed ? 'Quiz Réussi !' : 'Continuez à progresser',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Section des statistiques détaillées
  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'STATISTIQUES DÉTAILLÉES',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatRow(
                label: 'Réponses correctes',
                value: '$correctAnswers',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 0, color: Color(0xFFF1F5F9)),
              ),
              _buildStatRow(
                label: 'Réponses incorrectes',
                value: '$wrongAnswers',
                icon: Icons.cancel_rounded,
                color: const Color(0xFF3B82F6),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 0, color: Color(0xFFF1F5F9)),
              ),
              _buildStatRow(
                label: 'Temps passé',
                value: _formatTime(timeSpent),
                icon: Icons.timer_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Message d'attente avant de pouvoir reprendre
  Widget _buildWaitMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vous pourrez reprendre ce quiz dans $nextAvailableIn minute${nextAvailableIn! > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ligne de statistique individuelle
  Widget _buildStatRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// Bouton d'action principal
  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Retour à l'écran précédent (liste des quiz)
        Navigator.pop(context);
      },
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
        'Retour aux quiz',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Formater le temps en minutes:secondes
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}