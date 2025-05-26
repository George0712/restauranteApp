// Modelo de Mesa mejorado
class MesaModel {
  final int id;
  final String estado; 
  final int capacidad;
  final String? cliente;
  final String? tiempo;
  final double? total;
  final String? pedidoId;
  final DateTime? fechaReserva;
  final DateTime? horaOcupacion;

  MesaModel({
    required this.id,
    required this.estado,
    required this.capacidad,
    this.cliente,
    this.tiempo,
    this.total,
    this.pedidoId,
    this.fechaReserva,
    this.horaOcupacion,
  });

  MesaModel copyWith({
    int? id,
    String? estado,
    int? capacidad,
    String? cliente,
    String? tiempo,
    double? total,
    String? pedidoId,
    DateTime? fechaReserva,
    DateTime? horaOcupacion,
  }) {
    return MesaModel(
      id: id ?? this.id,
      estado: estado ?? this.estado,
      capacidad: capacidad ?? this.capacidad,
      cliente: cliente ?? this.cliente,
      tiempo: tiempo ?? this.tiempo,
      total: total ?? this.total,
      pedidoId: pedidoId ?? this.pedidoId,
      fechaReserva: fechaReserva ?? this.fechaReserva,
      horaOcupacion: horaOcupacion ?? this.horaOcupacion,
    );
  }

  String get tiempoTranscurrido {
    if (horaOcupacion == null) return '00:00';
    final duracion = DateTime.now().difference(horaOcupacion!);
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }
}