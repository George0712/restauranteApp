import 'package:flutter/material.dart';

Widget buildEmptyState(BuildContext context, String text, IconData icon) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).padding.top + 200),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Icon(icon,
              size: 46, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
