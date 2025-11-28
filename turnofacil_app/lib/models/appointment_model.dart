// Usamos este enum para manejar el estado de la cita de forma clara
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { 
  pending, 
  confirmed, 
  rejected 
}

class AppointmentModel {
  final String id;
  final String clientId;
  final String clientName; // Para facilitar la vista del barbero
  final String barberId;
  final String service;
  final DateTime date;
  final String time; // Ej: "10:30"
  final AppointmentStatus status;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.barberId,
    required this.service,
    required this.date,
    required this.time,
    required this.status,
  });

  // Método para crear una cita desde Firestore (lectura)
  factory AppointmentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AppointmentModel(
      id: id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? 'Cliente desconocido',
      barberId: data['barberId'] ?? '',
      service: data['service'] ?? 'Corte',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '00:00',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
    );
  }

  // Método para convertir a Map (escritura a Firestore)
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'barberId': barberId,
      'service': service,
      'date': Timestamp.fromDate(date), // Guardamos la fecha como Timestamp
      'time': time,
      'status': status.toString().split('.').last, // Guardamos solo el nombre (ej. "pending")
    };
  }
}