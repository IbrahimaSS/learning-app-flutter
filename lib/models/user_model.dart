class UserModel {
  final String id;
  final String nom;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      nom: data['nom'],
      email: data['email'],
      role: data['role'],
    );
  }
}
