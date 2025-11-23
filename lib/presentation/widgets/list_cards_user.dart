import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/build_empty_state.dart';

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
          return buildEmptyState(
            context, 
            'No hay usuarios registrados', 
            Icons.people_alt_outlined,
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
            return GestureDetector(
              onTap: () => _showUserOptions(context, ref, usuario),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.6),
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
                        color: theme.primaryColor.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${usuario.nombre} ${usuario.apellidos}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      error: (error, stackTrace) => Center(
          child: Text('Error al cargar usuarios: $error',
              style: const TextStyle(color: Colors.red))),
    );
  }

  void _showUserOptions(
      BuildContext context, WidgetRef ref, UserModel usuario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          UserOptionsBottomSheet(usuario: usuario, ref: ref, rol: rol),
    );
  }
}

class UserOptionsBottomSheet extends ConsumerStatefulWidget {
  final UserModel usuario;
  final WidgetRef ref;
  final String rol;

  const UserOptionsBottomSheet(
      {Key? key, required this.usuario, required this.ref, required this.rol})
      : super(key: key);

  @override
  ConsumerState<UserOptionsBottomSheet> createState() =>
      _UserOptionsBottomSheetState();
}

class _UserOptionsBottomSheetState
    extends ConsumerState<UserOptionsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;

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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
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
                          color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      usuario.email,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildOptionTile(
            context,
            icon: Icons.visibility_outlined,
            title: 'Ver detalles',
            subtitle: 'Información completa del usuario',
            color: const Color(0xFF3B82F6),
            onTap: () {
              context.pop();
              context.push('/admin/manage/user/detail/${usuario.uid}');
            },
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            context,
            icon: Icons.edit_outlined,
            title: 'Editar usuario',
            subtitle: 'Modificar información de contacto',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              context.pop(context);
              context.push('/admin/manage/user/edit', extra: usuario);
            },
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            context,
            icon: Icons.delete_outline,
            title: 'Eliminar usuario',
            subtitle: 'Remover permanentemente',
            color: const Color(0xFFEF4444),
            onTap: () async {
              _showDeleteConfirmation(context, widget.rol, usuario);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7))),
              ],
            )),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String rol, UserModel usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminar usuario',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar este usuario? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _deleteUser(ctx, rol, usuario);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(
      BuildContext context, String rol, UserModel usuario) async {
    try {
      final controller = ref.read(registerUserControllerProvider);
      final result = await controller.deleteUser(usuario.uid);

      if (result != null) {
        SnackbarHelper.showError('Error al eliminar: $result');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError('Error al eliminar: $e');
      }
    }
  }
}
