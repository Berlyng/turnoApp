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

  // Estado para el filtro: null significa "Todas"
  AppointmentStatus? _selectedFilterStatus = AppointmentStatus.pending; 

  // Lista de opciones de filtro para el Dropdown
  final List<Map<String, dynamic>> _filterOptions = [
    {'status': null, 'label': 'Todas las Citas'},
    {'status': AppointmentStatus.pending, 'label': 'Pendientes'},
    {'status': AppointmentStatus.confirmed, 'label': 'Confirmadas'},
    {'status': AppointmentStatus.rejected, 'label': 'Rechazadas'},
  ];

  @override
  void initState() {
    super.initState();
    // Podemos iniciar con las citas pendientes si es el flujo más común
    _selectedFilterStatus = AppointmentStatus.pending; 
  }

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
      return const Center(child: Text('Error de usuario. Vuelve a iniciar sesión.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Barbero'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------------------------------
          // Nuevo: Selector de Filtro de Estado
          // ---------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: DropdownButtonFormField<AppointmentStatus?>(
              value: _selectedFilterStatus,
              decoration: InputDecoration(
                labelText: 'Filtrar por Estado',
                prefixIcon: const Icon(Icons.filter_list),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _filterOptions.map((option) {
                return DropdownMenuItem<AppointmentStatus?>(
                  value: option['status'] as AppointmentStatus?,
                  child: Text(option['label'] as String),
                );
              }).toList(),
              onChanged: (AppointmentStatus? newValue) {
                setState(() {
                  _selectedFilterStatus = newValue;
                });
              },
            ),
          ),
          // ---------------------------------
          
          Expanded(
            child: _buildAppointmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList() {
    return StreamBuilder<List<AppointmentModel>>(
      // CAMBIO CLAVE: Pasamos el filtro al método de servicio
      stream: _dbService.getBarberAppointments(
        _currentBarberId!, 
        filterStatus: _selectedFilterStatus
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Dashboard Error: ${snapshot.error}");
          return Center(child: Text('Error al cargar las citas: ${snapshot.error}'));
        }

        final appointments = snapshot.data ?? [];
        final filterLabel = _filterOptions.firstWhere(
            (opt) => opt['status'] == _selectedFilterStatus)['label'] as String;

        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '🎉 No hay citas en estado "$filterLabel".',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
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
      elevation: 4,
      color: statusColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          backgroundColor: isPending ? Colors.yellow.shade800 : Colors.teal.shade700,
          radius: 25,
          child: Text(appointment.time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        title: Text(
          'Cliente: ${appointment.clientName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Servicio: ${appointment.service}\n'
          'Día: $dateString | Estado: $statusText',
        ),
        isThreeLine: true,
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón Confirmar
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    onPressed: () => _handleStatusUpdate(appointment, AppointmentStatus.confirmed),
                    tooltip: 'Confirmar',
                  ),
                  // Botón Rechazar
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
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