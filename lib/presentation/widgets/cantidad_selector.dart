import 'package:flutter/material.dart';

class CantidadSelector extends StatelessWidget {
  final int cantidad;
  final ValueChanged<int> onCantidadChanged;
  final bool enabled;

  const CantidadSelector({
    super.key,
    required this.cantidad,
    required this.onCantidadChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: enabled && cantidad > 1 
                ? () => onCantidadChanged(cantidad - 1)
                : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 40,
            child: Text(
              cantidad.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? () => onCantidadChanged(cantidad + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
} 