import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateCocineroScreen extends ConsumerStatefulWidget {
  const CreateCocineroScreen({super.key});

  @override
  ConsumerState<CreateCocineroScreen> createState() =>
      _CreateCocineroScreenState();
}

class _CreateCocineroScreenState extends ConsumerState<CreateCocineroScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final registerUserController = ref.read(registerUserControllerProvider);
    registerUserController.nombreController.addListener(_validateFields);
    registerUserController.apellidosController.addListener(_validateFields);
    registerUserController.telefonoController.addListener(_validateFields);
    registerUserController.direccionController.addListener(_validateFields);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Container(
            width: isTablet ? 500 : double.infinity,
            margin: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 16,
              vertical: isTablet ? 20 : 10,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.registerCook,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.registerCookDescription,
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
                            ? Icon(Icons.person,
                                size: 50, color: theme.primaryColor.withAlpha(200))
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
                        controller: registerUserController.nombreController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingrese un nombre'
                            : AppConstants.nameRegex.hasMatch(value)
                                ? null
                                : 'El nombre no es válido'
                      ),
                      const SizedBox(height: 12),
                      CustomInputField(
                        hintText: AppStrings.lastName,
                        controller:
                            registerUserController.apellidosController,
                        validator: (value) => value == null || value.isEmpty
                          ? 'Por favor ingrese un apellido'
                          : AppConstants.surnameRegex.hasMatch(value)
                            ? null
                            : 'El apellido no es válido',
                      ),
                      const SizedBox(height: 12),
                      CustomInputField(
                        hintText: AppStrings.phone,
                        keyboardType: TextInputType.phone,
                        controller: registerUserController.telefonoController,
                        validator: (value) => value == null || value.isEmpty
                          ? 'Por favor ingrese un teléfono'
                          : AppConstants.phoneRegex.hasMatch(value)
                            ? null
                            : 'El teléfono no es válido',
                      ),
                      const SizedBox(height: 12),
                      CustomInputField(
                        hintText: AppStrings.address,
                        controller:
                            registerUserController.direccionController,
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
                        side: BorderSide(color: theme.primaryColor),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: areFieldsValid && (_formKey.currentState?.validate() ?? false)
                          ? () {
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
                                rol: 'cocinero'
                              );
                              // 2. Guarda en el provider temporal
                              ref.read(userTempProvider.notifier).state =
                                  partialUser;
                            
                              context.push(
                                  '/admin/manage/cocinero/create-credentials');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
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
