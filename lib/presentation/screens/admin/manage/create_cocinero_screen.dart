import 'package:flutter/material.dart';

class CreateCocineroScreen extends StatelessWidget {
  const CreateCocineroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear usuario cocinero'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Crear cocinero',
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