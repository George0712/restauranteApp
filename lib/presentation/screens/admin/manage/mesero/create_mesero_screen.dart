import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateMeseroScreen extends ConsumerStatefulWidget {
  final UserModel? user;
  const CreateMeseroScreen({super.key, this.user});

  @override
  ConsumerState<CreateMeseroScreen> createState() => _CreateMeseroScreenState();
}

class _CreateMeseroScreenState extends ConsumerState<CreateMeseroScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool isEditing;

  @override
  void initState() {
    super.initState();
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

  void _validateFields() {
    if (!mounted) return;
    final registerUserController = ref.read(registerUserControllerProvider);
    final isValid = registerUserController.areFieldsContactDataValid();
    ref.read(isContactInfoValidProvider.notifier).state = isValid;
  }

  @override
  Widget build(BuildContext context) {
    final registerUserController = ref.watch(registerUserControllerProvider);
    final areFieldsValid = ref.watch(isContactInfoValidProvider);
    final profileImage = ref.watch(profileImageProvider);
    final imageNotifier = ref.read(profileImageProvider.notifier);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    const rol = 'mesero';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
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
            child: Container(
              width: isTablet ? 500 : double.infinity,
              padding: isTablet
                  ? const EdgeInsets.symmetric(vertical: 100, horizontal: 60)
                  : const EdgeInsets.fromLTRB(16, 100, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? "Editar Mesero" : AppStrings.registerWaiter,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing ? "Editar la información de contacto del Mesero." : AppStrings.registerWaiterDescription,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),

                  // Foto perfil
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withAlpha(40),
                          backgroundImage: profileImage != null ? FileImage(profileImage) : null,
                          child: profileImage == null
                              ? Icon(Icons.person, size: 50, color: theme.primaryColor.withAlpha(200))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.primaryColor,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
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
                          controller: registerUserController.apellidosController,
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
                          controller: registerUserController.telefonoController,
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
                          controller: registerUserController.direccionController,
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
                          registerUserController.nombreController.clear();
                          registerUserController.apellidosController.clear();
                          registerUserController.telefonoController.clear();
                          registerUserController.direccionController.clear();
                          registerUserController.userNameController.clear();
                          registerUserController.emailController.clear();
                          registerUserController.passwordController.clear();
                          context.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: areFieldsValid && (_formKey.currentState?.validate() ?? false)
                            ? () async {
                                if (isEditing) {
                                  final res = await registerUserController.updateUserPersonalInfo(
                                    widget.user!.copyWith(
                                      nombre: registerUserController.nombreController.text.trim(),
                                      apellidos: registerUserController.apellidosController.text.trim(),
                                      telefono: registerUserController.telefonoController.text.trim(),
                                      direccion: registerUserController.direccionController.text.trim(),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (res == null) {
                                    SnackbarHelper.showSuccess('Mesero actualizado exitosamente');
                                    context.pop();
                                  } else {
                                    SnackbarHelper.showError('Error: $res');
                                  }
                                } else {
                                  // Crear usuario temporal y continuar al siguiente paso fuera de esta pantalla
                                  final partialUser = UserModel(
                                    uid: '',
                                    nombre: registerUserController.nombreController.text.trim(),
                                    apellidos: registerUserController.apellidosController.text.trim(),
                                    telefono: registerUserController.telefonoController.text.trim(),
                                    direccion: registerUserController.direccionController.text.trim(),
                                    email: '',
                                    username: '',
                                    rol: rol,
                                  );
                                  ref.read(userTempProvider.notifier).state = partialUser;
                                  if (!mounted) return;
                                  context.push('/admin/manage/mesero/create-credentials');
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          disabledBackgroundColor: const Color(0xFF8B5CF6).withAlpha(100),
                        ),
                        child: Text(isEditing ? 'Actualizar' : 'Continuar', style: const TextStyle(color: Colors.white)),
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
  }
}