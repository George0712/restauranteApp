// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/providers/admin/permission_service.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateCocineroScreen extends ConsumerStatefulWidget {
  final UserModel? user;
  const CreateCocineroScreen({super.key, this.user});

  @override
  ConsumerState<CreateCocineroScreen> createState() =>
      _CreateCocineroScreenState();
}

class _CreateCocineroScreenState extends ConsumerState<CreateCocineroScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool isEditing;

  @override
  void initState() {
    super.initState();
    _clearFormFields();
    final controller = ref.read(registerUserControllerProvider);

    controller.nombreController.addListener(_validateFields);
    controller.apellidosController.addListener(_validateFields);
    controller.telefonoController.addListener(_validateFields);
    controller.direccionController.addListener(_validateFields);

    isEditing = widget.user != null;

    if (isEditing) {
      controller.nombreController.text = widget.user!.nombre;
      controller.apellidosController.text = widget.user!.apellidos;
      controller.telefonoController.text = widget.user!.telefono;
      controller.direccionController.text = widget.user!.direccion;
    }
  }

  @override
  void dispose() {
    // Remover listeners
    final controller = ref.read(registerUserControllerProvider);
    controller.nombreController.removeListener(_validateFields);
    controller.apellidosController.removeListener(_validateFields);
    controller.telefonoController.removeListener(_validateFields);
    controller.direccionController.removeListener(_validateFields);
    
    super.dispose();
  }

  void _clearFormFields() {
    final controller = ref.read(registerUserControllerProvider);
    controller.nombreController.clear();
    controller.apellidosController.clear();
    controller.telefonoController.clear();
    controller.direccionController.clear();
    controller.userNameController.clear();
    controller.emailController.clear();
    controller.passwordController.clear();
    
    // Limpiar la imagen después del frame actual para evitar modificar el provider durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profileImageProvider.notifier).clearImage();
      }
    });
  }

  void _validateFields() {
    if (!mounted) return;
    final registerUserController = ref.read(registerUserControllerProvider);
    final isValid = registerUserController.areFieldsContactDataValid();
    ref.read(isContactInfoValidProvider.notifier).state = isValid;
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
                'Imagen del Usuario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF34D399)),
                title: const Text('Seleccionar de Galería',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Elegir una imagen existente',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF34D399)),
                title: const Text('Tomar Foto',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Capturar con la cámara',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (ref.watch(profileImageProvider) != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                  title: const Text('Quitar Imagen',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Eliminar imagen actual',
                      style: TextStyle(color: Colors.white70)),
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
  }

  @override
  Widget build(BuildContext context) {
    final registerUserController = ref.watch(registerUserControllerProvider);
    final areFieldsValid = ref.watch(isContactInfoValidProvider);
    final profileImage = ref.watch(profileImageProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    const rol = 'cocinero';

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
                      isEditing ? "Editar Cocinero" : AppStrings.registerCook,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing
                          ? "Editar la información de contacto del Cocinero."
                          : AppStrings.registerCookDescription,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                            
                    // Foto perfil
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
                                  ? Icon(Icons.person,
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
                                    profileImage == null
                                        ? Icons.add_a_photo
                                        : Icons.edit,
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
                            controller: registerUserController.nombreController,
                            isRequired: true,
                            textCapitalization: TextCapitalization.words,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Por favor ingrese un nombre'
                                : AppConstants.nameRegex.hasMatch(value)
                                    ? null
                                    : 'El nombre no es válido',
                          ),
                          const SizedBox(height: 16),
                          CustomInputField(
                            hintText: AppStrings.lastName,
                            controller:
                                registerUserController.apellidosController,
                            isRequired: true,
                            textCapitalization: TextCapitalization.words,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Por favor ingrese un apellido'
                                : AppConstants.surnameRegex.hasMatch(value)
                                    ? null
                                    : 'El apellido no es válido',
                          ),
                          const SizedBox(height: 16),
                          CustomInputField(
                            hintText: AppStrings.phone,
                            keyboardType: TextInputType.phone,
                            controller:
                                registerUserController.telefonoController,
                            isRequired: true,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Por favor ingrese un teléfono'
                                : AppConstants.phoneRegex.hasMatch(value)
                                    ? null
                                    : 'El teléfono no es válido',
                          ),
                          const SizedBox(height: 16),
                          CustomInputField(
                            hintText: AppStrings.address,
                            controller:
                                registerUserController.direccionController,
                            isRequired: true,
                            textCapitalization: TextCapitalization.words,
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Ingrese una dirección'
                                : AppConstants.addressRegex.hasMatch(value)
                                    ? null
                                    : 'La dirección no es válida',
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
                          child: const Text('Cancelar',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: areFieldsValid &&
                                  (_formKey.currentState?.validate() ?? false)
                              ? () async {
                                  if (isEditing) {
                                    final res = await registerUserController
                                        .updateUserPersonalInfo(
                                      widget.user!.copyWith(
                                        nombre: registerUserController
                                            .nombreController.text
                                            .trim(),
                                        apellidos: registerUserController
                                            .apellidosController.text
                                            .trim(),
                                        telefono: registerUserController
                                            .telefonoController.text
                                            .trim(),
                                        direccion: registerUserController
                                            .direccionController.text
                                            .trim(),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (res == null) {
                                      context.pop();
                                    } else {
                                      SnackbarHelper.showError('Error: $res');
                                    }
                                  } else {
                                    // Crear usuario temporal y continuar al siguiente paso fuera de esta pantalla
                                    final partialUser = UserModel(
                                      uid: '',
                                      nombre: registerUserController
                                          .nombreController.text
                                          .trim(),
                                      apellidos: registerUserController
                                          .apellidosController.text
                                          .trim(),
                                      telefono: registerUserController
                                          .telefonoController.text
                                          .trim(),
                                      direccion: registerUserController
                                          .direccionController.text
                                          .trim(),
                                      email: '',
                                      username: '',
                                      rol: rol,
                                    );
                                    ref.read(userTempProvider.notifier).state =
                                        partialUser;
                                    if (!mounted) return;
                                    context.push(
                                        '/admin/manage/cocinero/create-credentials');
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            disabledBackgroundColor:
                                const Color(0xFF8B5CF6).withAlpha(100),
                          ),
                          child: Text(isEditing ? 'Actualizar' : 'Continuar',
                              style: const TextStyle(color: Colors.white)),
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