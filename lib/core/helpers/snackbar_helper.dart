import 'package:flutter/material.dart';
import 'package:restaurante_app/presentation/widgets/app_toast.dart';

class SnackbarHelper {
  const SnackbarHelper._();

  static final _key = GlobalKey<ScaffoldMessengerState>();
  static final _navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _currentToast;

  static GlobalKey<ScaffoldMessengerState> get key => _key;
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  static void _showToast(String message, ToastType type) {
    if (message.isEmpty) return;

    // Obtener el contexto desde el navigatorKey
    final context = _navigatorKey.currentContext;
    if (context == null) {
      // Fallback al método antiguo si no hay contexto
      _showSnackBarFallback(message, type);
      return;
    }

    // Remover toast actual si existe
    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.of(context);

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        right: 0,
        child: AppToast(
          type: type,
          message: message,
          onDismiss: () {
            _currentToast?.remove();
            _currentToast = null;
          },
        ),
      ),
    );

    overlay.insert(_currentToast!);
  }

  static void _showSnackBarFallback(String message, ToastType type) {
    Color backgroundColor;
    switch (type) {
      case ToastType.success:
        backgroundColor = const Color(0xFF10B981);
        break;
      case ToastType.error:
        backgroundColor = const Color(0xFFEF4444);
        break;
      case ToastType.info:
        backgroundColor = const Color(0xFF3B82F6);
        break;
      case ToastType.warning:
        backgroundColor = const Color(0xFFF97316);
        break;
    }

    final messenger = _key.currentState;
    if (messenger != null) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  static void showSuccess(String message) {
    _showToast(message, ToastType.success);
  }

  static void showError(String message) {
    _showToast(message, ToastType.error);
  }

  static void showInfo(String message) {
    _showToast(message, ToastType.info);
  }

  static void showWarning(String message) {
    _showToast(message, ToastType.warning);
  }
}