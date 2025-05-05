import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardCard extends ConsumerWidget {
  final String title;
  final Provider<int> countProvider;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.countProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(countProvider);

    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final padding = isTablet ? 16.0 : 8.0;
    final valueFontSize = isTablet ? 32.0 : 24.0;
    final titleFontSize = isTablet ? 20.0 : 16.0;
    final elevation = isTablet ? 8.0 : 4.0;

    final theme = Theme.of(context);

    return Card(
      color: Colors.white,  // <-- Fuerza fondo blanco
      elevation: elevation,
      shadowColor: theme.primaryColor.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$$count',
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            SizedBox(height: padding / 2),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
