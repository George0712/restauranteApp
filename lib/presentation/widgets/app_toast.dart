import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

class AppToast extends StatefulWidget {
  final ToastType type;
  final String message;
  final VoidCallback onDismiss;

  const AppToast({
    super.key,
    required this.type,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
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

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _dismiss();
      }
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getToastConfig();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  config.color,
                  config.color.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ToastConfig _getToastConfig() {
    switch (widget.type) {
      case ToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
        );
      case ToastType.error:
        return _ToastConfig(
          icon: Icons.error_rounded,
          color: const Color(0xFFEF4444),
        );
      case ToastType.info:
        return _ToastConfig(
          icon: Icons.info_rounded,
          color: const Color(0xFF3B82F6),
        );
      case ToastType.warning:
        return _ToastConfig(
          icon: Icons.warning_rounded,
          color: const Color(0xFFF97316),
        );
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color color;

  _ToastConfig({
    required this.icon,
    required this.color,
  });
}
