import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:restaurante_app/models/user_model.dart';

import 'package:restaurante_app/presentation/controllers/admin/admin_controller.dart';
import 'package:restaurante_app/presentation/controllers/admin/register_user_controller.dart';

final registerUserControllerProvider = Provider<RegisterUserController>((ref) {
  final controller = RegisterUserController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final adminControllerProvider = StateNotifierProvider<AdminController, AdminDashboardState>((ref) {
  return AdminController();
});


final isContactInfoValidProvider = StateProvider<bool>((ref) => false);

final isCredentialsValidProvider = StateProvider<bool>((ref) => false);

final userTempProvider = StateProvider<UserModel?>((ref) => null);


