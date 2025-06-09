
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/providers/login/auth_service.dart';

class SettingsUserScreen extends ConsumerWidget {
  const SettingsUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final currentLocation = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .fullPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (user) => Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                backgroundImage:
                    user.foto != null ? NetworkImage(user.foto!) : null,
                child: user.foto == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                '${user.nombre} ${user.apellidos}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(user.email, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  user.rol,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.deepPurple.withOpacity(0.4),
              ),
              const Divider(height: 32, color: Colors.white24),

              if (user.rol == 'admin') ...[
                // Si la ruta actual es /mesero/home, mostrar enlace a Admin
                if (currentLocation.startsWith('/mesero')) ...[
                  _customTile(
                    icon: Icons.admin_panel_settings,
                    label: 'Ir a vista de Administrador',
                    onTap: () => context.go('/admin/home'),
                  ),
                ] else ...[
                  _customTile(
                    icon: Icons.restaurant_menu_rounded,
                    
                    label: 'Ir a vista de Mesero',
                    onTap: () => context.go('/mesero/home'),
                  ),
                ],
                const SizedBox(height: 12),
                // Nuevo botón: Ir a vista de Cocina
                _customTile(
                  icon: Icons.kitchen,
                  label: 'Ir a vista de Cocina',
                  onTap: () => context.go('/cocinero/home'),
                ),
                const SizedBox(height: 12),
              ],

              _customTile(
                icon: Icons.logout,
                label: 'Cerrar sesión',
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

  Widget _customTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}