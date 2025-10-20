import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';

class ListCardsCategories extends ConsumerWidget {
  const ListCardsCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoryDisponibleProvider);

    return categoriasAsync.when(
      data: (categorias) {
        if (categorias.isEmpty) {
          return const Text('No hay categorías disponibles.');
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: categorias.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
          ),
          itemBuilder: (context, index) {
            final categoria = categorias[index];

            return GestureDetector(
              onTap: () => _showCategoryOptions(context, ref, categoria),
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
                  border: Border.all(
                    color: categoria.disponible
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        categoria.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: categoria.disponible
                              ? Colors.green.withValues(alpha: 0.7)
                              : Colors.red.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoria.disponible ? "Activo" : "Inactivo",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Text('Error al cargar categorías: $e'),
    );
  }

  void _showCategoryOptions(
      BuildContext context, WidgetRef ref, dynamic categoria) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _CategoryOptionsBottomSheet(categoria: categoria, ref: ref),
    );
  }
}

class _CategoryOptionsBottomSheet extends ConsumerStatefulWidget {
  final dynamic categoria;
  final WidgetRef ref;
  const _CategoryOptionsBottomSheet(
      {required this.categoria, required this.ref});
  @override
  ConsumerState<_CategoryOptionsBottomSheet> createState() =>
      _CategoryOptionsBottomSheetState();
}

class _CategoryOptionsBottomSheetState
    extends ConsumerState<_CategoryOptionsBottomSheet> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final categoria = widget.categoria;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(Icons.category_rounded,
                        color: Colors.white, size: 48)
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.categoria.disponible
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.categoria.disponible ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.categoria.disponible
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Editar
                    _buildOptionTile(
                      context,
                      icon: Icons.edit_outlined,
                      title: 'Editar Categoría',
                      subtitle: 'Modificar detalles de la categoría',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/manage/category/edit',
                            extra: categoria);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Activar/desactivar
                    _buildOptionTile(
                      context,
                      icon: categoria.disponible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      title: categoria.disponible ? 'Desactivar Categoría' : 'Activar Categoría',
                      subtitle: categoria.disponible
                          ? 'Ocultar la categoría'
                          : 'Hacer visible la categoría',
                      color:
                          categoria.disponible ? Colors.orange : Colors.green,
                      onTap: () => _toggleAvailability(context, categoria),
                    ),
                    const SizedBox(height: 16),
                    // Eliminar
                    _buildOptionTile(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Eliminar Categoría',
                      subtitle: 'Eliminar permanentemente',
                      color: Colors.red,
                      onTap: () => _showDeleteConfirmation(context, categoria),
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
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
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
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
                ],
              ),
            ),
            
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAvailability(
      BuildContext context, dynamic categoria) async {
    setState(() => _isLoading = true);
    final controller = ref.read(registerCategoryControllerProvider);
    final result = await controller.actualizarCategoria(
      ref,
      id: categoria.id,
      nombre: categoria.name,
      disponible: !categoria.disponible,
      foto: categoria.photo,
    );
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
    }
    if (result == null) {
      SnackbarHelper.showSuccess(categoria.disponible
          ? 'Categoría desactivada'
          : 'Categoría activada');
    } else {
      SnackbarHelper.showError('Error: $result');
    }
  }

  void _showDeleteConfirmation(BuildContext context, dynamic categoria) {
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
                'Eliminar categoría',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar esta categoría? Esta acción no se puede deshacer.',
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
              Navigator.pop(ctx); // Cerrar diálogo
              Navigator.pop(context); // Cerrar bottom sheet
              await _deleteCategory(categoria);
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

  Future<void> _deleteCategory(dynamic categoria) async {
    setState(() => _isLoading = true);
    final controller = ref.read(registerCategoryControllerProvider);
    await controller.eliminarCategoria(ref, id: categoria.id);
    setState(() => _isLoading = false);
  }
}
