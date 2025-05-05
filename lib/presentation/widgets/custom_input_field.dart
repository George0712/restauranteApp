import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String hintText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool? obscureText;

  const CustomInputField({super.key, 
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.controller, 
    this.validator, 
    this.obscureText
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}