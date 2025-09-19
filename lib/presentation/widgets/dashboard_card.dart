import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: "es_CO", symbol: "\$");

Widget buildNeonStatCard(
  WidgetRef ref, 
  String title, 
  String subtitle,
  StreamProvider<int> provider,
  Color color,
  IconData icon,
) {
  final asyncValue = ref.watch(provider);

  return asyncValue.when(
    data: (value) => buildNeonStatCardWithValue(title, subtitle, value, color, icon),
    loading: () => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color.fromRGBO(color.red, color.green, color.blue, 0.3),
          width: 1,
        ),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    ),
    error: (e, _) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.7), width: 1),
      ),
      child: Center(child: Text('Error', style: const TextStyle(color: Colors.white))),
    ),
  );
}

Widget buildNeonStatCardWithValue(
  String title,
  String subtitle,
  int value,
  Color color,
  IconData icon,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1117),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Color.fromRGBO(
          color.red,
          color.green,
          color.blue,
          0.3,
        ),
        width: 1,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con icono
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(
                      color.red,
                      color.green,
                      color.blue,
                      0.8,
                    ),
                    color,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      color.red,
                      color.green,
                      color.blue,
                      0.4,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Flexible(
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        Flexible(
          child: Text(
            subtitle,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}