// ignore_for_file: unreachable_switch_default

import "package:flutter/material.dart";

enum NotificationRole {
  kitchen,
  waiter,
  admin,
}

enum NotificationSeverity {
  info,
  success,
  warning,
  critical,
}

class AppNotification {
  final String id;
  final NotificationRole role;
  final String title;
  final String message;
  final NotificationSeverity severity;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;
  final String? navigationRoute;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.role,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
    this.navigationRoute,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    NotificationRole? role,
    String? title,
    String? message,
    NotificationSeverity? severity,
    DateTime? timestamp,
    bool? isRead,
    String? actionLabel,
    String? navigationRoute,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      role: role ?? this.role,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel ?? this.actionLabel,
      navigationRoute: navigationRoute ?? this.navigationRoute,
      metadata: metadata ?? this.metadata,
    );
  }
}

class NotificationState {
  final List<AppNotification> kitchen;
  final List<AppNotification> waiter;
  final List<AppNotification> admin;

  const NotificationState({
    required this.kitchen,
    required this.waiter,
    required this.admin,
  });

  factory NotificationState.initial() => const NotificationState(
        kitchen: <AppNotification>[],
        waiter: <AppNotification>[],
        admin: <AppNotification>[],
      );

  NotificationState copyWith({
    List<AppNotification>? kitchen,
    List<AppNotification>? waiter,
    List<AppNotification>? admin,
  }) {
    return NotificationState(
      kitchen: kitchen ?? this.kitchen,
      waiter: waiter ?? this.waiter,
      admin: admin ?? this.admin,
    );
  }

  List<AppNotification> notificationsFor(NotificationRole role) {
    switch (role) {
      case NotificationRole.kitchen:
        return kitchen;
      case NotificationRole.waiter:
        return waiter;
      case NotificationRole.admin:
        return admin;
    }
  }
}

Color notificationColor(NotificationSeverity severity, ThemeData theme) {
  switch (severity) {
    case NotificationSeverity.success:
      return const Color(0xFF34D399);
    case NotificationSeverity.warning:
      return const Color(0xFFF59E0B);
    case NotificationSeverity.critical:
      return const Color(0xFFF87171);
    case NotificationSeverity.info:
    default:
      return theme.colorScheme.secondary;
  }
}
