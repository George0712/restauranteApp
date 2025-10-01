import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/notification_model.dart';
import 'package:restaurante_app/presentation/providers/notification/notification_provider.dart';
import 'package:restaurante_app/presentation/widgets/notification_sheet.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({
    super.key,
    required this.role,
  });
  final NotificationRole role;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications =
        ref.watch(notificationCenterProvider).notificationsFor(role);
    final unreadCount =
        notifications.where((notification) => !notification.isRead).length;
    return IconButton(
      onPressed: () {
        if (notifications.isNotEmpty) {
          ref.read(notificationCenterProvider.notifier).markAllAsRead(role);
        }
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: NotificationSheet(role: role),
          ),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_rounded,
            color: Colors.white,
            size: 30,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notificaciones',
    );
  }
}
