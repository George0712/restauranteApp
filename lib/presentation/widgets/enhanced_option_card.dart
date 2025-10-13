import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnhancedOptionCard extends ConsumerStatefulWidget {
  final Widget icon;
  final String text;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const EnhancedOptionCard({
    super.key,
    required this.icon,
    required this.text,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  ConsumerState<EnhancedOptionCard> createState() => EnhancedOptionCardState();
}

class EnhancedOptionCardState extends ConsumerState<EnhancedOptionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color.fromRGBO(255, 255, 255, _isPressed ? 0.3 : 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      widget.color.r.toInt(),
                      widget.color.g.toInt(),
                      widget.color.b.toInt(),
                      _isPressed ? 0.2 : 0.3,
                    ),
                    blurRadius: _isPressed ? 4 : 6,
                    spreadRadius: 0,
                    offset: Offset(0, _isPressed ? 2 : 3),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _isPressed ? Color.fromRGBO(
                      widget.color.r.toInt(),
                      widget.color.g.toInt(),
                      widget.color.b.toInt(),
                      0.8,
                    ) : widget.color,
                    _isPressed ? Color.fromRGBO(
                      widget.color.r.toInt(),
                      widget.color.g.toInt(),
                      widget.color.b.toInt(),
                      0.6,
                    ) : Color.fromRGBO(
                      widget.color.r.toInt(),
                      widget.color.g.toInt(),
                      widget.color.b.toInt(),
                      0.8,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decoration circles
                  Positioned(
                    right: -15,
                    top: -15,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(255, 255, 255, _isPressed ? 0.08 : 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(255, 255, 255, _isPressed ? 0.03 : 0.05),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.icon,
                        const Spacer(),
                        Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromRGBO(255, 255, 255, 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
