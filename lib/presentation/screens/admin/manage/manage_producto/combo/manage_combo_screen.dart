import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/constants/app_strings.dart';

class ManageComboScreen extends ConsumerStatefulWidget {
  const ManageComboScreen({super.key});

  @override
  ConsumerState<ManageComboScreen> createState() => _ManageComboScreenState();
}

class _ManageComboScreenState extends ConsumerState<ManageComboScreen> {
  final rol = 'mesero';
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
                AppStrings.manageCombos,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.manageCombosDescription,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
          
              // Botones
              ElevatedButton(
                onPressed: () {
                  context.push('/admin/manage/combo/create-item-combos');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Nuevo Combo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}