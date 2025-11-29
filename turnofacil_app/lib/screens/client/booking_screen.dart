import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Asegúrate de que estas rutas son correctas
import '../../models/barber_model.dart';
import '../../services/database_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Inicialización del servicio de base de datos
  final DatabaseService _dbService = DatabaseService();
  
  // Variables de estado de la reserva
  BarberModel? _selectedBarber;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Fecha inicial: Mañana
  String? _selectedTime;
  final List<String> _availableServices = ['Corte de Cabello', 'Afeitado', 'Diseño de Barba'];
  String? _selectedService;
  
  // Variables de estado para la disponibilidad
  List<String> _occupiedTimes = [];
  bool _isLoadingTimes = false;
  
  // Horarios de trabajo fijos
  final List<String> _times = ["09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00"];

  @override
  void initState() {
    super.initState();
    // Inicializa el servicio seleccionado con el primero de la lista
    _selectedService = _availableServices.first;
  }

  // Consulta las horas ocupadas para el barbero y la fecha seleccionados
  void _fetchOccupiedTimes() async {
    if (_selectedBarber == null) return;
    
    // 1. Inicia el estado de carga y limpia la hora seleccionada
    setState(() {
      _isLoadingTimes = true;
      _selectedTime = null; 
    });

    try {
      // Obtiene los tiempos ocupados de manera segura (asumimos que DatabaseService 
      // devuelve una lista limpia de strings)
      final occupied = await _dbService.getOccupiedTimes(
        barberId: _selectedBarber!.id,
        date: _selectedDate,
      );
      
      // 2. Actualiza el estado solo si el widget sigue montado
      if (mounted) {
        setState(() {
          _occupiedTimes = occupied;
          _isLoadingTimes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Muestra un mensaje de error si la consulta falla
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar horas: $e')),
        );
        setState(() {
          _isLoadingTimes = false;
          _occupiedTimes = []; // Limpia las horas ocupadas para evitar errores
        });
      }
    }
  }

  // Muestra el selector de fecha y maneja el cambio
  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)), // Desde mañana
      lastDate: DateTime.now().add(const Duration(days: 90)), // Máximo 90 días
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      // Recalcula las horas disponibles con la nueva fecha
      if (_selectedBarber != null) {
        _fetchOccupiedTimes(); 
      }
    }
  }

  // Lógica principal para crear la cita
  void _bookAppointment() async {
    // Validación de campos obligatorios
    if (_selectedBarber == null || _selectedTime == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona barbero, servicio y hora.')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Debes iniciar sesión para reservar.')),
      );
      return;
    }

    final clientName = currentUser.email ?? 'Cliente Anónimo';

    try {
      await _dbService.createAppointment(
        clientId: currentUser.uid,
        clientName: clientName,
        barberId: _selectedBarber!.id,
        service: _selectedService!,
        date: _selectedDate,
        time: _selectedTime!,
      );

      // Mensaje de éxito y regreso a la pantalla anterior
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita reservada con éxito. Estado: Pendiente.')),
      );
      Navigator.of(context).pop();

    } on FirebaseException catch (e) {
      // Manejo de errores específicos de Firebase (e.g., permisos, duplicados)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de reserva: ${e.message}')),
      );
    } catch (e) {
      // Manejo de errores generales
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error inesperado: $e')),
      );
    }
  }

  // -----------------------------------------------------------
  // Widgets de Construcción
  // -----------------------------------------------------------

  // Widget para seleccionar el Barbero con StreamBuilder
  Widget _buildBarberSelector() {
    return StreamBuilder<List<BarberModel>>(
      stream: _dbService.getBarbers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final barbers = snapshot.data!;
        
        // Lógica de inicialización: Si no hay barbero seleccionado y la lista tiene datos, 
        // seleccionamos el primero y consultamos sus horarios.
        if (_selectedBarber == null && barbers.isNotEmpty) {
          // Usamos Future.microtask para garantizar que setState se llama después del build
          Future.microtask(() {
            setState(() {
              _selectedBarber = barbers.first;
            });
            _fetchOccupiedTimes();
          });
        }
        
        if (barbers.isEmpty) {
          return const Text('No hay barberos disponibles en este momento.');
        }

        // Aseguramos que el barbero seleccionado esté en la lista, si no, lo limpiamos
        if (_selectedBarber != null && !barbers.any((b) => b.id == _selectedBarber!.id)) {
            Future.microtask(() => setState(() => _selectedBarber = null));
        }

        return DropdownButtonFormField<BarberModel>(
          // Usamos el barbero seleccionado o null si ya no existe
          value: _selectedBarber != null && barbers.contains(_selectedBarber) ? _selectedBarber : null,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Barbero'),
          items: barbers.map((barber) {
            return DropdownMenuItem(
              value: barber,
              child: Text('${barber.name} (${barber.specialty})'),
            );
          }).toList(),
          onChanged: (BarberModel? newValue) {
            setState(() {
              _selectedBarber = newValue;
            });
            if (newValue != null) {
              _fetchOccupiedTimes(); // Cargar horas para el nuevo barbero
            } else {
              // Limpiar horas si se deselecciona el barbero (aunque el campo Dropdown no permite esto fácilmente)
              setState(() {
                _occupiedTimes = [];
                _selectedTime = null;
              });
            }
          },
        );
      },
    );
  }

  // Widget para seleccionar el Servicio
  Widget _buildServiceSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedService,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Servicio'),
      items: _availableServices.map((service) {
        return DropdownMenuItem(
          value: service,
          child: Text(service),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedService = newValue;
        });
      },
    );
  }

  // Widget para seleccionar la Fecha
  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Fecha: ${MaterialLocalizations.of(context).formatFullDate(_selectedDate)}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        TextButton.icon(
          onPressed: _presentDatePicker,
          icon: const Icon(Icons.calendar_today, color: Colors.indigo),
          label: const Text('Cambiar Fecha', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Widget para la cuadrícula de horas
  Widget _buildTimeGrid() {
    if (_isLoadingTimes) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Si no hay horas ocupadas, mostramos un mensaje por si acaso
    if (_occupiedTimes.length == _times.length) {
      return const Text('Todas las horas están reservadas para esta fecha.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _times.map((time) {
        final isBooked = _occupiedTimes.contains(time);
        final isSelected = _selectedTime == time;
        
        return ChoiceChip(
          label: Text(time),
          selected: isSelected,
          // Estilo y comportamiento basado en si está reservado
          selectedColor: Colors.indigo.shade200,
          backgroundColor: isBooked ? Colors.red.shade100 : Colors.indigo.shade50,
          labelStyle: TextStyle(
            color: isBooked ? Colors.red.shade800 : (isSelected ? Colors.indigo.shade900 : Colors.black87),
            fontWeight: isBooked ? FontWeight.bold : FontWeight.normal,
            decoration: isBooked ? TextDecoration.lineThrough : TextDecoration.none,
          ),
          onSelected: isBooked
              ? null // No se puede seleccionar si está reservado
              : (selected) {
                  setState(() {
                    _selectedTime = selected ? time : null;
                  });
                },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar un Turno'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sección 1: Seleccionar Barbero
            const Text('1. Selecciona tu Barbero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            _buildBarberSelector(),
            const SizedBox(height: 30),

            // Sección 2: Seleccionar Servicio
            const Text('2. Selecciona el Servicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            _buildServiceSelector(),
            const SizedBox(height: 30),

            // Sección 3: Seleccionar Fecha
            const Text('3. Selecciona la Fecha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            _buildDateSelector(),
            const SizedBox(height: 30),
            
            // Sección 4: Seleccionar Hora (solo si hay barbero seleccionado)
            if (_selectedBarber != null) ...[
              const Text('4. Selecciona la Hora Disponible', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 10),
              _buildTimeGrid(),
              const SizedBox(height: 40),
            ],

            // Botón Final de Reserva
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Deshabilita el botón si falta barbero o hora
                onPressed: (_selectedBarber != null && _selectedTime != null) 
                    ? _bookAppointment 
                    : null, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                child: const Text('Confirmar Reserva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}