import 'package:flutter/material.dart';
import 'package:restaurante_app/core/theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.children,
    this.isDarkMode = false,
    super.key,
  });

  final List<Widget> children;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDarkMode ? AppTheme.darkGradient : AppTheme.lightGradient;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}