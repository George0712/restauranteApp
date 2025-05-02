import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';

class ManageCocineroScreen extends ConsumerStatefulWidget {
  const ManageCocineroScreen({super.key});

  @override
  ConsumerState<ManageCocineroScreen> createState() => _ManageMeseroScreenState();
}

class _ManageMeseroScreenState extends ConsumerState<ManageCocineroScreen> {
  @override
  Widget build(BuildContext context) {
    final registerUserController =
        ref.watch(registerUserControllerProvider);
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
          child: Container(
            width: isTablet ? 500 : double.infinity,
            margin: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 16,
              vertical: isTablet ? 20 : 10,
            ),
            padding: const EdgeInsets.all(20),
            decoration: isTablet
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                      ),
                    ],
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.manageCook,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.manageCookDescription,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Botones
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
                    backgroundColor: Colors.black,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Nuevo Cocinero', style: TextStyle(color: Colors.white),),
                    ],
                  ),

                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}