import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptionButtonCard extends ConsumerStatefulWidget {
  final Widget icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const OptionButtonCard({
    Key? key,
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  ConsumerState<OptionButtonCard> createState() => _OptionButtonCardState();
}

class _OptionButtonCardState extends ConsumerState<OptionButtonCard> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.95);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: widget.onTap,
      onTapUp: _onTapUp,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1F2937),
              Color.fromRGBO(55, 65, 81, 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color.fromRGBO(
              widget.color.r.toInt(),
              widget.color.g.toInt(),
              widget.color.b.toInt(),
              0.3,
            ),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Decoración de fondo
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                    widget.color.r.toInt(),
                    widget.color.g.toInt(),
                    widget.color.b.toInt(),
                    0.1,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                         Color.fromRGBO(
                           widget.color.r.toInt(),
                           widget.color.g.toInt(),
                           widget.color.b.toInt(),
                           0.8,
                         ),
                          widget.color,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(
                            widget.color.r.toInt(),
                            widget.color.g.toInt(),
                            widget.color.b.toInt(),
                            0.3,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: widget.icon,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.text,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
