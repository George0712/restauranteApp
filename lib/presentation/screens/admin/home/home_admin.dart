import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
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

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 60,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: Padding(
            padding: const EdgeInsets.all(10),
            child: GestureDetector(
              onTap: () {
                context.push('/admin/settings');
              },
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
          ),
          title: Text(
            '',
            style: TextStyle(color: theme.primaryColor),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.dashboard,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Dashboard Cards
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2,
                ),
                children: [
                  DashboardCard(
                    title: 'Ventas Totales',
                    countProvider: totalVentasProvider,
                  ),
                  DashboardCard(
                    title: 'Órdenes',
                    countProvider: ordenesProvider,
                  ),
                  DashboardCard(
                    title: 'Clientes',
                    countProvider: clientesProvider,
                  ),
                  DashboardCard(
                    title: 'Productos',
                    countProvider: productosProviderCount,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                AppStrings.mainOptions,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    icon: const Iconify(Bi.box, size: 40),
                    text: AppStrings.productsTitle,
                    onTap: () {
                      context.push('/admin/manage/manage-productos');
                    },
                  ),
                  OptionButtonCard(
                    icon: const Iconify(
                      Ri.user_line,
                      size: 40,
                    ),
                    text: AppStrings.waitersTitle,
                    onTap: () {
                      context.push('/admin/manage/mesero');
                    },
                  ),
                  OptionButtonCard(
                    icon: const Iconify(Ri.user_line, size: 40),
                    text: AppStrings.cooksTitle,
                    onTap: () {
                      context.push('/admin/manage/cocinero');
                    },
                  ),
                  OptionButtonCard(
                    icon: const Iconify(Ci.settings, size: 40),
                    text: AppStrings.settingsTitle,
                    onTap: () {
                      context.push('/admin/settings');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
