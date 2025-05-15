import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateItemComboScreen extends ConsumerStatefulWidget {
  const CreateItemComboScreen({super.key});

  @override
  ConsumerState<CreateItemComboScreen> createState() =>
      _CreateItemComboScreenState();
}

class _CreateItemComboScreenState
    extends ConsumerState<CreateItemComboScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  bool? isAvailable = true;

  @override
  void initState() {
    super.initState();
    final registerComboController = ref.read(registerComboControllerProvider);
    registerComboController.nombreController.addListener(_validateFields);
    registerComboController.precioController.addListener(_validateFields);
    registerComboController.tiempoPreparacionController.addListener(_validateFields);
  }

  void _validateFields() {
    if (!mounted) return;
    final registerComboController = ref.read(registerComboControllerProvider);
    final isValid = registerComboController.areFieldsValid();
    ref.read(isValidFieldsProvider.notifier).state = isValid;
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
        backgroundColor: Colors.white,
        foregroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: isTablet
                    ? const EdgeInsets.symmetric(vertical: 40, horizontal: 80)
                    : const EdgeInsets.all(16), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.createNewCombo,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.createNewComboDescription,
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
                        controller: registerComboController.nombreController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingrese un nombre'
                            : AppConstants.nameRegex.hasMatch(value)
                                ? null
                                : 'El nombre no es válido'),
                    const SizedBox(height: 12),
                    CustomInputField(
                      hintText: AppStrings.price,
                      keyboardType: TextInputType.number,
                      controller: registerComboController.precioController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Por favor ingrese un valor'
                          : AppConstants.priceRegex.hasMatch(value)
                              ? null
                              : 'Este campo no es válida',
                    ),
                    const SizedBox(height: 12),                    
                    CustomInputField(
                      hintText: AppStrings.timePreparation,
                      controller: registerComboController.tiempoPreparacionController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese un tiempo de preparación'
                          : AppConstants.timePreparationRegex.hasMatch(value)
                              ? null
                              : 'El tiempo de preparación no es válido',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
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
                          context.push('/admin/manage/combo/create-item-combo/products-item-combo');
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
                                    ),
                                    const Text('Sí'),
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
                                    ),
                                    const Text('No'),
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
                      side: BorderSide(color: theme.primaryColor),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: areFieldsValid &&
                            (_formKey.currentState?.validate() ?? false)
                        ? () {
                            context.push(
                                '/admin/manage/producto/manage-combos');
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
    );
  }
}
