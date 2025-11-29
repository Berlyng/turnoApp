import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turnofacil_app/screens/base_screen.dart'; 
import 'firebase_options.dart'; 

void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de cualquier llamada nativa (como Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  
  // INICIALIZACIÓN CORREGIDA: Usando las opciones generadas
  try {
    await Firebase.initializeApp(
      // La clave está en usar las opciones generadas para la plataforma actual
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase inicializado con éxito.");
  } catch (e) {
    // Si falla, se imprime el error para debug.
    print("Error crítico al inicializar Firebase: $e");
    // Es posible que la aplicación no funcione correctamente sin Firebase.
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TurnoFácil Barbershop',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        // Usamos Inter como fuente predeterminada
        fontFamily: 'Inter', 
      ),
      home: const BaseScreen(), // Redirige al flujo de autenticación/rol
    );
  }
}