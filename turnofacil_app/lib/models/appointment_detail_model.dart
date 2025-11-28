import 'appointment_model.dart';
import 'barber_model.dart';

// Este modelo combina la información de la cita con el nombre del barbero
class AppointmentDetailModel {
  final AppointmentModel appointment;
  final String barberName; // Nombre real del barbero

  AppointmentDetailModel({
    required this.appointment,
    required this.barberName,
  });
}