import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TurnoModel {
  final String id;
  final String userId;
  final DateTime horaInicio;
  final DateTime horaFinProgramada;
  final DateTime? horaFin;
  final bool activo;
  final String? userName;

  const TurnoModel({
    required this.id,
    required this.userId,
    required this.horaInicio,
    required this.horaFinProgramada,
    this.horaFin,
    required this.activo,
    this.userName,
  });

  // Duración del turno
  Duration get duracion {
    final fin = horaFin ?? horaFinProgramada;
    return fin.difference(horaInicio);
  }

  // Tiempo restante del turno
  Duration? get tiempoRestante {
    if (!activo || horaFin != null) return null;

    try {
      tz.initializeTimeZones();
      final colombia = tz.getLocation('America/Bogota');
      final ahora = tz.TZDateTime.now(colombia);

      if (ahora.isAfter(horaFinProgramada)) return Duration.zero;
      return horaFinProgramada.difference(ahora);
    } catch (e) {
      // Fallback a hora local si hay error
      final ahora = DateTime.now();
      if (ahora.isAfter(horaFinProgramada)) return Duration.zero;
      return horaFinProgramada.difference(ahora);
    }
  }

  // Verificar si el turno ha expirado
  bool get haExpirado {
    if (!activo || horaFin != null) return false;

    try {
      tz.initializeTimeZones();
      final colombia = tz.getLocation('America/Bogota');
      final ahora = tz.TZDateTime.now(colombia);
      return ahora.isAfter(horaFinProgramada);
    } catch (e) {
      // Fallback a hora local si hay error
      return DateTime.now().isAfter(horaFinProgramada);
    }
  }

  factory TurnoModel.fromMap(Map<String, dynamic> data, String id) {
    return TurnoModel(
      id: id,
      userId: data['userId'] ?? '',
      horaInicio: _parseDateTime(data['horaInicio']) ?? DateTime.now(),
      horaFinProgramada: _parseDateTime(data['horaFinProgramada']) ?? DateTime.now(),
      horaFin: _parseDateTime(data['horaFin']),
      activo: data['activo'] ?? false,
      userName: data['userName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'horaInicio': Timestamp.fromDate(horaInicio),
      'horaFinProgramada': Timestamp.fromDate(horaFinProgramada),
      'horaFin': horaFin != null ? Timestamp.fromDate(horaFin!) : null,
      'activo': activo,
      'userName': userName,
    };
  }

  TurnoModel copyWith({
    String? id,
    String? userId,
    DateTime? horaInicio,
    DateTime? horaFinProgramada,
    DateTime? horaFin,
    bool? activo,
    String? userName,
  }) {
    return TurnoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFinProgramada: horaFinProgramada ?? this.horaFinProgramada,
      horaFin: horaFin ?? this.horaFin,
      activo: activo ?? this.activo,
      userName: userName ?? this.userName,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
