import 'package:flutter/material.dart';

class SnackbarHelper {
  const SnackbarHelper._();

  static final _key = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get key => _key;

  static void showSnackBar(String? message, {bool isError = false}) {
    final messenger = _key.currentState;
    if (messenger != null && message != null && message.isNotEmpty) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : null,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}