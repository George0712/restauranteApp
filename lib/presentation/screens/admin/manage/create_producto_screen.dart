import 'package:flutter/material.dart';

class CreateProductoScreen extends StatelessWidget {
  const CreateProductoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear producto'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Crear producto',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement your create mesero logic here
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}