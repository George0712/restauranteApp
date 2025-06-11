import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:iconify_flutter/icons/ri.dart';

import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/dashboard_card.dart';
import 'package:restaurante_app/presentation/widgets/option_button_card.dart';

class HomeAdminScreen extends ConsumerStatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  ConsumerState<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends ConsumerState<HomeAdminScreen> {
  @override
  Widget build(BuildContext context) {
     final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final theme = Theme.of(context);

    return Scaffold(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.dashboard,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet ? 4 : 2,
                  childAspectRatio: isTablet ? 1.2 : 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    buildNeonStatCard(
                      ref,
                      'Ventas',
                      'Totales',
                      totalVentasProvider,
                      const Color(0xFF00D4AA),
                      Icons.monetization_on,
                    ),
                    buildNeonStatCard(
                      ref,
                      'Órdenes',
                      'Activas',
                      ordenesProvider,
                      const Color(0xFF6366F1),
                      Icons.receipt,
                    ),
                    buildNeonStatCard(
                      ref,
                      'Clientes',
                      'Registrados',
                      clientesProvider,
                      const Color(0xFFFF6B6B),
                      Icons.group,
                    ),
                    buildNeonStatCard(
                      ref,
                      'Productos',
                      'Disponibles',
                      productosProviderCount,
                      const Color(0xFFFFD23F),
                      Icons.inventory_2,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  AppStrings.manageOptions,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    OptionButtonCard(
                      icon: const Iconify(Bi.box, size: 32),
                      text: AppStrings.productsTitle,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.push('/admin/manage/manage-productos'),
                    ),
                    OptionButtonCard(
                      icon: const Iconify(Ri.user_line, size: 32),
                      text: AppStrings.waitersTitle,
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.push('/admin/manage/mesero'),
                    ),
                    OptionButtonCard(
                      icon: const Iconify(Ri.user_line, size: 32),
                      text: AppStrings.cooksTitle,
                      color: const Color(0xFF10B981),
                      onTap: () => context.push('/admin/manage/cocinero'),
                    ),
                    OptionButtonCard(
                      icon: const Iconify(Ci.settings, size: 32),
                      text: AppStrings.settingsTitle,
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.push('/admin/settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
