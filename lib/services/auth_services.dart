import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> register({
    required String nom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      // 1) Création du compte Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return null;

      // 2) Création du document Firestore users/{uid}
      await _db.collection('users').doc(user.uid).set({
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'role': 'apprenant',
      });

      return user;
    }
    catch (e) {
      if (e is FirebaseAuthException) {
        print('CODE: ${e.code}');
        print('MESSAGE: ${e.message}');
      } else {
        print('Erreur inconnue: $e');
      }
      return null;
    }
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print('Erreur connexion: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
