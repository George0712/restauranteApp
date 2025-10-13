import 'package:flutter/material.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/presentation/widgets/cloudinary_image_widget.dart';

class CarritoItem extends StatelessWidget {
  final ItemCarrito item;
  final List<String> nombresAdicionales;

  const CarritoItem({
    super.key,
    required this.item,
    required this.nombresAdicionales,
  });

  @override
  Widget build(BuildContext context) {
    final modsPrecio = item.adicionales?.fold<double>(
          0,
          (sum, adicional) => sum + adicional.price,
        ) ??
        0;
    final totalItem = (item.precioUnitario + modsPrecio) * item.cantidad;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: ListTile(
        leading: item.producto.photo != null && item.producto.photo!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CloudinaryImageWidget(
                  imageUrl: item.producto.photo,
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
              )
            : const Text('🍽️', style: TextStyle(fontSize: 24)),
        title: Text('${item.producto.name} x${item.cantidad}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nombresAdicionales.isNotEmpty)
              Text('Adicionales: ${nombresAdicionales.join(", ")}',
                  style: const TextStyle(fontSize: 12)),
            if (item.notas?.isNotEmpty ?? false)
              Text('Nota: ${item.notas}',
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Text(
          '\$${totalItem.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              )}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
