import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turnofacil_app/screens/client/client_screen_home.dart';
import '../services/auth_service.dart';
import 'barber/barber_dashboard_screen.dart'; 
import 'auth/login_screen.dart'; // Para volver al login si no hay usuario

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  final AuthService _authService = AuthService();
  
  // El rol del usuario se almacena aquí. Null mientras carga.
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() async {
    // 1. Obtener el usuario actual de Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // 2. Si hay usuario, consultar su rol en Firestore
      try {
        final role = await _authService.getUserRole(currentUser.uid);
        setState(() {
          _userRole = role;
        });
      } catch (e) {
        // En caso de error (ej. documento de usuario no encontrado)
        print("Error al obtener rol: $e");
        setState(() {
          _userRole = 'error'; // Marcar como error
        });
      }
    } else {
      // 3. Si no hay usuario autenticado, redirigir al login
      // Aunque esto no debería pasar justo después del login, es buena práctica.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Función para cerrar sesión y volver al login
  void _logout() async {
    await FirebaseAuth.instance.signOut();
     if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Muestra un indicador de carga mientras se consulta el rol
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } 
    
    // 2. Redirección basada en el rol
    else if (_userRole == 'cliente') {
      return const ClientHomeScreen();
    } 
    
    else if (_userRole == 'barbero' || _userRole == 'administrador') {
      return const BarberDashboardScreen();
    } 
    
    else {
      // 3. Manejo de roles desconocidos o errores
      return Scaffold(
        appBar: AppBar(title: const Text('Error de Sesión')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo verificar tu rol. Por favor, intenta de nuevo.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      );
    }
  }
}