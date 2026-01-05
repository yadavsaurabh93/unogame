import 'dart:math';
import 'package:flutter/material.dart';

class ParticleSystem extends StatefulWidget {
  final Offset position;
  final Color color;
  const ParticleSystem({
    super.key,
    required this.position,
    required this.color,
  });
  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> particles = [];
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    for (int i = 0; i < 15; i++) particles.add(_Particle());
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (c, _) => CustomPaint(
        painter: _ParticlePainter(
            particles, _ctrl.value, widget.color, widget.position),
      ),
    );
  }
}

class _Particle {
  double angle = Random().nextDouble() * 2 * pi;
  double speed = Random().nextDouble() * 6 + 3;
  double size = Random().nextDouble() * 5 + 2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;
  final Offset origin;
  _ParticlePainter(this.particles, this.progress, this.color, this.origin);
  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = color.withOpacity(1 - progress)
      ..style = PaintingStyle.fill;
    for (var p in particles) {
      double d = p.speed * progress * 35;
      c.drawCircle(
          Offset(origin.dx + cos(p.angle) * d, origin.dy + sin(p.angle) * d),
          p.size * (1 - progress),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
