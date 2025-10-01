// Modelo de Mesa mejorado
class MesaModel {
  final String? docId; // ID del documento en Firestore
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
    this.docId,
    this.cliente,
    this.tiempo,
    this.total,
    this.pedidoId,
    this.fechaReserva,
    this.horaOcupacion,
  });

  static const _undefined = Object();

  MesaModel copyWith({
    String? docId,
    int? id,
    String? estado,
    int? capacidad,
    Object? cliente = _undefined,
    Object? tiempo = _undefined,
    Object? total = _undefined,
    Object? pedidoId = _undefined,
    Object? fechaReserva = _undefined,
    Object? horaOcupacion = _undefined,
  }) {
    return MesaModel(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      estado: estado ?? this.estado,
      capacidad: capacidad ?? this.capacidad,
      cliente: cliente == _undefined ? this.cliente : cliente as String?,
      tiempo: tiempo == _undefined ? this.tiempo : tiempo as String?,
      total: total == _undefined ? this.total : total as double?,
      pedidoId: pedidoId == _undefined ? this.pedidoId : pedidoId as String?,
      fechaReserva: fechaReserva == _undefined
          ? this.fechaReserva
          : fechaReserva as DateTime?,
      horaOcupacion: horaOcupacion == _undefined
          ? this.horaOcupacion
          : horaOcupacion as DateTime?,
    );
  }

  String get tiempoTranscurrido {
    if (horaOcupacion == null) return '00:00';
    final duracion = DateTime.now().difference(horaOcupacion!);
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }

  // Método para convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'id': id,
      'estado': estado,
      'capacidad': capacidad,
      'cliente': cliente,
      'tiempo': tiempo,
      'total': total,
      'pedidoId': pedidoId,
      'fechaReserva': fechaReserva?.toIso8601String(),
      'horaOcupacion': horaOcupacion?.toIso8601String(),
    };
  }

  // Método para crear desde Map de Firestore
  factory MesaModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MesaModel(
      docId: documentId,
      id: map['id'] ?? 0,
      estado: map['estado'] ?? 'disponible',
      capacidad: map['capacidad'] ?? 0,
      cliente: map['cliente'],
      tiempo: map['tiempo'],
      total: map['total']?.toDouble(),
      pedidoId: map['pedidoId'],
      fechaReserva: map['fechaReserva'] != null
          ? DateTime.parse(map['fechaReserva'])
          : null,
      horaOcupacion: map['horaOcupacion'] != null
          ? DateTime.parse(map['horaOcupacion'])
          : null,
    );
  }
}
