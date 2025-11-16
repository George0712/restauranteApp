import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/turno_model.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Provider para el usuario actual
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider para obtener el rol del usuario actual
final userRoleProvider = StreamProvider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }

      return FirebaseFirestore.instance
          .collection('usuario')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data();
        return data?['rol']?.toString().toLowerCase();
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider para obtener el turno activo del usuario actual
final turnoActivoProvider = StreamProvider<TurnoModel?>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }

      return FirebaseFirestore.instance
          .collection('turnos')
          .where('userId', isEqualTo: user.uid)
          .where('activo', isEqualTo: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        return TurnoModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Clase para gestionar turnos
class TurnoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _expirationTimer;

  TurnoController() {
    // Inicializar zonas horarias
    tz.initializeTimeZones();
  }

  /// Obtener hora actual de Colombia (UTC-5)
  DateTime _getColombiaTime() {
    final colombia = tz.getLocation('America/Bogota');
    return tz.TZDateTime.now(colombia);
  }

  /// Convertir a hora de Colombia
  DateTime _toColombiaTime(DateTime dateTime) {
    final colombia = tz.getLocation('America/Bogota');
    return tz.TZDateTime.from(dateTime, colombia);
  }

  /// Calcula la hora de fin del turno según el día de la semana
  DateTime calcularHoraFinTurno(DateTime horaInicio) {
    // Asegurarse de usar hora de Colombia
    final horaInicioColombia = _toColombiaTime(horaInicio);
    final diaSemana = horaInicioColombia.weekday;

    // Obtener la fecha del día en Colombia
    final fecha = DateTime(
      horaInicioColombia.year,
      horaInicioColombia.month,
      horaInicioColombia.day,
    );

    switch (diaSemana) {
      case DateTime.monday:
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
      case DateTime.friday:
        // Días de semana: 8 horas o hasta 12am (medianoche)
        final horaFin8Horas = horaInicioColombia.add(const Duration(hours: 8));
        final medianoche = fecha.add(const Duration(days: 1)); // 12:00 AM del día siguiente

        // Si 8 horas después es antes de medianoche, usar 8 horas
        // Si no, usar medianoche
        return horaFin8Horas.isBefore(medianoche) ? horaFin8Horas : medianoche;

      case DateTime.saturday:
        // Sábados: hasta las 2am del domingo
        return fecha.add(const Duration(days: 1, hours: 2)); // 2:00 AM del domingo

      case DateTime.sunday:
        // Domingos: hasta las 12am (medianoche)
        return fecha.add(const Duration(days: 1)); // 12:00 AM del lunes

      default:
        // Por defecto: 8 horas
        return horaInicioColombia.add(const Duration(hours: 8));
    }
  }

  /// Iniciar turno
  Future<void> iniciarTurno() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        SnackbarHelper.showError('Usuario no autenticado');
        return;
      }

      // Verificar si ya tiene un turno activo
      final turnoActivoQuery = await _firestore
          .collection('turnos')
          .where('userId', isEqualTo: user.uid)
          .where('activo', isEqualTo: true)
          .get();

      if (turnoActivoQuery.docs.isNotEmpty) {
        SnackbarHelper.showWarning('Ya tienes un turno activo');
        return;
      }

      // Usar hora de Colombia
      final horaInicio = _getColombiaTime();
      final horaFinProgramada = calcularHoraFinTurno(horaInicio);

      // Obtener nombre del usuario desde su documento
      String? userName;
      try {
        final userDoc = await _firestore.collection('usuario').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['nombre'] ?? userData?['name'] ?? user.displayName;
        }
      } catch (_) {
        userName = user.displayName;
      }

      final turno = TurnoModel(
        id: '',
        userId: user.uid,
        horaInicio: horaInicio,
        horaFinProgramada: horaFinProgramada,
        activo: true,
        userName: userName,
      );

      await _firestore.collection('turnos').add(turno.toMap());

      // Programar desactivación automática
      _programarDesactivacionAutomatica(horaFinProgramada, user.uid);

      SnackbarHelper.showSuccess('Turno iniciado');
    } catch (e) {
      SnackbarHelper.showError('Error al iniciar turno: $e');
    }
  }

  /// Programar desactivación automática del turno
  void _programarDesactivacionAutomatica(DateTime horaFin, String userId) {
    final ahora = DateTime.now();
    final duracion = horaFin.difference(ahora);

    if (duracion.isNegative) return;

    _expirationTimer?.cancel();
    _expirationTimer = Timer(duracion, () {
      _desactivarTurnoAutomaticamente(userId);
    });
  }

  /// Desactivar turno automáticamente
  Future<void> _desactivarTurnoAutomaticamente(String userId) async {
    try {
      final turnosActivos = await _firestore
          .collection('turnos')
          .where('userId', isEqualTo: userId)
          .where('activo', isEqualTo: true)
          .get();

      final horaActual = _getColombiaTime();

      for (final doc in turnosActivos.docs) {
        await doc.reference.update({
          'activo': false,
          'horaFin': Timestamp.fromDate(horaActual),
        });
      }
    } catch (e) {
      SnackbarHelper.showError('Error al desactivar turno automáticamente: $e');
    }
  }

  /// Finalizar turno manualmente (solo si ha pasado el tiempo programado)
  Future<void> finalizarTurno(String turnoId) async {
    try {
      final turnoDoc = await _firestore.collection('turnos').doc(turnoId).get();

      if (!turnoDoc.exists) {
        SnackbarHelper.showError('Turno no encontrado');
        return;
      }

      final turno = TurnoModel.fromMap(turnoDoc.data()!, turnoDoc.id);

      // Verificar si el turno ha expirado
      if (!turno.haExpirado) {
        SnackbarHelper.showWarning(
          'No puedes finalizar el turno antes de tiempo',
        );
        return;
      }

      final horaActual = _getColombiaTime();

      await turnoDoc.reference.update({
        'activo': false,
        'horaFin': Timestamp.fromDate(horaActual),
      });

      SnackbarHelper.showSuccess('Turno finalizado');
    } catch (e) {
      SnackbarHelper.showError('Error al finalizar turno: $e');
    }
  }

  /// Verificar y desactivar turnos expirados periódicamente
  Future<void> verificarTurnosExpirados() async {
    try {
      final ahora = _getColombiaTime();
      final turnosActivos = await _firestore
          .collection('turnos')
          .where('activo', isEqualTo: true)
          .get();

      for (final doc in turnosActivos.docs) {
        final turno = TurnoModel.fromMap(doc.data(), doc.id);

        if (turno.haExpirado) {
          await doc.reference.update({
            'activo': false,
            'horaFin': Timestamp.fromDate(ahora),
          });
        }
      }
    } catch (e) {
      SnackbarHelper.showError('Error al verificar turnos expirados: $e');
    }
  }

  void dispose() {
    _expirationTimer?.cancel();
  }
}

/// Provider para el controlador de turnos
final turnoControllerProvider = Provider<TurnoController>((ref) {
  final controller = TurnoController();

  ref.onDispose(() {
    controller.dispose();
  });

  // Verificar turnos expirados cada minuto
  Timer.periodic(const Duration(minutes: 1), (_) {
    controller.verificarTurnosExpirados();
  });

  return controller;
});
