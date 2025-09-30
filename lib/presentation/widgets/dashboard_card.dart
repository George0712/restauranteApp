import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

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
    data: (value) =>
        buildNeonStatCardWithValue(title, subtitle, value, color, icon),
    loading: () => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.fromRGBO(color.red, color.green, color.blue, 0.28),
          width: 1,
        ),
      ),
      constraints: const BoxConstraints(minHeight: 150),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Colors.white),
    ),
    error: (e, _) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.7), width: 1),
      ),
      constraints: const BoxConstraints(minHeight: 150),
      alignment: Alignment.center,
      child: const Text(
        'Error',
        style: TextStyle(color: Colors.white),
      ),
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
    padding: const EdgeInsets.all(20),
    constraints: const BoxConstraints(minHeight: 150),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1117),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Color.fromRGBO(
          color.red,
          color.green,
          color.blue,
          0.28,
        ),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
