import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //--------------------------
  // 1. Registro de usuario 
  //--------------------------
  Future<User?> signUp(
    String name, 
    String email, 
    String password, 
    String role 
  ) async {
    try {
      // Intenta crear el usuario
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        // Guarda el perfil de usuario en Firestore
        await _firestore.collection('usuarios').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': role // Guarda el rol proporcionado
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // Captura y muestra el mensaje de error específico de Firebase.
      print("Error específico de FirebaseAuth al registrar: ${e.code}");
      print("Mensaje de error: ${e.message}");
      return null;
    } catch (e) {
      // Captura cualquier otro error (ej. error de conexión de red)
      print("Error de registro (No FirebaseAuth): $e");
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

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Extrae el rol de forma segura, casteando a String? y usando 'cliente' si es nulo
        final roleString = (data['role'] as String?) ?? 'cliente'; 
        
        return roleString; 
      }

      // Si el documento no existe, asume 'cliente'
      return 'cliente'; 

    } catch (e) {
      print("Error al obtener rol: $e");
      // Respaldo en caso de error de conexión/lectura
      return 'cliente'; 
    }
  }
}