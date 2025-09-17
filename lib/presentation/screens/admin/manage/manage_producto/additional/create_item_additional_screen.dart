// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateItemAdditionalScreen extends ConsumerStatefulWidget {
  final AdditionalModel? additional;
  const CreateItemAdditionalScreen({super.key, this.additional});

  @override
  ConsumerState<CreateItemAdditionalScreen> createState() =>
      _CreateItemAdditionalScreenState();
}

class _CreateItemAdditionalScreenState
    extends ConsumerState<CreateItemAdditionalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool? isAvailable = true;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(registerAdditionalControllerProvider);
    controller.nameController.addListener(_validateFields);
    controller.priceController.addListener(_validateFields);

    if (widget.additional != null) {
      // Modo edición: inicializar campos
      controller.nameController.text = widget.additional!.name;
      controller.priceController.text = widget.additional!.price.toStringAsFixed(0);
      isAvailable = widget.additional!.disponible;
    }
  }

  void _validateFields() {
    if (!mounted) return;
    final controller = ref.read(registerAdditionalControllerProvider);
    final isValid = controller.areFieldsValid();
    ref.read(isValidFieldsProvider.notifier).state = isValid;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(registerAdditionalControllerProvider);
    final areFieldsValid = ref.watch(isValidFieldsProvider);
    final profileImage = ref.watch(profileImageProvider);
    //final imageNotifier = ref.read(profileImageProvider.notifier);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
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
                Text(
                  widget.additional == null ? AppStrings.registerAdditional : 'Editar Adicional',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.additional == null ? AppStrings.registerAdditionalDescription : 'Modifica la información del adicional',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // Foto de perfil (opcional) — mantén estilo si quieres
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withAlpha(40),
                        backgroundImage: profileImage != null ? FileImage(profileImage) : null,
                        child: profileImage == null
                            ? Icon(Icons.category_rounded, size: 50, color: theme.primaryColor.withAlpha(200))
                            : null,
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
                        controller: controller.nameController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingrese un nombre'
                            : AppConstants.nameRegex.hasMatch(value)
                                ? null
                                : 'El nombre no es válido',
                      ),
                      const SizedBox(height: 12),
                      CustomInputField(
                        hintText: 'Precio',
                        controller: controller.priceController,
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingrese un valor'
                            : AppConstants.priceRegex.hasMatch(value)
                                ? null
                                : 'El campo no es válido',
                      ),
                      const SizedBox(height: 12),

                      // Checkbox de disponibilidad
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Disponible:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
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
                                          ref.read(registerAdditionalControllerProvider).setDisponible(value ?? true);
                                        },
                                        activeColor: Colors.green,
                                      ),
                                      const Text('Sí', style: TextStyle(color: Colors.white)),
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
                                          ref.read(registerAdditionalControllerProvider).setDisponible(value ?? false);
                                        },
                                        activeColor: Colors.red,
                                      ),
                                      const Text('No', style: TextStyle(color: Colors.white)),
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
                        ref.read(registerAdditionalControllerProvider).clear();
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
                              final controller = ref.read(registerAdditionalControllerProvider);
                              String? result;
                              if (widget.additional == null) {
                                result = await controller.registrarAdditional(
                                  ref,
                                  name: controller.nameController.text.trim(),
                                  price: double.parse(controller.priceController.text.trim()),
                                  disponible: isAvailable!,
                                );
                              } else {
                                result = await controller.actualizarAdditional(
                                  ref,
                                  id: widget.additional!.id,
                                  name: controller.nameController.text.trim(),
                                  price: double.parse(controller.priceController.text.trim()),
                                  disponible: isAvailable!,
                                );
                              }

                              if (result == null) {
                                SnackbarHelper.showSnackBar(
                                    widget.additional == null ? 'Adicional agregado' : 'Adicional actualizado');
                                context.pop();
                              } else {
                                SnackbarHelper.showSnackBar('Error: $result');
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        disabledBackgroundColor: const Color(0xFF8B5CF6).withAlpha(100),
                      ),
                      child: Text(widget.additional == null ? 'Agregar' : 'Actualizar', style: const TextStyle(color: Colors.white)),
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