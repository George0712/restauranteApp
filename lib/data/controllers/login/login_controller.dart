import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/data/providers/loading/loading_provider.dart';

class LoginController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  bool areFieldsValid() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    return AppConstants.emailRegex.hasMatch(email) &&
           AppConstants.passwordRegex.hasMatch(password);
  }

  Future<bool> login(WidgetRef ref) async {
    ref.read(loadingProvider.notifier).state = true;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!areFieldsValid()) {
      ref.read(loadingProvider.notifier).state = false;
      return false;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      ref.read(loadingProvider.notifier).state = false;
      return true;
    } on FirebaseAuthException catch (e) {
      // Puedes mostrar un snackbar u otra forma de feedback
      debugPrint('Error en login: ${e.message}');
      ref.read(loadingProvider.notifier).state = false;
      return false;
    }
  }
}