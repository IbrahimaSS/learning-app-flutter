import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_result_screen.dart';

class TakeQuizScreen extends StatefulWidget {
  final String courseId;
  final String quizId;
  final String quizTitle;

  const TakeQuizScreen({
    super.key,
    required this.courseId,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  List<QueryDocumentSnapshot> _questions = [];
  int _currentIndex = 0;
  int _score = 0;

  int _correctAnswers = 0;
  int _wrongAnswers = 0;

  int? _remainingSeconds;
  int? _totalSeconds;
  Timer? _timer;

  int? _selectedAnswer;
  bool _answered = false;

  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ======================================================
  // 🔥 LOAD QUIZ + TIMER
  // ======================================================
  Future<void> _loadQuiz() async {
    final quizDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('quizzes')
        .doc(widget.quizId)
        .get();

    final data = quizDoc.data();
    final dynamic ts = data?['timerSeconds'];
    final int? timerSeconds = (ts is int) ? ts : int.tryParse('$ts');

    final qSnap = await quizDoc.reference
        .collection('questions')
        .orderBy('createdAt')
        .get();

    if (!mounted) return;

    setState(() {
      _questions = qSnap.docs;
      _remainingSeconds = timerSeconds;
      _totalSeconds = timerSeconds;
    });

    if (timerSeconds != null && timerSeconds > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds == null) return;

      if (_remainingSeconds! <= 1) {
        timer.cancel();
        _finishQuiz();
      } else {
        setState(() => _remainingSeconds = _remainingSeconds! - 1);
      }
    });
  }

  // ======================================================
  // ✅ ANSWER LOGIC
  // ======================================================
  void _selectAnswer(int index) {
    if (_answered) return;

    final q = _questions[_currentIndex];
    final int correct = q['correctIndex'];

    setState(() {
      _selectedAnswer = index;
      _answered = true;

      if (index == correct) {
        _score += (q['score'] as num).toInt();
        _correctAnswers++;
      } else {
        _wrongAnswers++;
      }
    });

    Future.delayed(const Duration(seconds: 1), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  // ======================================================
  // 🧠 FIN QUIZ + NOTIFICATION + CERTIFICAT
  // ======================================================
  Future<void> _finishQuiz() async {
    _timer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final int total = _questions.length;
    final int percent = total == 0 ? 0 : ((_score / total) * 100).round();
    final int timeSpentSeconds =
        DateTime.now().difference(_startedAt).inSeconds;

    const int cooldownMinutes = 5;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // =======================
    // 1️⃣ SAUVEGARDE RÉSULTAT
    // =======================
    await userRef.collection('quiz_results').doc(widget.quizId).set({
      'quizId': widget.quizId,
      'quizTitle': widget.quizTitle,
      'courseId': widget.courseId,
      'score': _score,
      'total': total,
      'percent': percent,
      'correctAnswers': _correctAnswers,
      'wrongAnswers': _wrongAnswers,
      'timeSpentSeconds': timeSpentSeconds,
      'createdAt': FieldValue.serverTimestamp(),
      'lastCompletedAt': FieldValue.serverTimestamp(),
      'cooldownMinutes': cooldownMinutes,
    }, SetOptions(merge: true));

    // =======================
    // 2️⃣ NOTIFICATION ENSEIGNANT (CORRIGÉ)
    // =======================
    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .get();

    final courseData = courseDoc.data();
    final String? teacherId = courseData?['teacherId'];

    if (teacherId != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'quiz_completed',
        'teacherId': teacherId,
        'studentId': user.uid,
        'studentName': user.displayName ?? user.email,
        'quizId': widget.quizId,
        'quizTitle': widget.quizTitle,
        'courseId': widget.courseId,
        'percent': percent,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    // =======================
    // 3️⃣ CERTIFICAT AUTO
    // =======================
    if (percent >= 70) {
      final certRef =
          userRef.collection('certificates').doc(widget.courseId);
      final certSnap = await certRef.get();

      if (!certSnap.exists) {
        await certRef.set({
          'courseId': widget.courseId,
          'courseTitle': widget.quizTitle,
          'percent': percent,
          'issuedAt': FieldValue.serverTimestamp(),
          'sourceQuizId': widget.quizId,
          'pdfUrl': null,
        });
      }
    }

    // =======================
    // 4️⃣ RÉSULTATS
    // =======================
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          score: _score,
          total: total,
          timeSpent: timeSpentSeconds,
          correctAnswers: _correctAnswers,
          wrongAnswers: _wrongAnswers,
          nextAvailableIn: cooldownMinutes,
        ),
      ),
    );
  }

  // ======================================================
  // 🎨 UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = _questions[_currentIndex];
    final List<String> options = List<String>.from(q['options']);
    final int correct = q['correctIndex'];
    final double progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.quizTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: (_remainingSeconds != null && _totalSeconds != null)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: (_remainingSeconds! / _totalSeconds!)
                      .clamp(0.0, 1.0),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  q['question'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(options.length, (i) {
                  Color border = Colors.grey.shade300;
                  Color bg = Colors.white;

                  if (_answered) {
                    if (i == correct) {
                      border = Colors.green;
                      bg = Colors.green.withOpacity(0.1);
                    } else if (i == _selectedAnswer) {
                      border = Colors.red;
                      bg = Colors.red.withOpacity(0.1);
                    }
                  }

                  return GestureDetector(
                    onTap: _answered ? null : () => _selectAnswer(i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 2),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: border,
                            child: Text(
                              String.fromCharCode(65 + i),
                              style:
                                  const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(options[i])),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
