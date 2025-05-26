import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta no encontrada'), leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.black54),
          onPressed: () => context.pop(),
        ),),
      body: const Center(
        child: Text('404 - Página no encontrada'),
      ),
    );
  }
}
