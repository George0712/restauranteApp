import 'dart:math';

import 'package:flutter/material.dart';

class OptionButtonCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const OptionButtonCard({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0.5,
        child: Container(
          padding: const EdgeInsets.all(4),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: min(50, 80), color: Colors.black),
              const SizedBox(height: 8),
              Text(
                text,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
