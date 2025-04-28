import 'package:flutter/material.dart';

class SettingsAdminScreen extends StatelessWidget {
  const SettingsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Administrador'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Configuración Administrador',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),            
          ],
        ),
      ),
    );
  }
}