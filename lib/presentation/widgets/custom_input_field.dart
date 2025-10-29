import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInputField extends StatelessWidget {
  final String hintText;
  final String? label;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool? obscureText;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;

  const CustomInputField({
    super.key,
    required this.hintText,
    this.label,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.obscureText,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? hintText;
    final displayLabel = isRequired ? '$effectiveLabel *' : effectiveLabel;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: (obscureText ?? false) ? 1 : maxLines,
      maxLength: maxLength,
      onTap: onTap,
      onChanged: onChanged,
      textInputAction: textInputAction,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: displayLabel,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,

        // Label style - Floating label
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: focusedBorderColor ?? const Color(0xFF34D399),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        // Hint style
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 14,
        ),

        // Fill
        filled: true,
        fillColor: fillColor ?? Colors.white.withValues(alpha: 0.08),

        // Content padding
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        // Counter style (for maxLength)
        counterStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
        ),

        // Border styles
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: borderColor ?? Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: focusedBorderColor ?? const Color(0xFF34D399),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1.5,
          ),
        ),

        // Error style
        errorStyle: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        errorMaxLines: 2,
      ),
    );
  }
}
