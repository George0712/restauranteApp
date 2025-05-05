// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
import 'package:restaurante_app/data/providers/login/login_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateItemProductoScreen extends ConsumerStatefulWidget {
  const CreateItemProductoScreen({super.key});

  @override
  ConsumerState<CreateItemProductoScreen> createState() =>
      _CreateItemProductoScreenState();
}

class _CreateItemProductoScreenState
    extends ConsumerState<CreateItemProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  bool? isAvailable = true;

  @override
  void initState() {
    super.initState();
    final registerProductController =
        ref.read(registerProductoControllerProvider);
    registerProductController.nombreController.addListener(_validateFields);
    registerProductController.precioController.addListener(_validateFields);
    registerProductController.tiempoPreparacionController
        .addListener(_validateFields);
    registerProductController.ingredientesController
        .addListener(_validateFields);
  }

  void _validateFields() {
    if (!mounted) return;
    final registerProductController =
        ref.read(registerProductoControllerProvider);
    final isValid = registerProductController.areFieldsValid();
    ref.read(fieldsValidProvider.notifier).state = isValid;
  }

  @override
  Widget build(BuildContext context) {
    final registerProductController =
        ref.watch(registerProductoControllerProvider);
    final categoryAsync = ref.watch(categoryDisponibleProvider);
    final areFieldsValid = ref.watch(fieldsValidProvider);
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
                AppStrings.createNewProduct,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.createNewProductDescription,
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
                      backgroundImage:
                          profileImage != null ? FileImage(profileImage) : null,
                      child: profileImage == null
                          ? Iconify(Bi.box_fill,
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
                        controller: registerProductController.nombreController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingrese un nombre'
                            : AppConstants.nameRegex.hasMatch(value)
                                ? null
                                : 'Este campo no es válido'),
                    const SizedBox(height: 12),
                    CustomInputField(
                      hintText: AppStrings.price,
                      keyboardType: TextInputType.number,
                      controller: registerProductController.precioController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Por favor ingrese un valor'
                          : AppConstants.priceRegex.hasMatch(value)
                              ? null
                              : 'Este campo no es válida',
                    ),
                    const SizedBox(height: 12),
                    // Categoría - Dropdown
                    categoryAsync.when(
                      data: (categories) {
                        return DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            hintText: AppStrings.category,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide(
                                color: theme.primaryColor.withAlpha(200),
                              ),
                            ),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id, // O el id si prefieres
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Seleccione una categoría'
                              : null,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) =>
                          const Text('Error cargando categorías'),
                    ),
                    const SizedBox(height: 12),
                    CustomInputField(
                      hintText: AppStrings.timePreparation,
                      controller:
                          registerProductController.tiempoPreparacionController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el tiempo de preapación'
                          : AppConstants.timePreparationRegex.hasMatch(value)
                              ? null
                              : 'Este campo no es válido',
                    ),
                    const SizedBox(height: 12),
                    CustomInputField(
                      hintText: AppStrings.ingredients,
                      controller:
                          registerProductController.ingredientesController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese al menos 3 ingredientes'
                          : AppConstants.ingredientesRegex.hasMatch(value)
                              ? null
                              : 'Este campo no es válido',
                    ),
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
                            await registerProductController.registrarProducto(
                                ref,
                                nombre: registerProductController
                                    .nombreController.text.trim(),
                                precio: double.parse(registerProductController
                                    .precioController.text),
                                tiempoPreparacion: int.parse(
                                    registerProductController
                                        .tiempoPreparacionController.text),
                                ingredientes: registerProductController
                                    .ingredientesController.text.trim(),
                                categoria: selectedCategory!,
                                disponible: isAvailable!,
                                foto: profileImage?.path ?? '');
                              SnackbarHelper.showSnackBar(
                                  'Producto agregado correctamente');
                            context.pop();
                            context.push('/admin/manage/producto/productos');
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
