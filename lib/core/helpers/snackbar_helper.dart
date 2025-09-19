import 'package:flutter/material.dart';

class SnackbarHelper {
  const SnackbarHelper._();

  static final _key = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get key => _key;

  static void showSnackBar(String? message, {Color? backgroundColor}) {
    final messenger = _key.currentState;
    if (messenger != null && message != null && message.isNotEmpty) {
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
    showSnackBar(message, backgroundColor: const Color(0xFF10B981));
  }

  static void showError(String message) {
    showSnackBar(message, backgroundColor: const Color(0xFFEF4444));
  }

  static void showInfo(String message) {
    showSnackBar(message, backgroundColor: const Color(0xFF3B82F6));
  }
}