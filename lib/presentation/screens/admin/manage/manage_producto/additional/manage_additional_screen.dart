import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/list_cards_additionals.dart';

class ManageAdditionalScreen extends ConsumerStatefulWidget {
  const ManageAdditionalScreen({super.key});

  @override
  ConsumerState<ManageAdditionalScreen> createState() => _ManageAdditionalScreenState();
}

class _ManageAdditionalScreenState extends ConsumerState<ManageAdditionalScreen> {
  final rol = 'mesero';
  @override
  Widget build(BuildContext context) {
    final registerAdditionalController = ref.watch(registerAdditionalControllerProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.black54),
          onPressed: () => context.pop(),
        ),
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
                AppStrings.manageAdditional,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.manageAdditionalDescription,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
          
              // Botones
              ElevatedButton(
                onPressed: () {
                  registerAdditionalController.nombreController.clear();
                  registerAdditionalController.precioController.clear();
                  context.push('/admin/manage/additional/create-item-additionals');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Nuevo Adicional',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const ListCardsAdditionals(),
            ],
          ),
        ),
      ),
    );
  }
}