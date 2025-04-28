import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/presentation/controllers/login/login_controller.dart';

final loginControllerProvider = Provider<LoginController>((ref) {
  final controller = LoginController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

// Provider para controlar si el password está oculto o no
final passwordVisibilityProvider = StateProvider<bool>((ref) => true);

// Provider para saber si los campos son válidos
final fieldsValidProvider = StateProvider<bool>((ref) => false);