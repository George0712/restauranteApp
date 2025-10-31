import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/cloudinary_image_widget.dart'; // O usa otra para imagen

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text(
                  'Usuario no encontrado',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: size.height * 0.4,
                  automaticallyImplyLeading: false,
                  pinned: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        user.foto != null && user.foto!.isNotEmpty
                            ? CloudinaryImageWidget(
                                imageUrl: user.foto!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: fallbackAvatar(theme),
                              )
                            : fallbackAvatar(theme),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black87,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 16,
                          child: Text(
                            '${user.nombre} ${user.apellidos}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 32 : 20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoRow(Icons.email_outlined, 'Email', user.email),
                        const SizedBox(height: 12),
                        infoRow(Icons.person_outline, 'Usuario', user.username),
                        const SizedBox(height: 12),
                        infoRow(
                            Icons.phone_outlined, 'Teléfono', user.telefono),
                        const SizedBox(height: 12),
                        infoRow(Icons.location_on_outlined, 'Dirección',
                            user.direccion),
                        const SizedBox(height: 12),
                        infoRow(Icons.badge_outlined, 'Rol', user.rol),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push(
                                    '/admin/manage/user/edit',
                                    extra: user),
                                icon: const Icon(Icons.edit,
                                    color: Colors.white70),
                                label: const Text(
                                  'Editar Usuario',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showDeleteConfirmation(
                                      context, user.rol, ref, user);
                                },
                                icon: const Icon(Icons.delete,
                                    color: Colors.white70),
                                label: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade300,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: ${e.toString()}',
                style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget fallbackAvatar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.3),
            theme.primaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
          child: Icon(Icons.person, size: 120, color: Colors.white70)),
    );
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String rol, WidgetRef ref, UserModel usuario) {
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
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
              Navigator.pop(ctx); // Cierra el diálogo de confirmación
              Navigator.pop(
                  context); // Cierra la pantalla de detalle (opcional, si quieres regresar)
              await _deleteUser(context, rol, ref, usuario);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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

  Future<void> _deleteUser(BuildContext context, String rol, WidgetRef ref,
      UserModel usuario) async {
    try {
      final controller = ref.read(registerUserControllerProvider);
      final result = await controller.deleteUser(usuario.uid);

      if (result == null) {
        if (context.mounted) {
          ref.invalidate(usersProvider(rol));
          SnackbarHelper.showSuccess('Usuario eliminado correctamente');
        }
      } else {
        if (context.mounted) {
          SnackbarHelper.showError('Error al eliminar: $result');
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError('Error inesperado: $e');
      }
    }
  }
}
