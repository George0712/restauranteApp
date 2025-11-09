import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/list_cards_user.dart';

class ManageCocineroScreen extends ConsumerStatefulWidget {
  const ManageCocineroScreen({super.key});

  @override
  ConsumerState<ManageCocineroScreen> createState() =>
      _ManageCocineroScreenState();
}

class _ManageCocineroScreenState extends ConsumerState<ManageCocineroScreen> {
  final rol = 'cocinero';

  @override
  Widget build(BuildContext context) {
    final registerUserController = ref.watch(registerUserControllerProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
              Color(0xFF16213E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.manageCook,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.manageCookDescription,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        registerUserController.nombreController.clear();
                        registerUserController.apellidosController.clear();
                        registerUserController.telefonoController.clear();
                        registerUserController.direccionController.clear();
                        registerUserController.userNameController.clear();
                        registerUserController.emailController.clear();
                        registerUserController.passwordController.clear();
                        context.push('/admin/manage/cocinero/create-cocinero');
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
                          SizedBox(width: 8),
                          Text(
                            'Nuevo Cocinero',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListCardsUsers(rol: rol),
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
