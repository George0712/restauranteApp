import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/login/login_provider.dart';
import 'package:restaurante_app/presentation/widgets/app_text_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final loginController = ref.read(loginControllerProvider);
    loginController.emailController.clear();
    loginController.passwordController.clear();
    loginController.emailController.addListener(_validateFields);
    loginController.passwordController.addListener(_validateFields);
  }

  void _validateFields() {
    if (!mounted) return;
    final loginController = ref.read(loginControllerProvider);
    final isValid = loginController.areFieldsValid();
    ref.read(fieldsValidProvider.notifier).state = isValid;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final loginController = ref.watch(loginControllerProvider);
    final isPasswordVisible = ref.watch(passwordVisibilityProvider);
    final isFieldsValid = ref.watch(fieldsValidProvider);

    const String assetName = 'assets/icon/cover-2.png';
    // icon designer: Gregor Cresnar
    // icon designer link: /creator/grega.cresnar/
    // font author: Impallari Type
    // font author site: www.impallari.com

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],          
          ),          
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Image.asset(
                      assetName,
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Text(
                        //   "Iniciar Sesión",
                        //   textAlign: TextAlign.center,
                        //   style: theme.textTheme.titleLarge?.copyWith(
                        //   color: Colors.white,
                        //   fontWeight: FontWeight.w700,
                        //   ),
                        // ),
                        const SizedBox(height: 16),
                        AppTextFormField(
                          controller: loginController.emailController,
                          labelText: "Correo o usuario",
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu correo o usuario',
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Colors.white54),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            return value!.isEmpty
                                ? "Ingresa correo"
                                : AppConstants.emailRegex.hasMatch(value)
                                    ? null
                                    : "Correo no válido";
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextFormField(
                          obscureText: isPasswordVisible,
                          controller: loginController.passwordController,
                          labelText: "Contraseña",
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Colors.white54),
                            suffixIcon: IconButton(
                              onPressed: () => ref
                                  .read(passwordVisibilityProvider.notifier)
                                  .state = !isPasswordVisible,
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: isPasswordVisible
                                    ? Colors.white54
                                    : const Color(
                                    0xFFDA3276),
                              ),
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            return value!.isEmpty
                                ? "Ingresa contraseña"
                                : AppConstants.passwordRegex.hasMatch(value)
                                    ? null
                                    : "Contraseña no válida";
                          },
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        // TextButton(
                        //   onPressed: () {},
                        //   child: const Text(
                        //     "¿Olvidaste tu contraseña?",
                        //     style: TextStyle(
                        //       color: Color(0xFFDA3276), // rosa degradado
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isFieldsValid && (_formKey.currentState?.validate() ?? false)
                              ? () async {
                                  final success =
                                      await loginController.login(ref);
                                  if (success) {
                                    if (context.mounted) {
                                      context.go('/splash-screen');
                                    }
                                  } else {
                                    if (context.mounted) {
                                      SnackbarHelper.showError(
                                          "Inicio de sesión fallido");
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            backgroundColor: isFieldsValid
                                ? const Color(
                                    0xFFDA3276)
                                : Colors
                                    .white24, 
                          ),
                          child: const Text(
                            "Entrar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Checkbox(
                        //       value: "Recordar sesión" == "Recordar sesión",
                        //       activeColor: const Color(0xFF8846E8),
                        //       onChanged: (value) => (),
                        //     ),
                        //     const Text("Recordar sesión",
                        //         style: TextStyle(color: Colors.white54)),
                        //   ],
                        // ),
                      ],
                    ),
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
