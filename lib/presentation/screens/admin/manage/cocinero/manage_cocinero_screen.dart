import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/list_cards_user.dart';

class ManageCocineroScreen extends ConsumerStatefulWidget {
  const ManageCocineroScreen({super.key});

  @override
  ConsumerState<ManageCocineroScreen> createState() => _ManageCocineroScreenState();
}

class _ManageCocineroScreenState extends ConsumerState<ManageCocineroScreen> {
  final rol = 'cocinero';
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider(rol));
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
          padding: isTablet
                    ? const EdgeInsets.symmetric(vertical: 20, horizontal: 60)
                    : const EdgeInsets.all(16), 
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
              const SizedBox(height: 24),
              ListCardsUsers(usersAsync: usersAsync, rol: rol),
            ],
          ),
        ),
      ),
    );
  }
}