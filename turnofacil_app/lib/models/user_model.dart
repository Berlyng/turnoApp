class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'cliente' o 'barbero'

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  // Constructor para crear el objeto desde un DocumentSnapshot de Firestore
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'cliente', // Por defecto es cliente
    );
  }

  // Método para convertir el objeto a un Map (para guardarlo en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}