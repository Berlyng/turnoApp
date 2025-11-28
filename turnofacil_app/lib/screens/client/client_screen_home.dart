import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turnofacil_app/screens/client/my_appointments_screen.dart';
import '../auth/login_screen.dart'; 
import 'booking_screen.dart'; 
import 'my_appointments_screen.dart'; // Importar la nueva pantalla

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  // Función para cerrar sesión (se usa en el IconButton y en BaseScreen)
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navegación para remover todas las rutas anteriores y establecer LoginScreen como la nueva raíz
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TurnoFácil - Reservar'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white, // Color de los iconos y texto
        actions: [
          // Botón para ir al Historial de Citas
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
              );
            },
            tooltip: 'Mis Citas',
          ),
          // Botón para Cerrar Sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¡Bienvenido Cliente!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            const Text(
              '¿Qué te gustaría hacer hoy?',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 60),

            // Botón principal para Reservar Nuevo Turno
            SizedBox(
              width: 250,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: const Text(
                  'Reservar Nuevo Turno',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BookingScreen()), 
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Botón secundario para Mis Citas
             SizedBox(
              width: 250,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history, color: Colors.indigo),
                label: const Text(
                  'Ver Mis Citas',
                  style: TextStyle(fontSize: 18, color: Colors.indigo),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.indigo, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}