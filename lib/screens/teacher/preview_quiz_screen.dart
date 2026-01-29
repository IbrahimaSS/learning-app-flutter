import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizPreviewScreen extends StatefulWidget {
  final String courseId;
  final String quizId;

  const QuizPreviewScreen({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
  bool _loading = true;

  List<QueryDocumentSnapshot> _questions = [];
  int _index = 0;

  int _score = 0;
  bool _answered = false;
  int? _selectedIndex;

  // ⏱ Timer
  Timer? _timer;
  int _timeLeft = 0;
  int _timerSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() => _loading = true);

    // 1) Lire le quiz (pour récupérer timerSeconds)
    final quizDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('quizzes')
        .doc(widget.quizId)
        .get();

    _timerSeconds = (quizDoc.data()?['timerSeconds'] ?? 0) as int;

    // 2) Lire les questions
    final qSnap = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('questions')
        .orderBy('createdAt', descending: false) // optionnel
        .get();

    _questions = qSnap.docs;

    // Init timer si activé
    if (_timerSeconds > 0) {
      _startTimer();
    }

    setState(() => _loading = false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _timerSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        t.cancel();
        _timeLeft = 0;

        // Temps fini -> question considérée ratée -> passer à la suivante
        _goNext(auto: true);
      } else {
        setState(() => _timeLeft--);
      }
    });

    setState(() {});
  }

  void _selectAnswer(int i) {
    if (_answered) return;

    final q = _questions[_index];
    final correctIndex = (q['correctIndex'] ?? 0) as int;
    final score = (q['score'] ?? 0) as int;

    setState(() {
      _answered = true;
      _selectedIndex = i;

      if (i == correctIndex) {
        _score += score;
      }
    });

    // Pause timer pour éviter qu'il passe tout seul
    _timer?.cancel();
  }

  void _goNext({bool auto = false}) {
    if (_questions.isEmpty) return;

    // si auto (timer fini) et pas répondu -> on passe sans score
    if (!auto && !_answered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une réponse avant de continuer')),
      );
      return;
    }

    if (_index >= _questions.length - 1) {
      _showResult();
      return;
    }

    setState(() {
      _index++;
      _answered = false;
      _selectedIndex = null;
    });

    if (_timerSeconds > 0) {
      _startTimer();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Résultat (Prévisualisation)'),
        content: Text(
          'Score final : $_score\nQuestions : ${_questions.length}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Color _choiceColor(int i) {
    if (!_answered) return Colors.white;

    final q = _questions[_index];
    final correctIndex = (q['correctIndex'] ?? 0) as int;

    if (i == correctIndex) return Colors.green.withOpacity(0.15);
    if (_selectedIndex == i && i != correctIndex) {
      return Colors.red.withOpacity(0.15);
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Aucune question dans ce quiz')),
      );
    }

    final q = _questions[_index];
    final text = (q['text'] ?? '').toString();

    final List<dynamic> choicesDyn = (q['choices'] ?? []) as List<dynamic>;
    final choices = choicesDyn.map((e) => e.toString()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prévisualisation Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Haut (progress + timer)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Question ${_index + 1}/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_timerSeconds > 0)
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 18),
                      const SizedBox(width: 6),
                      Text('$_timeLeft s'),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Question
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 16),

            // Choix
            Expanded(
              child: ListView.builder(
                itemCount: choices.length,
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => _selectAnswer(i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _choiceColor(i),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey.shade200,
                            child: Text('${i + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(choices[i])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Score + bouton suivant
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Score: $_score',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _goNext(),
                  child: Text(
                    _index == _questions.length - 1 ? 'Terminer' : 'Suivant',
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}