// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/providers/admin/permission_service.dart';
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
    ref.read(isValidFieldsProvider.notifier).state = isValid;
  }

  // Método principal para manejar la selección de imagen
  Future<void> _handleImageSelection() async {
    try {
      await PermissionService.showImageSourceDialog(
        context, 
        (bool fromCamera) async {
          final imageNotifier = ref.read(profileImageProvider.notifier);
          
          if (fromCamera) {
            await imageNotifier.pickImageFromCamera();
          } else {
            await imageNotifier.pickImage(); // Método existente para galería
          }
        }
      );
    } catch (e) {
      SnackbarHelper.showSnackBar('Error al seleccionar imagen: $e');
    }
  }

  // Método para mostrar opciones adicionales (opcional)
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Imagen del Producto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Seleccionar de Galería'),
                subtitle: const Text('Elegir una imagen existente'),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Tomar Foto'),
                subtitle: const Text('Capturar con la cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (ref.watch(profileImageProvider) != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Quitar Imagen'),
                  subtitle: const Text('Eliminar imagen actual'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Métodos individuales para cada acción
  Future<void> _selectFromGallery() async {
    try {
      final imageNotifier = ref.read(profileImageProvider.notifier);
      await imageNotifier.pickImage();
    } catch (e) {
      SnackbarHelper.showSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imageNotifier = ref.read(profileImageProvider.notifier);
      await imageNotifier.pickImageFromCamera();
    } catch (e) {
      SnackbarHelper.showSnackBar('Error al tomar foto: $e');
    }
  }

  void _removeImage() {
    final imageNotifier = ref.read(profileImageProvider.notifier);
    imageNotifier.clearImage();
    SnackbarHelper.showSnackBar('Imagen eliminada');
  }

  @override
  Widget build(BuildContext context) {
    final registerProductController =
        ref.watch(registerProductoControllerProvider);
    final categoryAsync = ref.watch(categoryDisponibleProvider);
    final areFieldsValid = ref.watch(isValidFieldsProvider);
    final profileImage = ref.watch(profileImageProvider);
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
                AppStrings.createNewProduct,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.createNewProductDescription,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // Foto de perfil (mejorada)
                Center(
                  child: GestureDetector(
                    onTap: _handleImageSelection, // También permite tap en toda la imagen
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withAlpha(40),
                            backgroundImage: profileImage != null 
                                ? FileImage(profileImage) 
                                : null,
                            child: profileImage == null
                                ? Iconify(
                                    Bi.box_fill,
                                    size: 50,
                                    color: theme.primaryColor.withAlpha(200),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _handleImageSelection,
                            onLongPress: _showImageOptions, // Opción adicional con long press
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: theme.primaryColor,
                                child: Icon(
                                  profileImage == null 
                                      ? Icons.add_a_photo 
                                      : Icons.edit,
                                  size: 18, 
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Indicador de que hay imagen
                        if (profileImage != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Texto informativo debajo de la imagen
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    profileImage == null 
                        ? 'Toca para agregar una imagen del producto'
                        : 'Toca para cambiar la imagen',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
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
                                    const Text('Sí', style: TextStyle(color: Colors.white)),
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
                                    const Text('No', style: TextStyle(color: Colors.white)),
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
                      backgroundColor: const Color(0xFF8B5CF6),
                      disabledBackgroundColor: const Color(0xFF8B5CF6).withAlpha(100),
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
      ),
    );
  }
}
