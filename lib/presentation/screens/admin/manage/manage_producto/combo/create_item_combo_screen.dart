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

class CreateItemComboScreen extends ConsumerStatefulWidget {
  const CreateItemComboScreen({super.key});

  @override
  ConsumerState<CreateItemComboScreen> createState() =>
      _CreateItemComboScreenState();
}

class _CreateItemComboScreenState extends ConsumerState<CreateItemComboScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  bool? isAvailable = true;

  @override
  void initState() {
    super.initState();
    final registerComboController = ref.read(registerComboControllerProvider);
    registerComboController.nombreController.addListener(_validateFields);
    registerComboController.precioController.addListener(_validateFields);
    registerComboController.tiempoPreparacionController
        .addListener(_validateFields);
  }

  void _validateFields() {
    if (!mounted) return;
    final registerComboController = ref.read(registerComboControllerProvider);
    final isValid = registerComboController.areFieldsValid();
    ref.read(isValidFieldsProvider.notifier).state = isValid;
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

  @override
  Widget build(BuildContext context) {
    final registerComboController = ref.watch(registerComboControllerProvider);
    final areFieldsValid = ref.watch(isValidFieldsProvider);
    final profileImage = ref.watch(profileImageProvider);
    final imageNotifier = ref.read(profileImageProvider.notifier);
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
                  AppStrings.createNewCombo,
                  style: TextStyle(
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
                          controller: registerComboController.nombreController,
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
                        controller: registerComboController.precioController,
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
                        controller:
                            registerComboController.tiempoPreparacionController,
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
                          ? () {
                              context
                                  .push('/admin/manage/producto/manage-combos');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        disabledBackgroundColor:
                            const Color(0xFF8B5CF6).withAlpha(100),
                      ),
                      child: const Text(
                        'Continuar',
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
