import 'package:flutter/material.dart';

class ModernBackground extends StatelessWidget {
  final Widget child;
  const ModernBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F1A),
      child: Stack(
        children: [
          // Animated Background Glow 1
          Positioned(
            top: -100,
            left: -100,
            child:
                _AnimatedGlow(color: Colors.blue.withOpacity(0.15), size: 400),
          ),
          // Animated Background Glow 2
          Positioned(
            bottom: -150,
            right: -100,
            child: _AnimatedGlow(
                color: Colors.purple.withOpacity(0.15), size: 500),
          ),
          child,
        ],
      ),
    );
  }
}

class _AnimatedGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AnimatedGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 10),
      builder: (context, double val, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: 150,
                spreadRadius: 50,
              )
            ],
          ),
        );
      },
    );
  }
}
