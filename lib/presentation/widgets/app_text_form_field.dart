import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    required this.textInputAction,
    required this.labelText,
    required this.keyboardType,
    required this.controller,
    super.key,
    this.onChanged,
    this.validator,
    this.obscureText,
    this.prefixIcon,
    this.suffixIcon,
    this.onEditingComplete,
    this.autofocus,
    this.focusNode,
    this.decoration,
    this.style,
    this.labelStyle,
    this.fillColor,
    this.filled,
    this.border,
    this.autovalidateMode,
  });

  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final bool? obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String labelText;
  final bool? autofocus;
  final FocusNode? focusNode;
  final void Function()? onEditingComplete;

  final InputDecoration? decoration;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final Color? fillColor;
  final bool? filled;
  final InputBorder? border;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        focusNode: focusNode,
        onChanged: onChanged,
        autofocus: autofocus ?? false,
        validator: validator,
        autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
        obscureText: obscureText ?? false,
        obscuringCharacter: '•',
        onEditingComplete: onEditingComplete,
        style: style ?? TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: decoration ??
            InputDecoration(
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              labelText: labelText,
              labelStyle: labelStyle,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: filled,
              fillColor: fillColor,
              border: border,
            ),
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}