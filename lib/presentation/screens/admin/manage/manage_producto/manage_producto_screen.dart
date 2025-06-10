import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/presentation/widgets/option_button_card.dart';

class ManageProductoScreen extends ConsumerStatefulWidget {
  const ManageProductoScreen({super.key});

  @override
  ConsumerState<ManageProductoScreen> createState() =>
      _ManageProductoScreenState();
}

class _ManageProductoScreenState extends ConsumerState<ManageProductoScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
          child: SingleChildScrollView(
            padding: isTablet
                ? const EdgeInsets.symmetric(vertical: 100, horizontal: 80)
                : const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.manageProduct,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.manageProductDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    OptionButtonCard(
                      icon: const Iconify(Bi.box, size: 42),
                      text: AppStrings.productsTitle,
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        context.push('/admin/manage/producto/productos');
                      },
                    ),
                    OptionButtonCard(
                      icon: const Iconify(Bx.category, size: 40),
                      text: AppStrings.categorysTitle,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        context.push('/admin/manage/producto/manage-categorys');
                      },
                    ),
                    OptionButtonCard(
                      icon: const Iconify(Mdi.burger_plus, size: 40),
                      text: AppStrings.additionalsTitle,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        context
                            .push('/admin/manage/producto/manage-additionals');
                      },
                    ),
                    // Botón de combos deshabilitado
                    Stack(
                      children: [
                        OptionButtonCard(
                          icon: const Iconify(Ion.fast_food, size: 40),
                          text: AppStrings.combosTitle,
                          color: Colors.grey.shade600, // Color gris para indicar deshabilitado
                          onTap: () {
                            // No hace nada o muestra un mensaje
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta función no está disponible'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        // Overlay con candado y listón
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Próximamente',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Listón diagonal (opcional)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomPaint(
                              painter: DiagonalStripePainter(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Painter para crear el listón diagonal
class DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Dibuja una línea diagonal desde la esquina superior izquierda a la inferior derecha
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}