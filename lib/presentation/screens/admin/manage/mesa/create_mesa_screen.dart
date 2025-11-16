import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/custom_input_field.dart';

class CreateMesaScreen extends ConsumerStatefulWidget {
  const CreateMesaScreen({super.key});

  @override
  ConsumerState<CreateMesaScreen> createState() => _CreateMesaScreenState();
}

class _CreateMesaScreenState extends ConsumerState<CreateMesaScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Limpiar campos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mesaController = ref.read(mesaControllerProvider);
      mesaController.numeroMesaController.clear();
      mesaController.capacidadController.clear();
      ref.read(isMesaFieldsValidProvider.notifier).state = false;
    });

    final mesaController = ref.read(mesaControllerProvider);
    mesaController.numeroMesaController.addListener(_validateFields);
    mesaController.capacidadController.addListener(_validateFields);
  }

  void _validateFields() {
    if (!mounted) return;
    final mesaController = ref.read(mesaControllerProvider);
    final isValid = mesaController.areFieldsValid();
    ref.read(isMesaFieldsValidProvider.notifier).state = isValid;
  }

  @override
  Widget build(BuildContext context) {
    final mesaController = ref.watch(mesaControllerProvider);
    final areFieldsValid = ref.watch(isMesaFieldsValidProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
                    const Text(
                      AppStrings.manageTable,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.manageTableDescription,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                
                    // Inputs de texto
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomInputField(
                              hintText: 'Número de mesa',
                              controller: mesaController.numeroMesaController,
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(
                                Icons.table_restaurant,
                                color: Color(0xFF34D399),
                                size: 22,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese un número de mesa';
                                }
                                final numeroMesaRegex = RegExp(r'^[1-9]\d*$');
                                if (!numeroMesaRegex.hasMatch(value)) {
                                  return 'El número de mesa debe ser un número válido';
                                }
                                return null;
                              }),
                          const SizedBox(height: 16),
                          CustomInputField(
                            hintText: 'Capacidad de la mesa',
                            controller: mesaController.capacidadController,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(
                              Icons.people_outline,
                              color: Color(0xFF34D399),
                              size: 22,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese la capacidad';
                              }
                              final capacidadRegex =
                                  RegExp(r'^([1-9]|1[0-9]|20)$');
                              if (!capacidadRegex.hasMatch(value)) {
                                return 'La capacidad debe ser entre 1 y 20 personas';
                              }
                              return null;
                            },
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
                            mesaController.limpiarFormulario();
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
                                  final numeroMesa = int.parse(mesaController
                                      .numeroMesaController.text
                                      .trim());
                                  final capacidad = int.parse(mesaController
                                      .capacidadController.text
                                      .trim());
                
                                  final error =
                                      await mesaController.crearMesa(
                                    numeroMesa: numeroMesa,
                                    capacidad: capacidad,
                                  );
                
                                  if (!mounted) return;
                                  if (error == null) {
                                    mesaController.limpiarFormulario();
                                    if (context.mounted) {
                                      context.pop();
                                    }
                                  } else {
                                    // Mostrar error
                                    SnackbarHelper.showError(error);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            disabledBackgroundColor:
                                const Color(0xFF8B5CF6).withAlpha(100),
                          ),
                          child: const Text(
                            'Agregar',
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
      ),
    );
  }
}
