import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/presentation/providers/login/login_provider.dart';
import 'package:restaurante_app/presentation/widgets/app_text_form_field.dart';
import 'package:restaurante_app/presentation/widgets/gradient_background.dart';

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
    final theme = Theme.of(context);
    final loginController = ref.watch(loginControllerProvider);
    final isPasswordVisible = ref.watch(passwordVisibilityProvider);
    final isFieldsValid = ref.watch(fieldsValidProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientBackground(
            children: [
              Text(
                AppStrings.signInToYourNAccount,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(AppStrings.signInToYourAccount,
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppTextFormField(
                    controller: loginController.emailController,
                    labelText: AppStrings.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _formKey.currentState?.validate(),
                    validator: (value) {
                      return value!.isEmpty
                          ? AppStrings.pleaseEnterEmailAddress
                          : AppConstants.emailRegex.hasMatch(value)
                              ? null
                              : AppStrings.invalidEmailAddress;
                    },
                  ),
                  AppTextFormField(
                    obscureText: isPasswordVisible,
                    controller: loginController.passwordController,
                    labelText: AppStrings.password,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (_) => _formKey.currentState?.validate(),
                    validator: (value) {
                      return value!.isEmpty
                          ? AppStrings.pleaseEnterPassword
                          : AppConstants.passwordRegex.hasMatch(value)
                              ? null
                              : AppStrings.invalidPassword;
                    },
                    suffixIcon: IconButton(
                      onPressed: () => ref
                          .read(passwordVisibilityProvider.notifier)
                          .state = !isPasswordVisible,
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(48),
                      ),
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(AppStrings.forgotPassword),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isFieldsValid
                          ? () async {
                              final success = await loginController.login(ref);
                              if (success) {
                                if (context.mounted) {
                                  context.go(
                                      '/splash-screen');
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Inicio de sesión fallido'),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 25),
                        ),
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.disabled)) {
                            return theme.colorScheme.primary.withAlpha(50);
                          }
                          return theme.colorScheme.primary;
                        }),
                        foregroundColor: WidgetStateProperty.all(
                          theme.colorScheme.onPrimary,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      child: const Text(AppStrings.login),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
