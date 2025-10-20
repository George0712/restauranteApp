import 'package:cloud_firestore/cloud_firestore.dart';

class Incidencia {
  final String? id;
  final String tipo; // cocina, administracion, tecnica, otra
  final String categoria; // urgente, normal, baja
  final String asunto;
  final String descripcion;
  final String meseroId;
  final String meseroNombre;
  final String? mesaId;
  final String? mesaNombre;
  final String? pedidoId;
  final String estado; // pendiente, en_revision, resuelta, cerrada
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolucion;
  final String? resolvidaPorId;
  final String? resolvidaPorNombre;

  Incidencia({
    this.id,
    required this.tipo,
    required this.categoria,
    required this.asunto,
    required this.descripcion,
    required this.meseroId,
    required this.meseroNombre,
    this.mesaId,
    this.mesaNombre,
    this.pedidoId,
    this.estado = 'pendiente',
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolucion,
    this.resolvidaPorId,
    this.resolvidaPorNombre,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Incidencia(
      id: docId ?? json['id'],
      tipo: json['tipo'] ?? 'otra',
      categoria: json['categoria'] ?? 'normal',
      asunto: json['asunto'] ?? '',
      descripcion: json['descripcion'] ?? '',
      meseroId: json['meseroId'] ?? '',
      meseroNombre: json['meseroNombre'] ?? '',
      mesaId: json['mesaId'],
      mesaNombre: json['mesaNombre'],
      pedidoId: json['pedidoId'],
      estado: json['estado'] ?? 'pendiente',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (json['resolvedAt'] as Timestamp?)?.toDate(),
      resolucion: json['resolucion'],
      resolvidaPorId: json['resolvidaPorId'],
      resolvidaPorNombre: json['resolvidaPorNombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tipo': tipo,
      'categoria': categoria,
      'asunto': asunto,
      'descripcion': descripcion,
      'meseroId': meseroId,
      'meseroNombre': meseroNombre,
      if (mesaId != null) 'mesaId': mesaId,
      if (mesaNombre != null) 'mesaNombre': mesaNombre,
      if (pedidoId != null) 'pedidoId': pedidoId,
      'estado': estado,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (resolucion != null) 'resolucion': resolucion,
      if (resolvidaPorId != null) 'resolvidaPorId': resolvidaPorId,
      if (resolvidaPorNombre != null) 'resolvidaPorNombre': resolvidaPorNombre,
    };
  }

  Incidencia copyWith({
    String? id,
    String? tipo,
    String? categoria,
    String? asunto,
    String? descripcion,
    String? meseroId,
    String? meseroNombre,
    String? mesaId,
    String? mesaNombre,
    String? pedidoId,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolucion,
    String? resolvidaPorId,
    String? resolvidaPorNombre,
  }) {
    return Incidencia(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      asunto: asunto ?? this.asunto,
      descripcion: descripcion ?? this.descripcion,
      meseroId: meseroId ?? this.meseroId,
      meseroNombre: meseroNombre ?? this.meseroNombre,
      mesaId: mesaId ?? this.mesaId,
      mesaNombre: mesaNombre ?? this.mesaNombre,
      pedidoId: pedidoId ?? this.pedidoId,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolucion: resolucion ?? this.resolucion,
      resolvidaPorId: resolvidaPorId ?? this.resolvidaPorId,
      resolvidaPorNombre: resolvidaPorNombre ?? this.resolvidaPorNombre,
    );
  }
}
