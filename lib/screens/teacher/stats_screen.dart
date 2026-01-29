import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final screenWidth = constraints.maxWidth;
          
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 0 : 24,
              vertical: isMobile ? 16 : 24,
            ),
            child: Column(
              children: [
                // Titre principal
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Container(
                    padding: EdgeInsets.only(bottom: isMobile ? 20 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: isMobile ? 22 : 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[900],
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.only(left: isMobile ? 16 : 28),
                          child: Text(
                            'Statistiques globales en temps réel',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cartes de statistiques - Avec petit espacement
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          title: 'Apprenants',
                          stream: db.collection('users').snapshots(),
                          isMobile: isMobile,
                          index: 0,
                        ),
                      ),
                      SizedBox(width: isMobile ? 4 : 8), // Petit espacement
                      Expanded(
                        child: _statBox(
                          title: 'Quiz',
                          stream: db.collectionGroup('quizzes').snapshots(),
                          isMobile: isMobile,
                          index: 1,
                        ),
                      ),
                      SizedBox(width: isMobile ? 4 : 8), // Petit espacement
                      Expanded(
                        child: _statBox(
                          title: 'Cours',
                          stream: db.collection('courses').snapshots(),
                          isMobile: isMobile,
                          index: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Carte du graphique
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: StreamBuilder<List<int>>(
                      stream: _statsStream(db),
                      builder: (context, snapshot) {
                        final users = snapshot.data?[0] ?? 0;
                        final quizzes = snapshot.data?[1] ?? 0;
                        final courses = snapshot.data?[2] ?? 0;

                        return Column(
                          children: [
                            // En-tête de la carte
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Répartition des données',
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Visualisation par catégories',
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.pie_chart_outline,
                                        size: 14,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Graphique',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Graphique seul (sans légende)
                            _buildPieChart(
                              users: users,
                              quizzes: quizzes,
                              courses: courses,
                              screenWidth: screenWidth,
                              isMobile: isMobile,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================== GRAPHIQUE ==================
  Widget _buildPieChart({
    required int users,
    required int quizzes,
    required int courses,
    required double screenWidth,
    required bool isMobile,
  }) {
    double chartSize;
    if (isMobile) {
      chartSize = screenWidth * 0.6;
    } else {
      chartSize = 240;
    }

    return Container(
      width: chartSize,
      height: chartSize,
      padding: const EdgeInsets.all(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: chartSize * 0.25,
              sections: [
                _section(
                  value: users.toDouble(),
                  color: const Color(0xFF3B82F6),
                ),
                _section(
                  value: quizzes.toDouble(),
                  color: const Color(0xFF8B5CF6),
                ),
                _section(
                  value: courses.toDouble(),
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),

          // Texte central
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${users + quizzes + courses}',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[900],
                ),
              ),
              Text(
                'éléments',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      )
    );
  }

  // ================== STREAM GLOBAL ==================
  Stream<List<int>> _statsStream(FirebaseFirestore db) async* {
    final users = db.collection('users').snapshots();
    final quizzes = db.collectionGroup('quizzes').snapshots();
    final courses = db.collection('courses').snapshots();

    await for (final u in users) {
      final q = await quizzes.first;
      final c = await courses.first;

      yield [
        u.docs.length,
        q.docs.length,
        c.docs.length,
      ];
    }
  }

  // ================== SECTION DU GRAPHIQUE ==================
  PieChartSectionData _section({
    required double value,
    required Color color,
  }) {
    return PieChartSectionData(
      value: value == 0 ? 1 : value,
      color: color,
      radius: 20,
      showTitle: false,
    );
  }

  // ================== CARTE STATISTIQUE ==================
  Widget _statBox({
    required String title,
    required Stream<QuerySnapshot> stream,
    required bool isMobile,
    required int index,
  }) {
    final List<Map<String, dynamic>> cardData = [
      {
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      },
      {
        'color': const Color(0xFF8B5CF6),
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      },
      {
        'color': const Color(0xFF10B981),
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
      },
    ];

    final data = cardData[index % cardData.length];

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: data['gradient'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12), // Coins arrondis légers
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              // Nombre
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              
              // Indicateur de progression
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+0%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}