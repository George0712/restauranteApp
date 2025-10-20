import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/cloudinary_image_widget.dart';

class ListCardsProducts extends ConsumerWidget {
  const ListCardsProducts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return productsAsync.when(
      data: (productos) {
        if (productos.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2E37).withValues(alpha: 0.5),
                    const Color(0xFF1A1B23).withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade700,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay Productos registrados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: productos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final producto = productos[index];

            return GestureDetector(
              onTap: () => _showProductOptions(context, ref, producto),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2D2E37),
                          Color(0xFF1A1B23),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: producto.disponible
                            ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                            : const Color(0xFFEF4444).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                children: [
                                  CloudinaryImageWidget(
                                    imageUrl: producto.photo,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    placeholder: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.grey.shade800,
                                            Colors.grey.shade700,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                        ),
                                      ),
                                    ),
                                    errorWidget: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                            const Color(0xFF6366F1).withValues(alpha: 0.2),
                            const Color(0xFF6366F1).withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.fastfood_rounded,
                                        size: 80,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),

                                  // Overlay sutil para mejorar la legibilidad
                                  if (producto.photo != null &&
                                      producto.photo!.isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        producto.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF6366F1),
                            const Color(0xFF6366F1).withValues(alpha: 0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1)
                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '\$${producto.price.toStringAsFixed(0).replaceAllMapped(
                                              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                              (Match m) => '${m[1]}.',
                                            )}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Badge de disponibilidad
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: producto.disponible
                                    ? [
                                        const Color(0xFF10B981),
                                        const Color(0xFF059669),
                                      ]
                                    : [
                                        const Color(0xFFEF4444),
                                        const Color(0xFFDC2626),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (producto.disponible
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  producto.disponible
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  producto.disponible
                                      ? 'Disponible'
                                      : 'No disponible',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Icono de opciones
                        /*Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),*/
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D2E37).withValues(alpha: 0.5),
                const Color(0xFF1A1B23).withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade900.withValues(alpha: 0.2),
                Colors.red.shade900.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.shade700,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar productos',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductOptions(
      BuildContext context, WidgetRef ref, dynamic producto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProductOptionsBottomSheet(
        producto: producto,
        ref: ref,
      ),
    );
  }
}

class ProductOptionsBottomSheet extends ConsumerStatefulWidget {
  final dynamic producto;
  final WidgetRef ref;

  const ProductOptionsBottomSheet({
    super.key,
    required this.producto,
    required this.ref,
  });

  @override
  ConsumerState<ProductOptionsBottomSheet> createState() =>
      _ProductOptionsBottomSheetState();
}

class _ProductOptionsBottomSheetState
    extends ConsumerState<ProductOptionsBottomSheet> {
  bool _isLoading = false;

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
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Título con imagen del producto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CloudinaryImageWidget(
                      imageUrl: widget.producto.photo,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.producto.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${widget.producto.price.toStringAsFixed(0).replaceAllMapped(
                                    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]}.',
                                  )}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.producto.disponible
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.producto.disponible
                                    ? 'Activo'
                                    : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.producto.disponible
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Opciones con funcionalidad
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
                    _buildOptionTile(
                      context,
                      icon: Icons.visibility_outlined,
                      title: 'Ver detalles',
                      subtitle: 'Información completa del producto',
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                            '/admin/manage/producto/detalle/${widget.producto.id}');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildOptionTile(
                      context,
                      icon: Icons.edit_outlined,
                      title: 'Editar producto',
                      subtitle: 'Modificar información del producto',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                            '/admin/manage/producto/editar/${widget.producto.id}');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildOptionTile(
                      context,
                      icon: widget.producto.disponible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      title: widget.producto.disponible
                          ? 'Desactivar producto'
                          : 'Activar producto',
                      subtitle: widget.producto.disponible
                          ? 'Ocultar del menú de clientes'
                          : 'Mostrar en el menú de clientes',
                      color: widget.producto.disponible
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                      onTap: () => _toggleAvailability(context),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionTile(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Eliminar producto',
                      subtitle: 'Eliminar permanentemente',
                      color: const Color(0xFFEF4444),
                      onTap: () => _showDeleteConfirmation(context),
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Función para cambiar disponibilidad
  Future<void> _toggleAvailability(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final controller = ref.read(productManagementControllerProvider);
      final result = await controller.toggleProductAvailability(
        widget.producto.id,
        widget.producto.disponible,
      );

      if (result == null) {
        // Éxito
        if (mounted) {
          Navigator.pop(context);
        }

        final message = widget.producto.disponible
            ? 'Producto desactivado correctamente'
            : 'Producto activado correctamente';

        if (widget.producto.disponible) {
          SnackbarHelper.showWarning(message);
        } else {
          SnackbarHelper.showSuccess(message);
        }
      } else {
        // Error
        SnackbarHelper.showError('Error: $result');
      }
    } catch (e) {
      SnackbarHelper.showError('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Función para eliminar producto
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.withValues(alpha: 0.8),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar producto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar "${widget.producto.name}"?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer y se eliminará permanentemente de la base de datos.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Cerrar diálogo
              Navigator.pop(context); // Cerrar bottom sheet
              await _deleteProduct();
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

  // Función para ejecutar la eliminación
  Future<void> _deleteProduct() async {
    try {
      final controller = ref.read(productManagementControllerProvider);
      final result = await controller.deleteProduct(widget.producto.id);

      if (result == null) {
        // Éxito
        SnackbarHelper.showSuccess('Producto eliminado correctamente');
      } else {
        // Error
        SnackbarHelper.showError('Error al eliminar: $result');
      }
    } catch (e) {
      SnackbarHelper.showError('Error inesperado: $e');
    }
  }
}
