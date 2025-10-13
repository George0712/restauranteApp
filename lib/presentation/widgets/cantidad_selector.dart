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
        color: Colors.grey.shade800.withValues(alpha: 0.5),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: enabled && cantidad > 1 
                ? () => onCantidadChanged(cantidad - 1)
                : null,
            icon: Icon(
              Icons.remove,
              color: enabled && cantidad > 1 
                  ? Colors.white
                  : Colors.white38,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              cantidad.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.white : Colors.white54,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? () => onCantidadChanged(cantidad + 1) : null,
            icon: Icon(
              Icons.add,
              color: enabled ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
} 