// ignore_for_file: use_build_context_synchronously

import 'dart:developer' as developer;
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
import 'package:restaurante_app/presentation/widgets/cloudinary_image_widget.dart';

class CreateItemProductScreen extends ConsumerStatefulWidget {
  final String? productId; // null para crear, con ID para editar

  const CreateItemProductScreen({
    super.key,
    this.productId,
  });

  @override
  ConsumerState<CreateItemProductScreen> createState() =>
      _CreateItemProductScreenState();
}

class _CreateItemProductScreenState
    extends ConsumerState<CreateItemProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  bool? isAvailable = true;
  bool _isLoading = false;
  bool _hasLoadedData = false;
  double _uploadProgress = 0.0;
  String? _originalImageUrl; // Para mantener referencia de la imagen original

  // Getter para determinar si estamos editando
  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();

    // Limpiar datos al iniciar SOLO si estamos creando (no editando)
    if (!isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearAllFields();
      });
    }

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

  @override
  void dispose() {
    final registerProductController =
        ref.read(registerProductoControllerProvider);
    registerProductController.nombreController.removeListener(_validateFields);
    registerProductController.precioController.removeListener(_validateFields);
    registerProductController.tiempoPreparacionController
        .removeListener(_validateFields);
    registerProductController.ingredientesController
        .removeListener(_validateFields);
    super.dispose();
  }

  // Método para limpiar todos los campos
  void _clearAllFields() {
    final registerProductController =
        ref.read(registerProductoControllerProvider);

    // Limpiar controladores
    registerProductController.clearAllFields();

    // Limpiar imagen
    ref.read(profileImageProvider.notifier).clearImage();

    // LIMPIAR ESTADO LOCAL CORRECTAMENTE
    setState(() {
      selectedCategory = null;
      isAvailable = true;
      _hasLoadedData = false;
      _originalImageUrl = null;
    });

    // Resetear formulario
    _formKey.currentState?.reset();

    // Resetear validación
    ref.read(isValidFieldsProvider.notifier).state = false;
  }

  // Cargar datos del producto para edición
  void _loadProductData(dynamic producto) {
    if (_hasLoadedData) return;

    final registerProductController =
        ref.read(registerProductoControllerProvider);

    registerProductController.nombreController.text = producto.name ?? '';
    registerProductController.precioController.text =
        (producto.price ?? 0).toDouble().toStringAsFixed(0);
    registerProductController.tiempoPreparacionController.text =
        (producto.tiempoPreparacion ?? 0).toString();
    registerProductController.ingredientesController.text =
        producto.ingredientes ?? '';

    String? categoryValue = producto.category;

    // Si está vacío, null, o solo espacios, convertir a null
    if (categoryValue != null && categoryValue.trim().isEmpty) {
      categoryValue = null;
    }

    setState(() {
      selectedCategory = categoryValue;
      isAvailable = producto.disponible ?? true;
      _originalImageUrl = producto.photo;
      _hasLoadedData = true;
    });

    // Limpiar imagen del provider para mostrar la original
    ref.read(profileImageProvider.notifier).clearImage();

    // Forzar validación después de cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateFields();
    });
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
              if (ref.watch(profileImageProvider) != null ||
                  (isEditing && _originalImageUrl != null))
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
    setState(() {
      _originalImageUrl = null;
    });
    SnackbarHelper.showInfo('Imagen eliminada');
  }

  // Método para manejar el envío del formulario
  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      SnackbarHelper.showWarning(
          'Por favor corrige los errores en el formulario');
      return;
    }

    if (selectedCategory == null) {
      SnackbarHelper.showWarning('Por favor selecciona una categoría');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      final registerProductController =
          ref.read(registerProductoControllerProvider);
      final profileImage = ref.watch(profileImageProvider);

      String? imageToProcess = _originalImageUrl; // Imagen por defecto

      // Si hay una nueva imagen seleccionada, usar su path
      if (profileImage != null) {
        imageToProcess = profileImage.path;
      }

      String? result;

      if (isEditing) {
        result = await registerProductController.updateProduct(
          ref,
          productId: widget.productId!,
          nombre: registerProductController.nombreController.text.trim(),
          precio: double.parse(registerProductController.precioController.text),
          tiempoPreparacion: int.parse(
              registerProductController.tiempoPreparacionController.text),
          ingredientes:
              registerProductController.ingredientesController.text.trim(),
          categoria: selectedCategory!,
          disponible: isAvailable!,
          newPhoto: imageToProcess,
          onUploadProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
      } else {
        // Crear nuevo producto
        result = await registerProductController.registrarProducto(
          ref,
          nombre: registerProductController.nombreController.text.trim(),
          precio: double.parse(registerProductController.precioController.text),
          tiempoPreparacion: int.parse(
              registerProductController.tiempoPreparacionController.text),
          ingredientes:
              registerProductController.ingredientesController.text.trim(),
          categoria: selectedCategory!,
          disponible: isAvailable!,
          foto: imageToProcess ?? '',
          onUploadProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
      }

      if (result == null) {
        final message = isEditing
            ? 'Producto actualizado correctamente'
            : 'Producto agregado correctamente';

        SnackbarHelper.showSuccess(message);

        _clearAllFields();

        if (mounted) {
          context.pop();
        }
      } else {
        SnackbarHelper.showError('Error: $result');
      }
    } catch (e) {
      SnackbarHelper.showError('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerProductController =
        ref.watch(registerProductoControllerProvider);
    final categoryAsync = ref.watch(categoryDisponibleProvider);
    final areFieldsValid = ref.watch(isValidFieldsProvider);
    final profileImage = ref.read(profileImageProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Si estamos editando, cargar datos del producto
    Widget bodyContent = Container(
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
                    isEditing ? 'Editar Producto' : AppStrings.createNewProduct,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing
                        ? 'Modifica la información del producto'
                        : AppStrings.createNewProductDescription,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
        
                  // Foto de perfil
                  Center(
                    child: GestureDetector(
                      onTap: _handleImageSelection,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
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
                                  ? (isEditing &&
                                          _originalImageUrl != null &&
                                          _originalImageUrl!.isNotEmpty)
                                      ? ClipOval(
                                          child: CloudinaryImageWidget(
                                            imageUrl: _originalImageUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorWidget: Iconify(
                                              Bi.box_fill,
                                              size: 50,
                                              color: theme.primaryColor
                                                  .withAlpha(200),
                                            ),
                                          ),
                                        )
                                      : Iconify(
                                          Bi.box_fill,
                                          size: 50,
                                          color:
                                              theme.primaryColor.withAlpha(200),
                                        )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _handleImageSelection,
                              onLongPress: _showImageOptions,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.primaryColor,
                                  child: Icon(
                                    (profileImage == null &&
                                            (isEditing &&
                                                _originalImageUrl == null))
                                        ? Icons.add_a_photo
                                        : Icons.edit,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
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
                      (profileImage == null &&
                              (isEditing && _originalImageUrl == null))
                          ? 'Toca para agregar una imagen del producto'
                          : 'Toca para cambiar la imagen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
        
                  const SizedBox(height: 24),
        
                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomInputField(
                          hintText: AppStrings.name,
                          controller: registerProductController.nombreController,
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
                                  : 'Este campo no es válido',
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          hintText: AppStrings.price,
                          keyboardType: TextInputType.number,
                          controller: registerProductController.precioController,
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
                        // Categoría - Dropdown
                        categoryAsync.when(
                          data: (categories) {
                            // LIMPIAR VALOR VACÍO O INVÁLIDO
                            String? validatedCategory = selectedCategory;
        
                            if (validatedCategory != null) {
                              // Si cambió el valor, actualizar el estado
                              if (validatedCategory != selectedCategory) {
                                developer.log(
                                    'Actualizando categoría de "$selectedCategory" a "$validatedCategory"');
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      selectedCategory = validatedCategory;
                                    });
                                  }
                                });
                                // Retornar un widget temporal mientras se actualiza
                                return Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Actualizando...',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
        
                            return DropdownButtonFormField<String>(
                              key: ValueKey(
                                  'dropdown_${categories.length}_${validatedCategory ?? "null"}'),
                              value: validatedCategory,
                              dropdownColor: const Color(0xFF1A1A2E),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppStrings.category,
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                                floatingLabelStyle: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 18,
                                ),
                                hintText: AppStrings.category,
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Color(0xFF34D399),
                                  size: 22,
                                ),
                                suffixText: '*',
                                suffixStyle: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32)),
                                  borderSide: BorderSide(
                                    color: Color(0xFF34D399),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32)),
                                  borderSide: BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32)),
                                  borderSide: BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              items: categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
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
                          loading: () => Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              borderRadius: BorderRadius.circular(32),
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF34D399),
                                      )),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Cargando categorías...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          error: (error, stack) => Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFEF4444)),
                              borderRadius: BorderRadius.circular(32),
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: Center(
                              child: Text(
                                'Error cargando categorías: $error',
                                style: const TextStyle(
                                    color: Color(0xFFEF4444), fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          hintText: AppStrings.timePreparation,
                          controller: registerProductController
                              .tiempoPreparacionController,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(
                            Icons.access_time,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ingrese el tiempo de preparación'
                              : AppConstants.timePreparationRegex.hasMatch(value)
                                  ? null
                                  : 'Este campo no es válido',
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          hintText: AppStrings.ingredients,
                          controller:
                              registerProductController.ingredientesController,
                          isRequired: true,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          prefixIcon: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ingrese al menos 3 ingredientes'
                              : AppConstants.ingredientesRegex.hasMatch(value)
                                  ? null
                                  : 'Este campo no es válido',
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
                        onPressed: _isLoading
                            ? null
                            : () {
                                _clearAllFields();
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
                        onPressed: (_isLoading ||
                                !areFieldsValid ||
                                !(_formKey.currentState?.validate() ?? false))
                            ? null
                            : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          disabledBackgroundColor:
                              const Color(0xFF8B5CF6).withAlpha(100),
                        ),
                        child: _isLoading
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  if (_uploadProgress > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${(_uploadProgress * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Text(
                                isEditing ? 'Actualizar' : 'Agregar',
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
    );

    // Si estamos editando, cargar los datos del producto
    if (isEditing) {
      final productAsync = ref.watch(productByIdProvider(widget.productId!));

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
        body: productAsync.when(
          data: (producto) {
            if (producto == null) {
              return Container(
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
                  child: Text(
                    'Producto no encontrado',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            }

            // Cargar datos del producto
            if (!_hasLoadedData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadProductData(producto);
              });
            }

            return bodyContent;
          },
          loading: () => Container(
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
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (error, stackTrace) => Container(
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
            child: Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    } else {
      // Modo creación normal
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
        body: bodyContent,
      );
    }
  }
}
