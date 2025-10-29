// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/category_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateItemCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? category; // null para crear, categoría para editar

  const CreateItemCategoryScreen({Key? key, this.category}) : super(key: key);

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
    final controller = ref.read(registerCategoryControllerProvider);

    if (widget.category != null) {
      controller.nombreController.text = widget.category!.name;
      isAvailable = widget.category!.disponible;
      // Si usas imagenes: inicializa tambien provider para imagen aquí si es necesario
    } else {
      isAvailable = true; // Default para nueva categoría
    }

    controller.nombreController.addListener(_validateFields);
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
    //final imageNotifier = ref.read(profileImageProvider.notifier);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: isTablet
                ? const EdgeInsets.symmetric(vertical: 100, horizontal: 60)
                : const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.registerCategory,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.registerCategoryDescription,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // Foto de perfil (opcional)
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withAlpha(40),
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? Icon(Icons.category,
                                size: 50,
                                color: theme.primaryColor.withAlpha(200))
                            : null,
                      ),
                      /*Positioned(
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
                      ),*/
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
                          isRequired: true,
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Por favor ingrese un nombre'
                              : AppConstants.nameRegex.hasMatch(value)
                                  ? null
                                  : 'El nombre no es válido'),
                      const SizedBox(height: 16),
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
                                color: Colors.white,
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
                                        activeColor: Colors.green,
                                      ),
                                      const Text('Sí',
                                          style:
                                              TextStyle(color: Colors.white)),
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
                                        activeColor: Colors.red,
                                      ),
                                      const Text('No',
                                          style:
                                              TextStyle(color: Colors.white)),
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
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: areFieldsValid &&
                              (_formKey.currentState?.validate() ?? false)
                          ? () async {
                              final controller = registerCategoryController;
                              String? result;
                              if (widget.category == null) {
                                // Crear nueva
                                result = await controller.registrarCategoria(
                                  ref,
                                  nombre: controller.nombreController.text,
                                  disponible: isAvailable!,
                                  foto: profileImage?.path ?? '',
                                );
                              } else {
                                // Actualizar existente
                                result = await controller.actualizarCategoria(
                                  ref,
                                  id: widget.category!.id,
                                  nombre: controller.nombreController.text,
                                  disponible: isAvailable!,
                                  foto: profileImage?.path ??
                                      '', // o el valor anterior si no cambió
                                );
                              }

                              if (result == null) {
                                SnackbarHelper.showSuccess(
                                    widget.category == null
                                        ? 'Categoría agregada exitosamente'
                                        : 'Categoría actualizada exitosamente');
                                context.pop();
                              } else {
                                SnackbarHelper.showError('Error: $result');
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        disabledBackgroundColor:
                            const Color(0xFF8B5CF6).withAlpha(100),
                      ),
                      child: Text(
                        widget.category == null ? 'Agregar' : 'Actualizar',
                        style: const TextStyle(color: Colors.white),
                      ),
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
