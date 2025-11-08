// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateCredentialsMesero extends ConsumerStatefulWidget {
  final UserModel? user;
  const CreateCredentialsMesero({super.key, this.user});

  @override
  ConsumerState<CreateCredentialsMesero> createState() =>
      _CreateCredentialsMeseroState();
}

class _CreateCredentialsMeseroState
    extends ConsumerState<CreateCredentialsMesero> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    final controller = ref.read(registerUserControllerProvider);

    controller.userNameController.addListener(_validateFields);
    controller.emailController.addListener(_validateFields);
    controller.passwordController.addListener(_validateFields);

    if (widget.user != null) {
      controller.userNameController.text = widget.user!.username;
      controller.emailController.text = widget.user!.email;
      controller.passwordController.text = '';
    } else {
      controller.userNameController.clear();
      controller.emailController.clear();
      controller.passwordController.clear();
    }
  }

  void _validateFields() {
    if (!mounted) return;
    final registerUserController = ref.read(registerUserControllerProvider);
    final isValid = registerUserController.areFieldsAccesDataValid();
    ref.read(isCredentialsValidProvider.notifier).state = isValid;
  }

  @override
  Widget build(BuildContext context) {
    final registerUserController = ref.watch(registerUserControllerProvider);
    final areFieldsValid = ref.watch(isCredentialsValidProvider);
    final tempUser = ref.watch(userTempProvider);
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
            child: Container(
              width: isTablet ? 500 : double.infinity,
              padding: isTablet
                  ? const EdgeInsets.symmetric(vertical: 100, horizontal: 60)
                  : const EdgeInsets.fromLTRB(16, 100, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.registerWaiterCredentials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.registerWaiterCredentialsDescription,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomInputField(
                          hintText: AppStrings.userName,
                          controller: registerUserController.userNameController,
                          isRequired: true,
                          prefixIcon: const Icon(
                            Icons.alternate_email,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                          validator: (value) {
                            return value!.isEmpty
                                ? AppStrings.pleaseEnterUserName
                                : AppStrings.invalidUserName;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          hintText: AppStrings.email,
                          controller: registerUserController.emailController,
                          isRequired: true,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                          validator: (value) {
                            return value!.isEmpty
                                ? AppStrings.pleaseEnterEmailAddress
                                : AppConstants.emailRegex.hasMatch(value)
                                    ? null
                                    : AppStrings.invalidEmailAddress;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (widget.user == null)
                          CustomInputField(
                            hintText: AppStrings.password,
                            controller:
                                registerUserController.passwordController,
                            isRequired: true,
                            obscureText: true,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) {
                              return value!.isEmpty
                                  ? AppStrings.pleaseEnterPassword
                                  : AppConstants.passwordRegex.hasMatch(value)
                                      ? null
                                      : AppStrings.invalidPassword;
                            },
                          ),
                        if (widget.user != null)
                          CustomInputField(
                            hintText: AppStrings.password,
                            controller:
                                registerUserController.passwordController,
                            obscureText: true,
                            readOnly: true,
                            enabled: false,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                if (tempUser == null) {
                                  SnackbarHelper.showWarning(
                                      'Falta información de contacto');
                                  return;
                                }
                              if (widget.user == null) {
                                final res = await registerUserController.registrarUsuario(
                                  ref,
                                  nombre: tempUser.nombre,
                                  apellidos: tempUser.apellidos,
                                  telefono: tempUser.telefono,
                                  direccion: tempUser.direccion,
                                  username: registerUserController.userNameController.text.trim(),
                                  email: registerUserController.emailController.text.trim(),
                                  password: registerUserController.passwordController.text.trim(),
                                  rol: tempUser.rol,
                                );
                                if (res == null) {
                                  SnackbarHelper.showSuccess('Usuario creado correctamente');
                                  ref.read(userTempProvider.notifier).state = null;
                                  context.pop();
                                  context.push('/admin/manage/mesero');
                                } else {
                                  SnackbarHelper.showError('Error: $res');
                                }
                              } else {
                                  // EDICIÓN - solo actualizar username y email
                                  final controller =
                                      ref.read(registerUserControllerProvider);
                                  final res =
                                      await controller.updateUserAccessInfo(
                                    uid: widget.user!.uid,
                                    email: registerUserController
                                        .emailController.text
                                        .trim(),
                                    username: registerUserController
                                        .userNameController.text
                                        .trim(),
                                  );
                                  if (res == null) {
                                    SnackbarHelper.showSuccess(
                                        'Credenciales actualizadas con éxito');
                                    context.go('/admin/manage/mesero');
                                  } else {
                                    SnackbarHelper.showError('Error: $res');
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          disabledBackgroundColor:
                              const Color(0xFF8B5CF6).withAlpha(100),
                        ),
                        child: const Text(
                          'Guardar',
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
      ),
    );
  }
}
