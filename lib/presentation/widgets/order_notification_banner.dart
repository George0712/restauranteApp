import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType {
  newOrder,
  orderCompleted,
  orderUpdated,
}

class OrderNotificationBanner extends ConsumerStatefulWidget {
  final NotificationType type;
  final String message;
  final VoidCallback onDismiss;
  final bool shouldPlaySound;

  const OrderNotificationBanner({
    super.key,
    required this.type,
    required this.message,
    required this.onDismiss,
    this.shouldPlaySound = true,
  });

  @override
  ConsumerState<OrderNotificationBanner> createState() => _OrderNotificationBannerState();
}

class _OrderNotificationBannerState extends ConsumerState<OrderNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Solo reproducir sonido si shouldPlaySound es true
    if (widget.shouldPlaySound) {
      _playSound();
    }

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _playSound() async {
    try {
      String soundPath;
      switch (widget.type) {
        case NotificationType.newOrder:
          soundPath = 'sounds/new_order.mp3';
          break;
        case NotificationType.orderCompleted:
          soundPath = 'sounds/order_complete.mp3';
          break;
        case NotificationType.orderUpdated:
          soundPath = 'sounds/order_updated.mp3';
          break;
      }

      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Si falla, al menos hacer vibración como feedback
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  config.color,
                  config.color.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: config.color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    config.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        config.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _NotificationConfig _getNotificationConfig() {
    switch (widget.type) {
      case NotificationType.newOrder:
        return _NotificationConfig(
          title: 'Nuevo Pedido',
          icon: Icons.restaurant_menu,
          color: const Color(0xFFF97316),
        );
      case NotificationType.orderCompleted:
        return _NotificationConfig(
          title: 'Pedido Completado',
          icon: Icons.check_circle,
          color: const Color(0xFF10B981),
        );
      case NotificationType.orderUpdated:
        return _NotificationConfig(
          title: 'Pedido Modificado',
          icon: Icons.edit_notifications,
          color: const Color(0xFF3B82F6),
        );
    }
  }
}

class _NotificationConfig {
  final String title;
  final IconData icon;
  final Color color;

  _NotificationConfig({
    required this.title,
    required this.icon,
    required this.color,
  });
}
