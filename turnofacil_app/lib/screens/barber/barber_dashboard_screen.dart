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

class _BarberDashboardScreenState extends State<BarberDashboardScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final String? _currentBarberId = FirebaseAuth.instance.currentUser?.uid;

  // Estado para el filtro: null significa "Todas"
  AppointmentStatus? _selectedFilterStatus = AppointmentStatus.pending; 

  // Lista de opciones de filtro para el Dropdown
  final List<Map<String, dynamic>> _filterOptions = [
    {'status': null, 'label': 'Todas las Citas', 'icon': Icons.list_alt},
    {'status': AppointmentStatus.pending, 'label': 'Pendientes', 'icon': Icons.schedule},
    {'status': AppointmentStatus.confirmed, 'label': 'Confirmadas', 'icon': Icons.check_circle},
    {'status': AppointmentStatus.rejected, 'label': 'Rechazadas', 'icon': Icons.cancel},
  ];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Podemos iniciar con las citas pendientes si es el flujo más común
    _selectedFilterStatus = AppointmentStatus.pending;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  // Lógica para manejar la acción del barbero (Confirmar/Rechazar)
  void _handleStatusUpdate(AppointmentModel appointment, AppointmentStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              status == AppointmentStatus.confirmed ? Icons.check_circle : Icons.cancel,
              color: status == AppointmentStatus.confirmed ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Text(status == AppointmentStatus.confirmed ? 'Confirmar Cita' : 'Rechazar Cita'),
          ],
        ),
        content: Text(
          '¿Deseas ${status == AppointmentStatus.confirmed ? "confirmar" : "rechazar"} la cita de ${appointment.clientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == AppointmentStatus.confirmed ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(status == AppointmentStatus.confirmed ? 'Confirmar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.updateAppointmentStatus(
          appointmentId: appointment.id,
          newStatus: status,
        );
        // Mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    status == AppointmentStatus.confirmed ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cita de ${appointment.clientName} ha sido ${status == AppointmentStatus.confirmed ? "CONFIRMADA" : "RECHAZADA"}.',
                    ),
                  ),
                ],
              ),
              backgroundColor: status == AppointmentStatus.confirmed ? Colors.green.shade600 : Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Error al actualizar la cita.')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentBarberId == null) {
      // Manejo visual de error cuando no hay usuario
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.red.shade50, Colors.white],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error de Usuario',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo verificar tu sesión.\nVuelve a iniciar sesión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar Sesión'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final userDisplayName = currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Barbero';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.content_cut, size: 24),
            SizedBox(width: 12),
            Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4, // Añadir elevación para un efecto más pulido
        actions: [
          // Mostrar nombre o correo del usuario actual
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    userDisplayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // ---------------------------------
            // Nuevo: Selector de Filtro de Estado (Diseño Mejorado)
            // ---------------------------------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppointmentStatus?>(
                  value: _selectedFilterStatus,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).primaryColor, size: 28),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  hint: Row(
                    children: [
                      Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text('Filtrar citas...'),
                    ],
                  ),
                  items: _filterOptions.map((option) {
                    return DropdownMenuItem<AppointmentStatus?>(
                      value: option['status'] as AppointmentStatus?,
                      child: Row(
                        children: [
                          Icon(option['icon'] as IconData, size: 20, color: option['status'] == AppointmentStatus.pending ? Colors.orange.shade700 : option['status'] == AppointmentStatus.confirmed ? Colors.green.shade700 : option['status'] == AppointmentStatus.rejected ? Colors.red.shade700 : Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          Text(option['label'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (AppointmentStatus? newValue) {
                    setState(() {
                      _selectedFilterStatus = newValue;
                      // Reiniciar animación al cambiar filtro
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                ),
              ),
            ),
            // ---------------------------------
            
            Expanded(
              child: _buildAppointmentList(),
            ),
          ],
        ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando citas...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print("Dashboard Error: ${snapshot.error}");
          // Manejo visual de errores al cargar citas
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error al cargar las citas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {}); // Reintentar carga
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final appointments = snapshot.data ?? [];
        final filterLabel = _filterOptions.firstWhere(
            (opt) => opt['status'] == _selectedFilterStatus)['label'] as String;

        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '🎉 Sin citas en "$filterLabel"',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay citas que mostrar en este momento.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Muestra las citas
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildAppointmentCard(appointments[index]),
            );
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
    Color accentColor;
    String statusText;
    IconData statusIcon;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = Colors.green.shade50;
        accentColor = Colors.green.shade700;
        statusText = 'CONFIRMADA';
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.rejected:
        statusColor = Colors.red.shade50;
        accentColor = Colors.red.shade700;
        statusText = 'RECHAZADA';
        statusIcon = Icons.cancel;
        break;
      case AppointmentStatus.pending:
      default:
        statusColor = Colors.orange.shade50;
        accentColor = Colors.orange.shade700;
        statusText = 'PENDIENTE';
        statusIcon = Icons.schedule;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con hora y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        appointment.time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nombre del cliente
            Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Servicio
            Row(
              children: [
                Icon(Icons.cut, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.service,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Fecha
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  dateString,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            
            // Botones de acción solo para citas pendientes
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleStatusUpdate(appointment, AppointmentStatus.confirmed),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleStatusUpdate(appointment, AppointmentStatus.rejected),
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}