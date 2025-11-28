import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/barber_model.dart';
import '../../services/database_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final DatabaseService _dbService = DatabaseService();
  BarberModel? _selectedBarber;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Mañana
  String? _selectedTime;
  final List<String> _availableServices = ['Corte de Cabello', 'Afeitado', 'Diseño de Barba'];
  String? _selectedService;
  List<String> _occupiedTimes = [];
  bool _isLoadingTimes = false;
  
  // Horarios disponibles (puedes ajustar esto a tu lógica de negocio)
  final List<String> _times = ["09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00"];

  @override
  void initState() {
    super.initState();
    _selectedService = _availableServices.first;
    // La primera vez, no consultamos horas porque no hay barbero seleccionado.
  }

  // Consulta las horas ocupadas para el barbero y la fecha seleccionados
  void _fetchOccupiedTimes() async {
    if (_selectedBarber == null) return;
    
    setState(() {
      _isLoadingTimes = true;
      _selectedTime = null; // Resetea la hora seleccionada
    });

    final occupied = await _dbService.getOccupiedTimes(
      barberId: _selectedBarber!.id,
      date: _selectedDate,
    );
    
    setState(() {
      _occupiedTimes = occupied;
      _isLoadingTimes = false;
    });
  }

  // Muestra el selector de fecha
  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)), // A partir de mañana
      lastDate: DateTime.now().add(const Duration(days: 30)), // Máximo 30 días
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _fetchOccupiedTimes(); // Recalcula las horas disponibles con la nueva fecha
    }
  }

  // Lógica para crear la cita
  void _bookAppointment() async {
    if (_selectedBarber == null || _selectedTime == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona barbero, servicio y hora.')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Supongamos que tienes el nombre del cliente guardado en algún lado
    // Por simplicidad, usaremos el email como nombre:
    final clientName = currentUser.email ?? 'Cliente Anónimo';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar un Turno'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sección 1: Seleccionar Barbero
            const Text('1. Selecciona tu Barbero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildBarberSelector(),
            const SizedBox(height: 30),

            // Sección 2: Seleccionar Servicio
            const Text('2. Selecciona el Servicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildServiceSelector(),
            const SizedBox(height: 30),

            // Sección 3: Seleccionar Fecha
            const Text('3. Selecciona la Fecha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildDateSelector(),
            const SizedBox(height: 30),
            
            // Sección 4: Seleccionar Hora (solo si hay barbero seleccionado)
            if (_selectedBarber != null) ...[
              const Text('4. Selecciona la Hora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTimeGrid(),
              const SizedBox(height: 40),
            ],

            // Botón Final de Reserva
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedBarber != null && _selectedTime != null) 
                    ? _bookAppointment 
                    : null, // Deshabilita el botón si falta información
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Confirmar Reserva', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para seleccionar el Barbero
  Widget _buildBarberSelector() {
    return StreamBuilder<List<BarberModel>>(
      stream: _dbService.getBarbers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final barbers = snapshot.data!;
        
        // Si no hay barbero seleccionado, seleccionamos el primero por defecto
        if (_selectedBarber == null && barbers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedBarber = barbers.first;
            });
            _fetchOccupiedTimes();
          });
        }

        if (barbers.isEmpty) {
          return const Text('No hay barberos disponibles en este momento.');
        }

        return DropdownButtonFormField<BarberModel>(
          value: _selectedBarber,
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
            _fetchOccupiedTimes(); // Cargar horas para el nuevo barbero
          },
        );
      },
    );
  }

  // Widget para seleccionar el Servicio
  Widget _buildServiceSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedService,
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
            'Fecha: ${MaterialLocalizations.of(context).formatShortDate(_selectedDate)}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        TextButton.icon(
          onPressed: _presentDatePicker,
          icon: const Icon(Icons.edit, color: Colors.indigo),
          label: const Text('Cambiar', style: TextStyle(color: Colors.indigo)),
        ),
      ],
    );
  }

  // Widget para la cuadrícula de horas
  Widget _buildTimeGrid() {
    if (_isLoadingTimes) {
      return const Center(child: CircularProgressIndicator());
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _times.map((time) {
        final isBooked = _occupiedTimes.contains(time);
        
        return ChoiceChip(
          label: Text(time),
          selected: _selectedTime == time,
          selectedColor: Colors.indigo.shade200,
          disabledColor: Colors.grey.shade300,
          backgroundColor: isBooked ? Colors.red.shade100 : Colors.grey.shade100,
          labelStyle: TextStyle(
            color: isBooked ? Colors.red.shade800 : (_selectedTime == time ? Colors.indigo.shade900 : Colors.black),
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
}