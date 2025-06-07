import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:restaurante_app/presentation/widgets/enhanced_option_card.dart';
import 'package:restaurante_app/presentation/widgets/navbar_item.dart';
import 'package:restaurante_app/presentation/widgets/quick_stat_item.dart';

class HomeMeseroScreen extends ConsumerStatefulWidget {
  const HomeMeseroScreen({super.key});

  @override
  ConsumerState<HomeMeseroScreen> createState() => _HomeMeseroScreenState();
}

class _HomeMeseroScreenState extends ConsumerState<HomeMeseroScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
            child: Hero(
              tag: 'profile_avatar',
              child: GestureDetector(
                onTap: () {
                  context.push('/admin/settings');
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.8),
                    child: const Icon(
                      Icons.person,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 20),
              child: IconButton(
                onPressed: () {
                  // Añadir funcionalidad de notificaciones
                },
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Fondo con gradiente y overlay de imagen
            Container(
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
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'lib/core/assets/bg-mesero.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Contenido principal
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y bienvenida
                  Padding(
                    padding: EdgeInsets.only(
                        left: isTablet ? 40 : 24,
                        right: isTablet ? 40 : 24,
                        top: 20,
                        bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido!',
                          style: TextStyle(
                            fontSize: isTablet ? 36 : 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿Qué te gustaría hacer hoy?',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Resumen rápido
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40 : 24,
                      vertical: 20,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          quickStatItem('Activas', '0', Icons.table_restaurant),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withAlpha(80),
                          ),
                          quickStatItem(
                              'Pendientes', '0', Icons.pending_actions),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withAlpha(80),
                          ),
                          quickStatItem('Total', '\$0K', Icons.attach_money),
                        ],
                      ),
                    ),
                  ),

                  // Grid de opciones principal
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 30 : 16,
                      ),
                      child: GridView.count(
                        physics: const BouncingScrollPhysics(),
                        crossAxisCount: isTablet ? 4 : 2,
                        crossAxisSpacing: isTablet ? 20 : 12,
                        mainAxisSpacing: isTablet ? 20 : 12,
                        childAspectRatio: 1.0,
                        children: [
                          _buildEnhancedOptionCard(
                            icon: const Iconify(Ri.restaurant_2_fill, size: 50),
                            text: 'Mesas',
                            description: 'Gestionar todas las mesas',
                            color: const Color(0xFF5E35B1),
                            onTap: () {
                              context.push('/mesero/pedidos/mesas');
                            },
                          ),
                          _buildEnhancedOptionCard(
                            icon: const Iconify(Ion.fast_food, size: 50),
                            text: 'Para llevar',
                            description: 'Pedidos para recoger',
                            color: const Color(0xFF00897B),
                            onTap: () {},
                          ),
                          _buildEnhancedOptionCard(
                            icon: const Iconify(Mdi.delivery_dining, size: 50),
                            text: 'Domicilios',
                            description: 'Entregas a domicilio',
                            color: const Color(0xFF5D4037),
                            onTap: () {},
                          ),
                          _buildEnhancedOptionCard(
                            icon: const Iconify(Bx.bxs_receipt, size: 50),
                            text: 'Historial',
                            description: 'Pedidos anteriores',
                            color: const Color(0xFF0097A7),
                            onTap: () {},
                          ),
                          if (isTablet) ...[
                            _buildEnhancedOptionCard(
                              icon: const Icon(Icons.menu_book_rounded,
                                  size: 50, color: Colors.white),
                              text: 'Menú',
                              description: 'Ver catálogo',
                              color: const Color(0xFFE64A19),
                              onTap: () {},
                            ),
                            _buildEnhancedOptionCard(
                              icon: const Icon(Icons.assessment_rounded,
                                  size: 50, color: Colors.white),
                              text: 'Reportes',
                              description: 'Estadísticas y ventas',
                              color: const Color(0xFF7CB342),
                              onTap: () {},
                            ),
                            _buildEnhancedOptionCard(
                              icon: const Icon(Icons.event_note_rounded,
                                  size: 50, color: Colors.white),
                              text: 'Reservas',
                              description: 'Administrar reservaciones',
                              color: const Color(0xFF039BE5),
                              onTap: () {},
                            ),
                            _buildEnhancedOptionCard(
                              icon: const Icon(Icons.chat_rounded,
                                  size: 50, color: Colors.white),
                              text: 'Soporte',
                              description: 'Ayuda y asistencia',
                              color: const Color(0xFF546E7A),
                              onTap: () {},
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),

                  // Barra de navegación inferior
                  if (!isTablet)
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          navbarItem(Icons.home_rounded, true, context),
                          navbarItem(Icons.fastfood_rounded, false, context),
                          navbarItem(Icons.assignment_rounded, false, context),
                          navbarItem(Icons.settings_rounded, false, context),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedOptionCard({
    required Widget icon,
    required String text,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return EnhancedOptionCard(
      icon: icon,
      text: text,
      description: description,
      color: color,
      onTap: onTap,
    );
  }
}
