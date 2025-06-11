// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateCredentialsMesero extends ConsumerStatefulWidget {
  const CreateCredentialsMesero({super.key});

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

    final registerUserController = ref.read(registerUserControllerProvider);
    registerUserController.userNameController.addListener(_validateFields);
    registerUserController.emailController.addListener(_validateFields);
    registerUserController.passwordController.addListener(_validateFields);
  }

  void _validateFields() {
    if (!mounted) return;
    final registerUserController = ref.read(registerUserControllerProvider);
    final isValid = registerUserController.areFieldsAccesDataValid();
    ref.read(isCredentialsValidProvider.notifier).state = isValid;
  }

  @override
  void dispose() {
    super.dispose();
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.black54),
          onPressed: () => context.pop(),
        ),
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
                  AppStrings.registerWaiterCredentials,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.registerWaiterCredentialsDescription,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomInputField(
                        hintText: AppStrings.userName,
                        controller: registerUserController.userNameController,
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
                        validator: (value) {
                          return value!.isEmpty
                              ? AppStrings.pleaseEnterEmailAddress
                              : AppConstants.emailRegex.hasMatch(value)
                                  ? null
                                  : AppStrings.invalidEmailAddress;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        hintText: AppStrings.password,
                        controller: registerUserController.passwordController,
                        validator: (value) {
                          return value!.isEmpty
                              ? AppStrings.pleaseEnterPassword
                              : AppConstants.passwordRegex.hasMatch(value)
                                  ? null
                                  : AppStrings.invalidPassword;
                        },
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
                        side: const BorderSide(color: Colors.black),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: areFieldsValid &&
                              (_formKey.currentState?.validate() ?? false)
                          ? () async {
                              if (tempUser == null) {
                                SnackbarHelper.showSnackBar(
                                    'Falta información de contacto');
                                return;
                              }
                              try {
                                await registerUserController.registrarUsuario(
                                  ref,
                                  nombre: tempUser.nombre,
                                  apellidos: tempUser.apellidos,
                                  telefono: tempUser.telefono,
                                  direccion: tempUser.direccion,
                                  username: registerUserController
                                      .userNameController.text
                                      .trim(),
                                  email: registerUserController
                                      .emailController.text
                                      .trim(),
                                  password: registerUserController
                                      .passwordController.text
                                      .trim(),
                                  rol: tempUser.rol,
                                );
                                SnackbarHelper.showSnackBar(
                                    'Mesero registrado con éxito');
                                ref.read(userTempProvider.notifier).state =
                                    null;
                                context.pop();
                                context.push('/admin/manage/mesero');
                              } catch (e) {
                                SnackbarHelper.showSnackBar(
                                    'Error: ${e.toString()}');
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
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
    );
  }
}
