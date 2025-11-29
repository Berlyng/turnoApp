class BarberModel {
  final String id; 
  final String name;
  final String specialty;
  final String? photoUrl; // Usaremos este campo para la foto

  BarberModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.photoUrl,
  });

  // Crea un objeto BarberModel desde un documento de Firestore
  factory BarberModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BarberModel(
      id: id,
      name: data['name'] ?? 'Barbero sin nombre',
      specialty: data['specialty'] ?? 'General',
      photoUrl: data['photoUrl'],
    );
  }

  // Método para convertir el modelo a un mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'photoUrl': photoUrl,
      // Nota: 'id' no se incluye aquí, ya que se usa como ID del documento en Firestore.
    };
  }
}