import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

            return Container(
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
              child: Center(
                child: Text(
                  categoria.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
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
}
