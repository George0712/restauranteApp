import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    final List<Map<String, String>> dashboardData = [
      {'title': 'Ventas Totales', 'value': '\$0'},
      {'title': 'Órdenes', 'value': '0'},
      {'title': 'Clientes', 'value': '0'},
      {'title': 'Productos', 'value': '0'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Center(
              child: Icon(
                Icons.person,
                size: 35,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        title: const Text(
          'Nombre de Usuario',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VISTA GENERAL',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Dashboard Cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width > 600
                    ? 4
                    : 2, // 4 columnas en tablet, 2 en móvil
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2, // Ancho / Alto de las cards
              ),
              itemBuilder: (context, index) {
                final item = dashboardData[index];
                return DashboardCard(
                  title: item['title']!,
                  value: item['value']!,
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'OPCIONES PRINCIPALES',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount:
                  size.width > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                OptionButtonCard(
                  icon: Icons.restaurant_menu,
                  text: 'Productos',
                  onTap: () {
                    context.push('/admin/manage/producto');
                  },
                ),
                OptionButtonCard(
                  icon: Icons.receipt_long,
                  text: 'Meseros',
                  onTap: () {
                    context.push('/admin/manage/mesero');
                  },
                ),
                OptionButtonCard(
                  icon: Icons.people,
                  text: 'Cocineros',
                  onTap: () {
                    context.push('/admin/manage/cocinero');
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'OTRAS OPCIONES',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount:
                  size.width > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                OptionButtonCard(
                  icon: Icons.receipt_long,
                  text: 'Pedidos',
                  onTap: () {
                    context.push('/mesero/home');
                  },
                ),
                OptionButtonCard(
                  icon: Icons.settings,
                  text: 'Configuración',
                  onTap: () {
                    context.push('/admin/settings');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
