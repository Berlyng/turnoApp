import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //--------------------------
  // 1. Registro de usuario
  //--------------------------
  Future<User?> signUp(String name, String email, String password) async {
    try {
      // 1. Crear el usuario en Firebase Authentication
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        // 2. Guardar el perfil en Firestore con el rol 'cliente'
        await _firestore.collection('usuarios').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': 'cliente', // Rol por defecto
        });
      }
      return user;
    } catch (e) {
      print("Error en registro: $e");
      return null;
    }
  }



}