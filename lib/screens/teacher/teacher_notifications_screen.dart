import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherNotificationsScreen extends StatelessWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherId = FirebaseAuth.instance.currentUser?.uid;

    if (teacherId == null) {
      return const Center(child: Text('Non connecté'));
    }

    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'Aucune notification pour le moment',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final data = n.data() as Map<String, dynamic>;

              final studentName = data['studentName'] ?? 'Un apprenant';
              final quizTitle = data['quizTitle'] ?? 'Quiz';
              final createdAt = data['createdAt'] as Timestamp?;
              final dateText = createdAt == null
                  ? ''
                  : DateFormat('dd/MM à HH:mm').format(createdAt.toDate());

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(
                    '$studentName a terminé un quiz',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Quiz : $quizTitle\n$dateText',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}