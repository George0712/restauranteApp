import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/presentation/controllers/mesero/carrito_controller.dart';
import 'package:restaurante_app/presentation/widgets/cloudinary_image_widget.dart';

class CarritoItemSlide extends ConsumerWidget {
  final ItemCarrito item;
  final List<String> nombresAdicionales;
  final int index;
  final bool isReadOnly;

  const CarritoItemSlide({
    super.key,
    required this.item,
    required this.nombresAdicionales,
    required this.index,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carritoController = ref.watch(carritoControllerProvider);
    final theme = Theme.of(context);

    final modsPrecio = item.adicionales?.fold<double>(
          0,
          (sum, adicional) => sum + adicional.price,
        ) ??
        0;

    final totalItem = (item.precioUnitario + modsPrecio) * item.cantidad;
    final white70 = Colors.white.withOpacity(0.7);

    Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.05), // Fondo transparente con leve brillo
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen centrada verticalmente
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.producto.photo != null &&
                        item.producto.photo!.isNotEmpty
                    ? CloudinaryImageWidget(
                        imageUrl: item.producto.photo,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(
                          Icons.fastfood_rounded,
                          color: Colors.grey,
                          size: 28,
                        ),
                      )
                    : const Icon(
                        Icons.fastfood_rounded,
                        color: Colors.grey,
                        size: 42,
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // Contenido derecho con nombre, adicionales, notas y controles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.producto.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Text(
                    '\$${totalItem.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Adicionales y nota con estilo sutil y sin saturar
                  if (nombresAdicionales.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '+ ${nombresAdicionales.join(", ")}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: white70,
                        ),
                      ),
                    ),

                  if (item.notas?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Nota: ${item.notas}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: white70,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: isReadOnly
                  ? _buildReadOnlyQuantity()
                  : _buildCantidadControls(ref, carritoController),
            ),
          ],
        ),
      ),
    );

    if (isReadOnly) {
      return cardContent;
    }

    return Dismissible(
      key: Key('${item.producto.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Eliminar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _mostrarConfirmacionEliminacion(context);
      },
      onDismissed: (direction) {
        carritoController.eliminarItem(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.producto.name} eliminado del carrito'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Deshacer',
              textColor: Colors.white,
              onPressed: () {
                SnackbarHelper.showInfo('Función "Deshacer" no disponible aún');
              },
            ),
          ),
        );
      },
      child: cardContent,
    );
  }

  Widget _buildReadOnlyQuantity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 16,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.cantidad}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCantidadControls(WidgetRef ref, CarritoController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: item.cantidad > 1
                ? () => controller.actualizarCantidad(index, item.cantidad - 1)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '${item.cantidad}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onPressed: item.cantidad < 99
                ? () => controller.actualizarCantidad(index, item.cantidad + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final bool enabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.35),
        ),
      ),
    );
  }

  Future<bool?> _mostrarConfirmacionEliminacion(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar producto',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${item.producto.name}" del carrito?',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
