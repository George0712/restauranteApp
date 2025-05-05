// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/data/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/screens/splash/splah_loading_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final userModelAsync = ref.watch(userModelProvider);

  return userModelAsync.when(
    loading: () => const SplashLoadingScreen(),
    error: (e, _) => Center(child: Text('Error: $e')),
    data: (user) {
      Future.microtask(() => _redirectByRole(context, user));
      return const SizedBox(); // Evita renderizar widgets por ahora
    },
  );
  }
}

void _redirectByRole(BuildContext context, UserModel user) {
  switch (user.rol) {
    case 'admin':
      context.go('/admin/home');
      break;
    case 'mesero':
      context.go('/mesero/home');
      break;
    case 'cocinero':
      context.go('/cocinero/home');
      break;
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol desconocido: ${user.rol}')),
      );
  }
}




