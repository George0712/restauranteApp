import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/notification_model.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';

const int _maxNotificationsPerRole = 40;
const Duration _delayCheckInterval = Duration(minutes: 1);
const Duration _soundThrottle = Duration(seconds: 4);

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._ref) : super(NotificationState.initial()) {
    _pedidosSub = _ref.listen<AsyncValue<List<Pedido>>>(
      pedidosStreamProvider,
      _onPedidosChanged,
      fireImmediately: true,
    );

    _tickTimer = Timer.periodic(_delayCheckInterval, (_) {
      if (_latestPedidos.isNotEmpty) {
        _evaluateDelays(_latestPedidos);
      }
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<List<Pedido>>> _pedidosSub;
  final Map<String, _OrderSnapshot> _previousSnapshots =
      <String, _OrderSnapshot>{};
  final Set<String> _emittedNotifications = <String>{};
  List<Pedido> _latestPedidos = <Pedido>[];
  DateTime _lastSound = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _tickTimer;
  bool _hydrated = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final Map<NotificationRole, StreamController<AppNotification>>
      _newNotificationControllers = {};

  Stream<AppNotification> streamForRole(NotificationRole role) {
    _newNotificationControllers.putIfAbsent(
        role, () => StreamController<AppNotification>.broadcast());
    return _newNotificationControllers[role]!.stream;
  }

  void _onPedidosChanged(
    AsyncValue<List<Pedido>>? _,
    AsyncValue<List<Pedido>> next,
  ) {
    next.whenData((pedidos) {
      _latestPedidos = pedidos;
      _processPedidos(pedidos);
    });
  }

  void _processPedidos(List<Pedido> pedidos) {
    final previous = Map<String, _OrderSnapshot>.from(_previousSnapshots);

    _previousSnapshots
      ..clear()
      ..addEntries(
        pedidos.map(
          (pedido) => MapEntry(
            pedido.id,
            _OrderSnapshot(
              status: pedido.status,
              createdAt: pedido.createdAt,
              updatedAt: pedido.updatedAt,
              total: pedido.total,
              mesaNombre: pedido.mesaNombre,
              meseroNombre: pedido.meseroNombre,
            ),
          ),
        ),
      );

    if (!_hydrated) {
      _hydrated = true;
      return;
    }

    final newNotifications = <AppNotification>[];

    for (final pedido in pedidos) {
      final previousSnapshot = previous[pedido.id];
      if (previousSnapshot == null) {
        newNotifications.addAll(_notificationsForNewOrder(pedido));
        continue;
      }

      if (previousSnapshot.status != pedido.status) {
        newNotifications.addAll(
          _notificationsForStatusChange(pedido, previousSnapshot.status),
        );
      }
    }

    if (newNotifications.isNotEmpty) {
      _addNotifications(newNotifications);
      _playAlert(newNotifications);
    }

    _evaluateDelays(pedidos);
    _evaluateAdminMetrics(pedidos);
  }

  List<AppNotification> _notificationsForNewOrder(Pedido pedido) {
    final friendlyId = _friendlyId(pedido.id);
    final mesa = _mesaLabel(pedido);
    final createdAt = pedido.createdAt ?? DateTime.now();
    final timestamp = createdAt.millisecondsSinceEpoch;

    return <AppNotification>[
      _buildNotification(
        id: 'kitchen-${pedido.id}-created-$timestamp',
        role: NotificationRole.kitchen,
        title: 'Nuevo pedido recibido',
        message: 'El pedido #$friendlyId $mesa espera confirmacion en cocina.',
        severity: NotificationSeverity.critical,
        timestamp: createdAt,
        navigationRoute: '/cocina',
      ),
      _buildNotification(
        id: 'admin-${pedido.id}-created-$timestamp',
        role: NotificationRole.admin,
        title: 'Se registro un nuevo pedido',
        message:
            'Pedido #$friendlyId $mesa registrado por ${pedido.meseroNombre ?? 'mesero sin asignar'}.',
        severity: NotificationSeverity.info,
        timestamp: createdAt,
      ),
    ];
  }

  List<AppNotification> _notificationsForStatusChange(
    Pedido pedido,
    String previousStatus,
  ) {
    final friendlyId = _friendlyId(pedido.id);
    final mesa = _mesaLabel(pedido);
    final now = pedido.updatedAt ?? DateTime.now();
    final notifications = <AppNotification>[];

    switch (pedido.status) {
      case 'preparando':
        notifications.add(
          _buildNotification(
            id: 'kitchen-${pedido.id}-preparing',
            role: NotificationRole.kitchen,
            title: 'Pedido #$friendlyId en preparacion',
            message:
                'Confirmaste la preparacion del pedido $mesa. Mantener ritmo.',
            severity: NotificationSeverity.success,
            timestamp: now,
          ),
        );
        break;
      case 'terminado':
        notifications.addAll(<AppNotification>[
          _buildNotification(
            id: 'waiter-${pedido.id}-ready',
            role: NotificationRole.waiter,
            title: 'Pedido listo para entrega',
            message:
                'El pedido #$friendlyId $mesa esta terminado y espera ser entregado.',
            severity: NotificationSeverity.critical,
            timestamp: now,
            navigationRoute: '/mesero/pedidos',
            actionLabel: 'Ver pedido',
          ),
          _buildNotification(
            id: 'admin-${pedido.id}-ready',
            role: NotificationRole.admin,
            title: 'Pedido finalizado en cocina',
            message: 'El pedido #$friendlyId $mesa paso a estado terminado.',
            severity: NotificationSeverity.success,
            timestamp: now,
          ),
        ]);
        break;
      case 'cancelado':
        notifications.addAll(<AppNotification>[
          _buildNotification(
            id: 'waiter-${pedido.id}-cancelled',
            role: NotificationRole.waiter,
            title: 'Pedido cancelado',
            message:
                'El pedido #$friendlyId $mesa fue cancelado. Revisar con el cliente.',
            severity: NotificationSeverity.warning,
            timestamp: now,
            navigationRoute: '/mesero/pedidos',
          ),
          _buildNotification(
            id: 'admin-${pedido.id}-cancelled',
            role: NotificationRole.admin,
            title: 'Cancelacion registrada',
            message:
                'El pedido #$friendlyId fue cancelado. Verificar motivos y ajustar el flujo.',
            severity: NotificationSeverity.warning,
            timestamp: now,
          ),
        ]);
        break;
      case 'entregado':
      case 'pagado':
        notifications.add(
          _buildNotification(
            id: 'admin-${pedido.id}-delivered',
            role: NotificationRole.admin,
            title: 'Pedido entregado',
            message:
                'El pedido #$friendlyId fue entregado y registra un pago de \$${pedido.total.toStringAsFixed(0)}.',
            severity: NotificationSeverity.success,
            timestamp: now,
          ),
        );
        break;
      default:
        notifications.add(
          _buildNotification(
            id: 'admin-${pedido.id}-${pedido.status}',
            role: NotificationRole.admin,
            title: 'Estado actualizado',
            message:
                'El pedido #$friendlyId cambio de $previousStatus a ${pedido.status}.',
            severity: NotificationSeverity.info,
            timestamp: now,
          ),
        );
        break;
    }

    return notifications;
  }

  void _evaluateDelays(List<Pedido> pedidos) {
    final now = DateTime.now();

    for (final pedido in pedidos) {
      final reference = pedido.updatedAt ?? pedido.createdAt;
      if (reference == null) {
        continue;
      }

      final elapsed = now.difference(reference).inMinutes;

      if (pedido.status == 'pendiente' && elapsed >= 10) {
        _emitOnce(
          key: 'kitchen-${pedido.id}-delay10',
          notification: _buildNotification(
            id: 'kitchen-${pedido.id}-delay10',
            role: NotificationRole.kitchen,
            title: 'Pedido pendiente hace $elapsed min',
            message:
                'El pedido #${_friendlyId(pedido.id)} lleva $elapsed minutos pendiente. Priorizar su preparacion.',
            severity: NotificationSeverity.warning,
            timestamp: now,
          ),
        );
      }

      if (pedido.status == 'preparando' && elapsed >= 15) {
        _emitOnce(
          key: 'waiter-${pedido.id}-delay15',
          notification: _buildNotification(
            id: 'waiter-${pedido.id}-delay15',
            role: NotificationRole.waiter,
            title: 'Revisar pedido en cocina',
            message:
                'El pedido #${_friendlyId(pedido.id)} lleva $elapsed minutos en preparacion. Coordinar con cocina.',
            severity: NotificationSeverity.warning,
            timestamp: now,
          ),
        );
      }
    }
  }

  void _evaluateAdminMetrics(List<Pedido> pedidos) {
    final pendingCount = pedidos
        .where((pedido) =>
            pedido.status == 'pendiente' || pedido.status == 'preparando')
        .length;

    if (pendingCount >= 8) {
      _emitOnce(
        key: 'admin-backlog-high',
        notification: _buildNotification(
          id: 'admin-backlog-high',
          role: NotificationRole.admin,
          title: 'Alta carga operativa',
          message:
              'Hay $pendingCount pedidos activos. Considerar apoyo a cocina y meseros.',
          severity: NotificationSeverity.critical,
          timestamp: DateTime.now(),
        ),
      );
    } else if (pendingCount >= 5) {
      _emitOnce(
        key: 'admin-backlog-medium',
        notification: _buildNotification(
          id: 'admin-backlog-medium',
          role: NotificationRole.admin,
          title: 'Operacion exigida',
          message:
              'Hay $pendingCount pedidos pendientes o en preparacion. Monitorear tiempos.',
          severity: NotificationSeverity.warning,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _emitOnce({required String key, required AppNotification notification}) {
    if (_emittedNotifications.contains(key)) {
      return;
    }

    _emittedNotifications.add(key);
    _addNotifications(<AppNotification>[notification]);
    // _playAlert(<AppNotification>[notification]);
  }

  void _addNotifications(List<AppNotification> notifications) {
    final kitchen = List<AppNotification>.from(state.kitchen);
    final waiter = List<AppNotification>.from(state.waiter);
    final admin = List<AppNotification>.from(state.admin);

    for (final notification in notifications) {
      if (_emittedNotifications.contains(notification.id)) {
        continue;
      }

      _emittedNotifications.add(notification.id);

      switch (notification.role) {
        case NotificationRole.kitchen:
          kitchen.insert(0, notification);
          if (kitchen.length > _maxNotificationsPerRole) {
            kitchen.removeRange(_maxNotificationsPerRole, kitchen.length);
          }
          break;
        case NotificationRole.waiter:
          waiter.insert(0, notification);
          if (waiter.length > _maxNotificationsPerRole) {
            waiter.removeRange(_maxNotificationsPerRole, waiter.length);
          }
          break;
        case NotificationRole.admin:
          admin.insert(0, notification);
          if (admin.length > _maxNotificationsPerRole) {
            admin.removeRange(_maxNotificationsPerRole, admin.length);
          }
          break;
      }

      // Emitir evento a la escucha del rol
      if (_newNotificationControllers.containsKey(notification.role) &&
          !_newNotificationControllers[notification.role]!.isClosed) {
        _newNotificationControllers[notification.role]!.add(notification);
      }
    }

    state = state.copyWith(
      kitchen: kitchen,
      waiter: waiter,
      admin: admin,
    );
  }

  void markAllAsRead(NotificationRole role) {
    final updated = state
        .notificationsFor(role)
        .map((notification) => notification.copyWith(isRead: true))
        .toList();

    switch (role) {
      case NotificationRole.kitchen:
        state = state.copyWith(kitchen: updated);
        break;
      case NotificationRole.waiter:
        state = state.copyWith(waiter: updated);
        break;
      case NotificationRole.admin:
        state = state.copyWith(admin: updated);
        break;
    }
  }

  void markAsRead(NotificationRole role, String notificationId) {
    final notifications = state.notificationsFor(role);
    final updated = notifications
        .map(
          (notification) => notification.id == notificationId
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList();

    switch (role) {
      case NotificationRole.kitchen:
        state = state.copyWith(kitchen: updated);
        break;
      case NotificationRole.waiter:
        state = state.copyWith(waiter: updated);
        break;
      case NotificationRole.admin:
        state = state.copyWith(admin: updated);
        break;
    }
  }

  void notifyMesaAutoRelease({
    required int mesaId,
    String? cliente,
    Duration? tiempoOcupacion,
    String? motivo,
    String? pedidoId,
    String? estadoPedido,
    bool notifyAdmin = false,
  }) {
    final now = DateTime.now();
    final mensajeBase = StringBuffer('Mesa $mesaId se libero automaticamente');
    final clienteTrim = cliente?.trim() ?? '';

    if (clienteTrim.isNotEmpty) {
      mensajeBase.write(' (cliente $clienteTrim)');
    }

    mensajeBase.write('.');

    final motivoTrim = motivo?.trim() ?? '';
    if (motivoTrim.isNotEmpty) {
      mensajeBase.write(' Motivo: $motivoTrim.');
    }

    final duracionLabel =
        tiempoOcupacion != null ? _humanizeDuration(tiempoOcupacion) : null;
    if (duracionLabel != null) {
      mensajeBase.write(' Tiempo ocupada: $duracionLabel.');
    }

    final metadata = <String, dynamic>{
      'mesaId': mesaId,
      if (clienteTrim.isNotEmpty) 'cliente': clienteTrim,
      if (pedidoId != null && pedidoId.isNotEmpty) 'pedidoId': pedidoId,
      if (estadoPedido != null && estadoPedido.isNotEmpty)
        'estadoPedido': estadoPedido,
      if (tiempoOcupacion != null)
        'tiempoOcupacionSegundos': tiempoOcupacion.inSeconds,
    };

    final notifications = <AppNotification>[
      _buildNotification(
        id: 'waiter-mesa-$mesaId-liberada-${now.millisecondsSinceEpoch}',
        role: NotificationRole.waiter,
        title: 'Mesa liberada automaticamente',
        message: mensajeBase.toString(),
        severity: NotificationSeverity.info,
        timestamp: now,
        navigationRoute: '/mesero/pedidos/mesas',
        metadata: metadata,
      ),
    ];

    if (notifyAdmin) {
      notifications.add(
        _buildNotification(
          id: 'admin-mesa-$mesaId-liberada-${now.millisecondsSinceEpoch}',
          role: NotificationRole.admin,
          title: 'Mesa liberada automaticamente',
          message: mensajeBase.toString(),
          severity: NotificationSeverity.info,
          timestamp: now,
          navigationRoute: '/admin/mesas',
          metadata: metadata,
        ),
      );
    }

    _addNotifications(notifications);
    // _playAlert(notifications);
  }

  void _playAlert(List<AppNotification> notifications) {
    final now = DateTime.now();
    final shouldPlay = notifications.any(
      (notification) =>
          notification.severity == NotificationSeverity.critical ||
          notification.severity == NotificationSeverity.warning,
    );

    if (!shouldPlay) {
      return;
    }

    if (now.difference(_lastSound) < _soundThrottle) {
      return;
    }

    _lastSound = now;

    // Reproducir sonido de notificación general
    _audioPlayer.play(AssetSource('sounds/new_order.mp3')).catchError((e) {
      // Si falla el audio, usar el sonido del sistema como fallback
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  String _humanizeDuration(Duration duration) {
    if (duration.inMinutes <= 0) {
      return '${duration.inSeconds}s';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final parts = <String>[];

    if (hours > 0) {
      parts.add('${hours}h');
    }

    if (minutes > 0 || hours == 0) {
      parts.add('${minutes}m');
    }

    return parts.join(' ');
  }

  AppNotification _buildNotification({
    required String id,
    required NotificationRole role,
    required String title,
    required String message,
    required NotificationSeverity severity,
    required DateTime timestamp,
    String? actionLabel,
    String? navigationRoute,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id,
      role: role,
      title: title,
      message: message,
      severity: severity,
      timestamp: timestamp,
      actionLabel: actionLabel,
      navigationRoute: navigationRoute,
      metadata: metadata,
    );
  }

  String _friendlyId(String id) {
    if (id.length <= 6) {
      return id.toUpperCase();
    }
    return id.substring(id.length - 6).toUpperCase();
  }

  String _mesaLabel(Pedido pedido) {
    if ((pedido.mesaNombre?.isNotEmpty ?? false)) {
      return 'para ${pedido.mesaNombre}';
    }

    if ((pedido.tableNumber?.isNotEmpty ?? false)) {
      return 'para mesa ${pedido.tableNumber}';
    }

    return "para ${pedido.mode == 'domicilio' ? 'domicilio' : 'consumo interno'}";
  }

  @override
  void dispose() {
    _pedidosSub.close();
    _tickTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class _OrderSnapshot {
  _OrderSnapshot({
    required this.status,
    required this.total,
    this.createdAt,
    this.updatedAt,
    this.mesaNombre,
    this.meseroNombre,
  });

  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double total;
  final String? mesaNombre;
  final String? meseroNombre;
}
