import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:turnofacil_app/models/appointment_detail_model.dart';
import '../models/barber_model.dart';
import '../models/appointment_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------
  // CLIENTE: GESTIÓN DE BARBEROS
  // -------------------------

  // Obtiene la lista de todos los barberos (usuarios con rol 'barbero')
  Stream<List<BarberModel>> getBarbers() {
    // Escuchamos la colección 'usuarios' donde el rol es 'barbero'
    return _firestore
        .collection('usuarios')
        .where('role', isEqualTo: 'barbero')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Mapeamos el documento a nuestro BarberModel
        return BarberModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // -------------------------
  // CLIENTE: CREACIÓN DE CITA
  // -------------------------

  Future<void> createAppointment({
    required String clientId,
    required String clientName,
    required String barberId,
    required String service,
    required DateTime date,
    required String time,
  }) async {
    final newAppointment = AppointmentModel(
      id: '', // Firestore asigna el ID automáticamente
      clientId: clientId,
      clientName: clientName,
      barberId: barberId,
      service: service,
      date: date,
      time: time,
      status: AppointmentStatus.pending,
    );

    await _firestore.collection('citas').add(newAppointment.toMap());
  }

  // -------------------------
  // LÓGICA DE VALIDACIÓN (Barbero)
  // -------------------------
  
  // Obtiene las citas ocupadas para un barbero en una fecha específica
  Future<List<String>> getOccupiedTimes({
    required String barberId,
    required DateTime date,
  }) async {
    // Creamos un rango de búsqueda para todo el día
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('citas')
        .where('barberId', isEqualTo: barberId)
        // Buscamos todas las citas en ese rango de tiempo (todo el día)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        // Excluimos las citas que fueron rechazadas
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    // Devolvemos solo la lista de horas ocupadas (ej. ["10:00", "11:30"]).
    // 💡 MEJORA DE ROBUSTEZ: Se utiliza 'doc.data()?['time'] as String?' para manejar nulos
    // y se usa whereType<String>() para filtrar cualquier valor que no sea String,
    // garantizando que la lista final sea de tipo List<String>.
    return snapshot.docs
        .map((doc) => doc.data().containsKey('time') ? doc.get('time') as String? : null)
        .whereType<String>() 
        .toList();
  }

 // -------------------------
  // BARBERO: GESTIÓN DE CITAS CON FILTRO
  // -------------------------

  // Obtiene las citas para el Barbero actualmente logeado, con un filtro de estado opcional.
    Stream<List<AppointmentModel>> getBarberAppointments(
    String barberId, {
    AppointmentStatus? filterStatus, // Nuevo parámetro opcional
  }) {
    Query query = _firestore
        .collection('citas')
        .where('barberId', isEqualTo: barberId);

    // Si se proporciona un filtro de estado, se añade la cláusula where
    if (filterStatus != null) {
      final statusString = filterStatus.toString().split('.').last;
      query = query.where('status', isEqualTo: statusString);
    }
    
    query = query
        .orderBy('date', descending: false)
        .orderBy('time', descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // CORRECCIÓN CLAVE: Casting explícito
        return AppointmentModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 2. Método para actualizar el estado de una cita
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required AppointmentStatus newStatus,
  }) async {
    // Referencia al documento específico de la cita
    DocumentReference appointmentRef = _firestore.collection('citas').doc(appointmentId);

    // Actualizamos solo el campo 'status'
    await appointmentRef.update({
      'status': newStatus.toString().split('.').last, // Ej: "confirmed"
    });
  }

  // -------------------------
  // CLIENTE: OBTENER MIS CITAS
  // -------------------------

  // Obtiene todas las citas reservadas por un cliente específico
  Stream<List<AppointmentModel>> getClientAppointments(String clientId) {
    // Escuchamos la colección 'citas' donde el clientId coincide con el usuario actual
    return _firestore
        .collection('citas')
        .where('clientId', isEqualTo: clientId)
        // Ordenamos por fecha y hora para una vista cronológica
        .orderBy('date', descending: true) // Las más recientes primero
        .orderBy('time', descending: true) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Mapeamos el documento a nuestro AppointmentModel
        return AppointmentModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // -------------------------
  // CONSULTA AVANZADA: Citas con Nombre del Barbero
  // -------------------------

  Stream<List<AppointmentDetailModel>> getClientAppointmentsWithBarberName(String clientId) {
    // 1. Obtenemos el Stream de todas las citas del cliente
    final appointmentsStream = getClientAppointments(clientId);

    // 2. Transformamos el Stream de citas
    return appointmentsStream.switchMap((appointments) {
      if (appointments.isEmpty) {
        return Stream.value([]); // Retornamos un Stream vacío si no hay citas
      }

      // 3. Obtenemos los IDs únicos de los barberos de la lista de citas
      final uniqueBarberIds = appointments.map((a) => a.barberId).toSet().toList();

      // 4. Creamos una lista de futuros (Future) que buscarán los documentos de los barberos
      final barberFutures = uniqueBarberIds.map((barberId) {
        return _firestore.collection('usuarios').doc(barberId).get();
      }).toList();

      // 5. Esperamos a que todos los documentos de barberos se resuelvan
      return Future.wait(barberFutures).asStream().map((barberDocs) {
        
        // Mapeamos los documentos de barberos a un Map para búsqueda rápida (ID -> Nombre)
        final Map<String, String> barberNames = {};
        for (var doc in barberDocs) {
          if (doc.exists) {
            barberNames[doc.id] = doc.data()?['name'] ?? 'Barbero Desconocido';
          }
        }

        // 6. Finalmente, mapeamos las citas originales al modelo de detalle
        return appointments.map((appointment) {
          final name = barberNames[appointment.barberId] ?? 'Barbero Desconocido';
          return AppointmentDetailModel(
            appointment: appointment,
            barberName: name,
          );
        }).toList();
      });
    });
  }

  
}