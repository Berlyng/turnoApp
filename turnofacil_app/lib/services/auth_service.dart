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

  // -------------------------
  // 2. INICIO DE SESIÓN
  // -------------------------
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print("Error en login: $e");
      return null;
    }
  }

  // -------------------------
  // 3. OBTENER ROL DEL USUARIO
  // -------------------------
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') ?? 'cliente';
      }
      return 'cliente';
    } catch (e) {
      print("Error al obtener rol: $e");
      return 'cliente';
    }
  }



}