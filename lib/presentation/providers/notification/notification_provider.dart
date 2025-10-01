import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:restaurante_app/data/models/notification_model.dart";
import "package:restaurante_app/presentation/controllers/notification/notification_controller.dart";

final notificationCenterProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  final controller = NotificationController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

final unreadNotificationsProvider =
    Provider.family<int, NotificationRole>((ref, role) {
  final state = ref.watch(notificationCenterProvider);
  return state
      .notificationsFor(role)
      .where((notification) => !notification.isRead)
      .length;
});
