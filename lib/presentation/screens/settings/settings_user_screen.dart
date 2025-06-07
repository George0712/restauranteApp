// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/providers/login/auth_service.dart';

class SettingsUserScreen extends ConsumerWidget {
  const SettingsUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.secondaryHeaderColor.withAlpha(100),
                foregroundColor: theme.primaryColor.withAlpha(230),
                backgroundImage: user.foto != null
                    ? NetworkImage(user.foto!)
                    : null,
                child: user.foto == null ? const Icon(Icons.person, size: 40) : null,
              ),
              const SizedBox(height: 16),
              Text('${user.nombre} ${user.apellidos}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Chip(label: Text(user.rol), backgroundColor: theme.primaryColor.withAlpha(50)),

              const Divider(height: 32),

              if (user.rol == 'admin') ...[
                ListTile(
                  leading: const Icon(Icons.restaurant_menu_rounded),
                  title: const Text('Ir a vista de Mesero'),
                  onTap: () {
                    context.push('/mesero/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.kitchen),
                  title: const Text('Ir a vista de Cocina'),
                  onTap: () {
                    context.push('/cocinero/home');
                  },
                ),
              ],

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  await ref.read(authProvider).signOut();
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
