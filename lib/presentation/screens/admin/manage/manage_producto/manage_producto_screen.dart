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
  ConsumerState<ManageProductoScreen> createState() => _ManageProductoScreenState();
}

class _ManageProductoScreenState extends ConsumerState<ManageProductoScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: isTablet
                    ? const EdgeInsets.symmetric(vertical: 40, horizontal: 80)
                    : const EdgeInsets.all(16), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.manageProduct,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.manageProductDescription,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
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
                    onTap: () {
                      context.push('/admin/manage/producto/productos');
                    },
                  ),
                  OptionButtonCard(
                    icon: const Iconify(Bx.category, size: 40),
                    text: AppStrings.categorysTitle,
                    onTap: () {
                      context.push('/admin/manage/producto/manage-categorys');
                    },
                  ),
                  OptionButtonCard(
                    icon: const Iconify(Mdi.burger_plus, size: 40),
                    text: AppStrings.additionalsTitle,
                    onTap: () {
                      context.push('/admin/manage/producto/create-additionals');
                    },
                  ),
                  OptionButtonCard(
                    icon: const Iconify(Ion.fast_food, size: 40),
                    text: AppStrings.combosTitle,
                    onTap: () {
                      context.push('/admin/manage/producto/create-additionals');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
