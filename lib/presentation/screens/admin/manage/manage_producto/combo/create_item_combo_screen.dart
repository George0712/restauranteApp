import 'dart:io';

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
import 'package:restaurante_app/presentation/providers/images/cloudinary_service.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateItemComboScreen extends ConsumerStatefulWidget {
  final String? comboId;

  const CreateItemComboScreen({super.key, this.comboId});

  @override
  ConsumerState<CreateItemComboScreen> createState() =>
      _CreateItemComboScreenState();
}

class _CreateItemComboScreenState extends ConsumerState<CreateItemComboScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  bool? isAvailable = true;
  bool _isLoading = false;
  bool _isLoadingData = false;

  bool get isEditMode => widget.comboId != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      // Modo edición
      final editComboController = ref.read(editComboControllerProvider.notifier);
      editComboController.nombreController.addListener(_validateFields);
      editComboController.precioController.addListener(_validateFields);
      editComboController.tiempoPreparacionController.addListener(_validateFields);

      // Cargar datos del combo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadComboData();
      });
    } else {
      // Modo creación: limpiar campos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearAllFields();
      });

      final registerComboController = ref.read(registerComboControllerProvider);
      registerComboController.nombreController.addListener(_validateFields);
      registerComboController.precioController.addListener(_validateFields);
      registerComboController.tiempoPreparacionController.addListener(_validateFields);
    }
  }

  // Método para limpiar todos los campos
  void _clearAllFields() {
    final registerComboController = ref.read(registerComboControllerProvider);
    registerComboController.nombreController.clear();
    registerComboController.precioController.clear();
    registerComboController.tiempoPreparacionController.clear();
    ref.read(selectedComboProductsProvider.notifier).state = [];
    ref.read(profileImageProvider.notifier).clearImage();
    ref.read(isValidFieldsProvider.notifier).state = false;
    setState(() {
      isAvailable = true;
    });
  }

  Future<void> _loadComboData() async {
    if (widget.comboId == null) return;

    setState(() => _isLoadingData = true);

    try {
      final comboAsync = ref.read(comboByIdProvider(widget.comboId!));

      await comboAsync.when(
        data: (combo) async {
          if (combo != null) {
            final editComboController = ref.read(editComboControllerProvider.notifier);
            editComboController.loadComboData(combo);

            // Set availability
            isAvailable = combo.disponible ?? true;

            // Set selected products
            ref.read(selectedComboProductsProvider.notifier).state = combo.products;

            // If there's a photo URL, we'll keep it for reference but won't load it into the image picker
            // Users can replace it by selecting a new image
          }
        },
        loading: () async {},
        error: (error, stack) async {
          SnackbarHelper.showError('Error al cargar combo: $error');
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Error al cargar datos del combo: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _validateFields() {
    if (!mounted) return;

    if (isEditMode) {
      final editComboController = ref.read(editComboControllerProvider.notifier);
      final isValid = editComboController.areFieldsValid();
      ref.read(isValidFieldsProvider.notifier).state = isValid;
    } else {
      final registerComboController = ref.read(registerComboControllerProvider);
      final isValid = registerComboController.areFieldsValid();
      ref.read(isValidFieldsProvider.notifier).state = isValid;
    }
  }

  Future<void> _handleImageSelection() async {
    try {
      await PermissionService.showImageSourceDialog(context,
          (bool fromCamera) async {
        final imageNotifier = ref.read(profileImageProvider.notifier);

        if (fromCamera) {
          await imageNotifier.pickImageFromCamera();
        } else {
          await imageNotifier.pickImage();
        }
      });
    } catch (e) {
      SnackbarHelper.showError('Error al seleccionar imagen: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
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
                'Imagen del Combo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF34D399)),
                title: const Text('Seleccionar de Galería', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Elegir una imagen existente', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF34D399)),
                title: const Text('Tomar Foto', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Capturar con la cámara', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (ref.watch(profileImageProvider) != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                  title: const Text('Quitar Imagen', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Eliminar imagen actual', style: TextStyle(color: Colors.white70)),
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

  Future<void> _selectFromGallery() async {
    try {
      final imageNotifier = ref.read(profileImageProvider.notifier);
      await imageNotifier.pickImage();
    } catch (e) {
      SnackbarHelper.showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imageNotifier = ref.read(profileImageProvider.notifier);
      await imageNotifier.pickImageFromCamera();
    } catch (e) {
      SnackbarHelper.showError('Error al tomar foto: $e');
    }
  }

  void _removeImage() {
    final imageNotifier = ref.read(profileImageProvider.notifier);
    imageNotifier.clearImage();
    SnackbarHelper.showInfo('Imagen eliminada');
  }

  Future<void> _saveCombo() async {
    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showWarning('Por favor completa todos los campos requeridos');
      return;
    }

    final selectedProducts = ref.read(selectedComboProductsProvider);
    if (selectedProducts.isEmpty) {
      SnackbarHelper.showWarning('Debes seleccionar al menos un producto para el combo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileImage = ref.read(profileImageProvider);
      String? photoUrl;

      if (isEditMode) {
        // Modo edición
        final editComboController = ref.read(editComboControllerProvider.notifier);
        final comboAsync = ref.read(comboByIdProvider(widget.comboId!));

        // Get current photo URL if no new image selected
        String? currentPhotoUrl;
        await comboAsync.when(
          data: (combo) async {
            currentPhotoUrl = combo?.photo;
          },
          loading: () async {},
          error: (_, __) async {},
        );

        // Si hay nueva imagen, subirla a Cloudinary
        if (profileImage != null) {
          final file = File(profileImage.path);
          if (await file.exists()) {
            photoUrl = await CloudinaryService.uploadImage(file);
            if (photoUrl == null) {
              throw Exception('Error al subir la imagen');
            }
          }
        } else {
          // Mantener la foto actual si no hay nueva imagen
          photoUrl = currentPhotoUrl;
        }

        // Actualizar el combo
        final error = await editComboController.updateCombo(
          ref,
          comboId: widget.comboId!,
          nombre: editComboController.nombreController.text.trim(),
          precio: double.parse(editComboController.precioController.text.trim()),
          tiempoPreparacion: int.parse(editComboController.tiempoPreparacionController.text.trim()),
          productos: selectedProducts,
          disponible: isAvailable ?? true,
          newPhoto: photoUrl,
        );

        setState(() => _isLoading = false);

        if (error == null) {
          SnackbarHelper.showSuccess('Combo actualizado exitosamente');
      
          if (mounted) {
            context.pop();
          }
        } else {
          SnackbarHelper.showError('Error al actualizar combo: $error');
        }
      } else {
        // Modo creación
        final registerComboController = ref.read(registerComboControllerProvider);

        // Si hay imagen, subirla a Cloudinary
        if (profileImage != null) {
          final file = File(profileImage.path);
          if (await file.exists()) {
            photoUrl = await CloudinaryService.uploadImage(file);
            if (photoUrl == null) {
              throw Exception('Error al subir la imagen');
            }
          }
        }

        // Registrar el combo
        final error = await registerComboController.registrarCombo(
          ref,
          nombre: registerComboController.nombreController.text.trim(),
          precio: double.parse(registerComboController.precioController.text.trim()),
          tiempoPreparacion: int.parse(registerComboController.tiempoPreparacionController.text.trim()),
          productos: selectedProducts,
          disponible: isAvailable.toString(),
          foto: photoUrl,
        );

        setState(() => _isLoading = false);

        if (error == null) {
          SnackbarHelper.showSuccess('Combo registrado exitosamente');

          // Limpiar campos y productos seleccionados
          _clearAllFields();

          // Esperar un momento para que se vea el mensaje
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            context.pop();
          }
        } else {
          SnackbarHelper.showError('Error al registrar combo: $error');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      SnackbarHelper.showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use appropriate controller based on mode
    final registerComboController = isEditMode ? null : ref.watch(registerComboControllerProvider);
    final editComboController = isEditMode ? ref.watch(editComboControllerProvider.notifier) : null;

    // Get the active controller's text controllers
    final nombreController = isEditMode
        ? editComboController!.nombreController
        : registerComboController!.nombreController;
    final precioController = isEditMode
        ? editComboController!.precioController
        : registerComboController!.precioController;
    final tiempoPreparacionController = isEditMode
        ? editComboController!.tiempoPreparacionController
        : registerComboController!.tiempoPreparacionController;

    final areFieldsValid = ref.watch(isValidFieldsProvider);
    final profileImage = ref.watch(profileImageProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (_isLoadingData) {
      return Scaffold(
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
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF59E0B),
            ),
          ),
        ),
      );
    }

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
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditMode ? 'Editar Combo' : AppStrings.createNewCombo,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.createNewComboDescription,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
              
                    // Foto de perfil (opcional)
                    Center(
                      child: GestureDetector(
                        onTap: _handleImageSelection,
                        onLongPress: _showImageOptions,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white.withAlpha(40),
                              backgroundImage: profileImage != null
                                  ? FileImage(profileImage)
                                  : null,
                              child: profileImage == null
                                  ? Iconify(Bi.box_fill,
                                      size: 50,
                                      color: theme.primaryColor.withAlpha(200))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _handleImageSelection,
                                onLongPress: _showImageOptions,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.primaryColor,
                                  child: Icon(
                                    profileImage == null ? Icons.add_a_photo : Icons.edit,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                              controller: nombreController,
                              isRequired: true,
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF34D399),
                                size: 22,
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Por favor ingrese un nombre'
                                  : AppConstants.nameRegex.hasMatch(value)
                                      ? null
                                      : 'El nombre no es válido'),
                          const SizedBox(height: 16),
                          CustomInputField(
                            hintText: AppStrings.price,
                            keyboardType: TextInputType.number,
                            controller: precioController,
                            isRequired: true,
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Por favor ingrese un valor'
                                : AppConstants.priceRegex.hasMatch(value)
                                    ? null
                                    : 'Este campo no es válida',
                          ),
                          const SizedBox(height: 16),
                          CustomInputField(
                            hintText: AppStrings.timePreparation,
                            controller: tiempoPreparacionController,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Ingrese un tiempo de preparación'
                                : AppConstants.timePreparationRegex.hasMatch(value)
                                    ? null
                                    : 'El tiempo de preparación no es válido',
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_shopping_cart,
                                  color: Colors.white),
                              label: const Text(
                                'Agregar Productos al Combo',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              onPressed: () {
                                context.push(
                                    '/admin/manage/combo/create-item-combo/products-item-combo');
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
              
                          // Productos seleccionados (píldoras)
                          Consumer(
                            builder: (context, ref, child) {
                              final selectedProducts = ref.watch(selectedComboProductsProvider);
              
                              if (selectedProducts.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.white70, size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'No hay productos seleccionados',
                                          style: TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Productos seleccionados:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF34D399),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${selectedProducts.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: selectedProducts.map((product) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF34D399).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF34D399),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                product.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () {
                                                // Eliminar producto
                                                ref.read(selectedComboProductsProvider.notifier).state =
                                                  selectedProducts.where((p) => p.id != product.id).toList();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFEF4444),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            },
                          ),
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
                            if (!isEditMode) {
                              _clearAllFields();
                            }
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
                                  (_formKey.currentState?.validate() ?? false) &&
                                  !_isLoading
                              ? _saveCombo
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            disabledBackgroundColor:
                                const Color(0xFF8B5CF6).withAlpha(100),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEditMode ? 'Actualizar Combo' : 'Guardar Combo',
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
        ),
      ),
    );
  }
}
