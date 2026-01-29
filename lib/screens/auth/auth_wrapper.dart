import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../students/student_main_screen.dart';
import '../teacher/teacher_main_screen.dart';
import '../students/login_screens.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Non connecté
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // ✅ Connecté → on lit Firestore
        final uid = authSnapshot.data!.uid;

        return FutureBuilder<UserModel?>(
          future: UserService().getUserById(uid),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = userSnapshot.data!;

            // 🎓 Enseignant
            if (user.role == 'enseignant') {
              return const TeacherMainScreen();
            }

            // 👨‍🎓 Apprenant
            return const StudentMainScreen();
          },
        );
      },
    );
  }
}
