// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateItemCategoryScreen extends ConsumerStatefulWidget {
  const CreateItemCategoryScreen({super.key});

  @override
  ConsumerState<CreateItemCategoryScreen> createState() =>
      _CreateItemCategoryScreenState();
}

class _CreateItemCategoryScreenState
    extends ConsumerState<CreateItemCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool? isAvailable = true;

  @override
  void initState() {
    super.initState();
    final registerCategoryController =
        ref.read(registerCategoryControllerProvider);
    registerCategoryController.nombreController.addListener(_validateFields);
  }

  void _validateFields() {
    if (!mounted) return;
    final registerCategoryController =
        ref.read(registerCategoryControllerProvider);
    final isValid = registerCategoryController.areFieldsValid();
    ref.read(isValidFieldsProvider.notifier).state = isValid;
  }

  @override
  Widget build(BuildContext context) {
    final registerCategoryController =
        ref.watch(registerCategoryControllerProvider);
    final areFieldsValid = ref.watch(isValidFieldsProvider);
    final profileImage = ref.watch(profileImageProvider);
    final imageNotifier = ref.read(profileImageProvider.notifier);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: theme.primaryColor,
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
                AppStrings.registerCategory,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.registerCategoryDescription,
                style: TextStyle(fontSize: 16, color: theme.primaryColor),
              ),
              const SizedBox(height: 24),
          
              // Foto de perfil (opcional)
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.primaryColor.withAlpha(50),
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage)
                          : null,
                      child: profileImage == null
                          ? Icon(Icons.category,
                              size: 50,
                              color: theme.primaryColor.withAlpha(200))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                          onPressed: () async {
                            await imageNotifier.pickImage();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
          
              // Inputs de texto
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomInputField(
                        hintText: AppStrings.name,
                        controller:
                            registerCategoryController.nombreController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingrese un nombre'
                            : AppConstants.nameRegex.hasMatch(value)
                                ? null
                                : 'El nombre no es válido'),
                    const SizedBox(height: 12),
                    // Checkbox de disponibilidad
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Disponible:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Radio<bool>(
                                      value: true,
                                      groupValue: isAvailable,
                                      onChanged: (value) {
                                        setState(() {
                                          isAvailable = value;
                                        });
                                      },
                                    ),
                                    const Text('Sí'),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Radio<bool>(
                                      value: false,
                                      groupValue: isAvailable,
                                      onChanged: (value) {
                                        setState(() {
                                          isAvailable = value;
                                        });
                                      },
                                    ),
                                    const Text('No'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          
              const SizedBox(height: 32),
          
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      registerCategoryController.nombreController.clear();
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: theme.primaryColor),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: areFieldsValid &&
                            (_formKey.currentState?.validate() ?? false)
                        ? () async {
                            final result = await registerCategoryController
                                .registrarCategoria(
                              ref,
                              nombre: registerCategoryController
                                  .nombreController.text,
                              disponible: isAvailable!,
                              foto: profileImage?.path ?? '',
                            );
          
                            if (result == null) {
                              // Registro exitoso
                              SnackbarHelper.showSnackBar('Categoría Agregada');
                              context.pop();
                              context.push(
                                  '/admin/manage/producto/manage-categorys');
                            } else {
                              SnackbarHelper.showSnackBar(
                                  'Error al registrar categoría');
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                    ),
                    child: const Text(
                      'Agregar',
                      style: TextStyle(color: Colors.white),
                    ),
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
