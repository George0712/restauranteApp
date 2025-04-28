import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateMeseroScreen extends StatelessWidget {
  const CreateMeseroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: isTablet ? 500 : double.infinity,
            margin: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 16,
              vertical: isTablet ? 20 : 10,
            ),
            padding: const EdgeInsets.all(20),
            decoration: isTablet
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Nuevo Mesero',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa los datos personales del mesero. La foto es opcional.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                
                // Foto de perfil (opcional)
                Center(
                  child: Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: () {
                              // Lógica para seleccionar imagen
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Inputs de texto
                const _CustomInputField(hintText: 'Nombre'),
                const SizedBox(height: 12),
                const _CustomInputField(hintText: 'Apellidos'),
                const SizedBox(height: 12),
                const _CustomInputField(hintText: 'Teléfono', keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                const _CustomInputField(hintText: 'Dirección'),
                
                const SizedBox(height: 32),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        context.pop(); // Cancelar
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: Colors.black),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.black),),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.pushNamed('/crear-credenciales');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Guardar y Continuar', style: TextStyle(color: Colors.white),),
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

class _CustomInputField extends StatelessWidget {
  final String hintText;
  final TextInputType keyboardType;

  const _CustomInputField({
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}