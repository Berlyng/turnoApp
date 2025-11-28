import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_detail_model.dart'; // Importa el nuevo modelo

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentClientId = FirebaseAuth.instance.currentUser?.uid;
    final DatabaseService dbService = DatabaseService();

    if (currentClientId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Mis Citas')),
        body: Center(child: Text('Error: No se encontró el ID del usuario.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // CAMBIO CLAVE: Usamos getClientAppointmentsWithBarberName
      body: StreamBuilder<List<AppointmentDetailModel>>(
        stream: dbService.getClientAppointmentsWithBarberName(currentClientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Firestore Error: ${snapshot.error}"); // Log para debug
            return Center(child: Text('Error al cargar las citas: ${snapshot.error}'));
          }

          final appointmentDetails = snapshot.data ?? [];

          if (appointmentDetails.isEmpty) {
            return const Center(
              child: Text(
                'Aún no has reservado ninguna cita.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: appointmentDetails.length,
            itemBuilder: (context, index) {
              final detail = appointmentDetails[index];
              return _buildAppointmentCard(context, detail);
            },
          );
        },
      ),
    );
  }

  // CAMBIO CLAVE: Ahora acepta AppointmentDetailModel
  Widget _buildAppointmentCard(BuildContext context, AppointmentDetailModel detail) {
    final appointment = detail.appointment;
    final dateString = MaterialLocalizations.of(context).formatShortDate(appointment.date);
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = Colors.green.shade100;
        statusText = 'Confirmada';
        statusIcon = Icons.check_circle_outline;
        break;
      case AppointmentStatus.rejected:
        statusColor = Colors.red.shade100;
        statusText = 'Rechazada';
        statusIcon = Icons.cancel_outlined;
        break;
      case AppointmentStatus.pending:
      default:
        statusColor = Colors.yellow.shade100;
        statusText = 'Pendiente de Confirmación';
        statusIcon = Icons.access_time;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      elevation: 3,
      color: statusColor,
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor == Colors.red.shade100 ? Colors.red.shade800 : Colors.indigo),
        title: Text(
          appointment.service,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          // AHORA MOSTRAMOS EL NOMBRE DEL BARBERO
          'Barbero: ${detail.barberName}\n' 
          'Día: $dateString, Hora: ${appointment.time}',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Text(
          statusText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor == Colors.red.shade100 ? Colors.red.shade900 : Colors.indigo,
          ),
        ),
      ),
    );
  }
}