import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool isRequired;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? labelColor;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.isRequired = false,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
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
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        
        // Label style
        labelStyle: TextStyle(
          color: labelColor ?? Colors.white.withValues(alpha: 0.7),
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

// Widget especializado para campos de precio/moneda
class CurrencyTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool isRequired;

  const CurrencyTextField({
    super.key,
    this.controller,
    required this.label,
    this.validator,
    this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      validator: validator,
      onChanged: onChanged,
      isRequired: isRequired,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF34D399), size: 22),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
  }
}

// Widget especializado para campos de número/cantidad
class NumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool isRequired;
  final int? maxValue;

  const NumberTextField({
    super.key,
    this.controller,
    required this.label,
    this.validator,
    this.onChanged,
    this.isRequired = false,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      validator: validator,
      onChanged: onChanged,
      isRequired: isRequired,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        if (maxValue != null)
          FilteringTextInputFormatter.allow(
            RegExp(r'^([1-9]|[1-9][0-9]|' + maxValue.toString() + r')$'),
          ),
      ],
    );
  }
}

// Widget especializado para campos de email
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  const EmailTextField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Correo electrónico',
      validator: validator,
      onChanged: onChanged,
      isRequired: true,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF34D399), size: 22),
      textCapitalization: TextCapitalization.none,
    );
  }
}

// Widget especializado para campos de contraseña
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool isRequired;

  const PasswordTextField({
    super.key,
    this.controller,
    this.label = 'Contraseña',
    this.validator,
    this.onChanged,
    this.isRequired = true,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label,
      validator: widget.validator,
      onChanged: widget.onChanged,
      isRequired: widget.isRequired,
      obscureText: _obscureText,
      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF34D399), size: 22),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white.withValues(alpha: 0.7),
          size: 22,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}

// Widget especializado para campos de teléfono
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool isRequired;

  const PhoneTextField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Teléfono',
      validator: validator,
      onChanged: onChanged,
      isRequired: isRequired,
      keyboardType: TextInputType.phone,
      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF34D399), size: 22),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
    );
  }
}
