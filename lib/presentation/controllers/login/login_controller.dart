import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/utils/regex_validators.dart';
import 'package:restaurante_app/presentation/providers/common/loading_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
class LoginController {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  bool areFieldsValid() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    return AppRegex.emailRegex.hasMatch(email) &&
           AppRegex.passwordRegex.hasMatch(password);
  }

  Future<bool> login(WidgetRef ref) async {
    ref.read(loadingProvider.notifier).state = true;
    await Future.delayed(const Duration(seconds: 2));
    if (!areFieldsValid()) {
      ref.read(loadingProvider.notifier).state = false;
      return false;
    }
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      await _authService.loginWithEmailAndPassword(email, password);
      ref.read(loadingProvider.notifier).state = false;
      return true;
    } on FirebaseAuthException catch (e) {
      ref.read(loadingProvider.notifier).state = false;
      // Puedes mostrar aquí un error bonito si quieres.
      debugPrint('Error de login: ${e.message}');
      return false;
    }
  }
}