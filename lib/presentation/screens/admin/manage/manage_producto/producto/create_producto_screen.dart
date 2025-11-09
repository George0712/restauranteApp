import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/list_cards_products.dart';

class CreateProductoScreen extends ConsumerStatefulWidget {
  const CreateProductoScreen({super.key});

  @override
  ConsumerState<CreateProductoScreen> createState() =>
      _CreateProductoScreenState();
}

class _CreateProductoScreenState extends ConsumerState<CreateProductoScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final registerProductoController =
        ref.watch(registerProductoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.white),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: const BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                      ),
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        registerProductoController.nombreController.clear();
                        registerProductoController.precioController.clear();
                        registerProductoController.tiempoPreparacionController
                            .clear();
                        registerProductoController.ingredientesController.clear();
                        ref.read(profileImageProvider.notifier).clearImage();
          
                        context
                            .push('/admin/manage/producto/create-item-productos');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Nuevo Producto',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const ListCardsProducts(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
