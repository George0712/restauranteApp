import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';

class ListCardsUsers extends ConsumerWidget {
  final String rol;

  const ListCardsUsers({
    Key? key,
    required this.rol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider(rol));
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return usersAsync.when(
      data: (usuarios) {
        if (usuarios.isEmpty) {
          return Text('No hay usuarios con rol "$rol" registrados.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: usuarios.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final usuario = usuarios[index];

            return GestureDetector(
              onTap: () => _showUserOptions(context, usuario),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Center(
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: theme.primaryColor.withAlpha(230),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${usuario.nombre} ${usuario.apellidos}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('Error al cargar usuarios: $error'),
    );
  }

  void _showUserOptions(BuildContext context, UserModel usuario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UserOptionsBottomSheet(usuario: usuario),
    );
  }
}

class UserOptionsBottomSheet extends StatelessWidget {
  final UserModel usuario;

  const UserOptionsBottomSheet({
    super.key,
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${usuario.nombre} ${usuario.apellidos}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          usuario.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Opciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildOptionTile(
                    context,
                    icon: Icons.visibility_outlined,
                    title: 'Ver detalles',
                    subtitle: 'Información completa del usuario',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      // Acción ver detalles
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOptionTile(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Editar usuario',
                    subtitle: 'Modificar información y configuración',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      // Acción editar usuario
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOptionTile(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Eliminar usuario',
                    subtitle: 'Remover permanentemente',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, usuario);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Eliminar usuario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${usuario.nombre} ${usuario.apellidos}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar lógica de eliminación
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuario eliminado'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
