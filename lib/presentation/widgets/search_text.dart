import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchBarText extends ConsumerStatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextStyle? hintStyle;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final Color? fillColor;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;
  final BorderSide? enabledBorderSide;
  final BorderSide? focusedBorderSide;
  final EdgeInsetsGeometry? margin;

  const SearchBarText({
    Key? key,
    required this.onChanged,
    this.hintText = 'Buscar...',
    this.hintStyle,
    this.prefixIconColor,
    this.suffixIconColor,
    this.fillColor,
    this.textStyle,
    this.borderRadius,
    this.enabledBorderSide,
    this.focusedBorderSide,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) : super(key: key);

  @override
  ConsumerState<SearchBarText> createState() => _SearchTextState();
}

class _SearchTextState extends ConsumerState<SearchBarText> {
  final TextEditingController _searchController = TextEditingController();
  String filtroTexto = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      width: double.infinity,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon:
              Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: filtroTexto.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Colors.white.withValues(alpha: 0.7)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      filtroTexto = '';
                    });
                    widget.onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
        ),
        onChanged: (value) {
          setState(() {
            filtroTexto = value;
          });
          widget.onChanged(value);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
