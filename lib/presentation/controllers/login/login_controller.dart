import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/utils/regex_validators.dart';
import 'package:restaurante_app/presentation/providers/common/loading_provider.dart';

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
    return true; 
  }
}