import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/appointment_model.dart';
import '../auth/login_screen.dart'; 

class BarberDashboardScreen extends StatefulWidget {
  const BarberDashboardScreen({super.key});

  @override
  State<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends State<BarberDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String? _currentBarberId = FirebaseAuth.instance.currentUser?.uid;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Lógica para manejar la acción del barbero (Confirmar/Rechazar)
  void _handleStatusUpdate(AppointmentModel appointment, AppointmentStatus status) async {
    try {
      await _dbService.updateAppointmentStatus(
        appointmentId: appointment.id,
        newStatus: status,
      );
      // Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cita de ${appointment.clientName} ha sido ${status == AppointmentStatus.confirmed ? "CONFIRMADA" : "RECHAZADA"}.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar la cita.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentBarberId == null) {
      // Si por alguna razón el UID es nulo, forzamos el logout.
      return const Center(child: Text('Error de usuario.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Barbero'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _buildAppointmentList(),
    );
  }

  Widget _buildAppointmentList() {
    return StreamBuilder<List<AppointmentModel>>(
      // Usamos el Stream para obtener las citas en tiempo real
      stream: _dbService.getBarberAppointments(_currentBarberId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar las citas: ${snapshot.error}'));
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return const Center(
            child: Text(
              '🎉 ¡No tienes citas pendientes ni confirmadas hoy!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Muestra las citas
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return _buildAppointmentCard(appointment);
          },
        );
      },
    );
  }

  // Widget para mostrar una cita individual
  Widget _buildAppointmentCard(AppointmentModel appointment) {
    // Formatear la fecha para una mejor visualización
    final dateString = MaterialLocalizations.of(context).formatShortDate(appointment.date);
    final isPending = appointment.status == AppointmentStatus.pending;

    Color statusColor;
    String statusText;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = Colors.green.shade100;
        statusText = 'CONFIRMADA';
        break;
      case AppointmentStatus.rejected:
        statusColor = Colors.red.shade100;
        statusText = 'RECHAZADA';
        break;
      case AppointmentStatus.pending:
      default:
        statusColor = Colors.yellow.shade100;
        statusText = 'PENDIENTE';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      elevation: 3,
      color: statusColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPending ? Colors.yellow.shade800 : Colors.teal,
          child: Text(appointment.time.substring(0, 2), style: const TextStyle(color: Colors.white)),
        ),
        title: Text(
          '${appointment.clientName} - ${appointment.service}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Día: $dateString, Hora: ${appointment.time}\nEstado: $statusText'),
        isThreeLine: true,
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón Confirmar
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _handleStatusUpdate(appointment, AppointmentStatus.confirmed),
                    tooltip: 'Confirmar',
                  ),
                  // Botón Rechazar
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _handleStatusUpdate(appointment, AppointmentStatus.rejected),
                    tooltip: 'Rechazar',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}