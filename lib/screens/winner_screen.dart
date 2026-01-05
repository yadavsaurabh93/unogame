import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/modern_button.dart';
import 'lobby_screen.dart';
import 'main_menu_screen.dart';

class WinnerScreen extends StatefulWidget {
  final String w;
  final bool m;
  final bool isOnline;
  final String? roomId;
  final String? myId;
  final String? myName;
  final bool isHost;

  const WinnerScreen(
      {super.key,
      required this.w,
      required this.m,
      required this.isOnline,
      this.roomId,
      this.myId,
      this.myName,
      required this.isHost});

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _shockwaveCtrl;

  final List<StarParticle> stars = [];
  final _db = FirebaseDatabase.instance.ref();
  Random ra = Random();

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _shockwaveCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _mainCtrl.forward();
    _shockwaveCtrl.forward();

    // Spawn star field
    for (int i = 0; i < 60; i++) {
      stars.add(StarParticle(
        pos: Offset(ra.nextDouble(), ra.nextDouble()),
        size: ra.nextDouble() * 2.5 + 0.5,
        speed: ra.nextDouble() * 0.005 + 0.002,
      ));
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _shockwaveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.m ? Colors.amber : Colors.redAccent;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. STARFIELD BACKGROUND
          _StarField(stars: stars, color: themeColor),

          // 2. SWEEPING VORTEX (Background Glow)
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (c, _) => Center(
              child: Transform.rotate(
                angle: _rotateCtrl.value * 2 * pi,
                child: Container(
                  width: size.width * 1.5,
                  height: size.width * 1.5,
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        themeColor.withOpacity(0),
                        themeColor.withOpacity(0.15),
                        themeColor.withOpacity(0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. EXPANDING SHOCKWAVE RING
          AnimatedBuilder(
            animation: _shockwaveCtrl,
            builder: (c, _) {
              if (_shockwaveCtrl.value >= 1.0) return const SizedBox.shrink();
              return Center(
                child: Container(
                  width: _shockwaveCtrl.value * size.width * 2,
                  height: _shockwaveCtrl.value * size.width * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeColor.withOpacity(1 - _shockwaveCtrl.value),
                      width: 15 * (1 - _shockwaveCtrl.value),
                    ),
                  ),
                ),
              );
            },
          ),

          // 4. MAIN UI CONTENT
          Center(
            child: ScaleTransition(
              scale:
                  CurvedAnimation(parent: _mainCtrl, curve: Curves.elasticOut),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Floating & Pulsing Icon
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (c, _) => Transform.translate(
                      offset: Offset(0, sin(_pulseCtrl.value * 2 * pi) * 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft Ambient Glow
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.4),
                                  blurRadius: 80,
                                  spreadRadius: 10,
                                )
                              ],
                            ),
                          ),
                          Icon(
                            widget.m ? Icons.emoji_events : Icons.dangerous,
                            size: 140,
                            color: themeColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // SHIMMERING GLOW TEXT
                  _ShimmerText(text: widget.w, color: themeColor),

                  const SizedBox(height: 70),

                  // UI BUTTONS (Fade In)
                  FadeTransition(
                    opacity: _mainCtrl,
                    child: Column(
                      children: [
                        if (widget.isOnline && widget.roomId != null)
                          ModernButton(
                            label: "READY TO LOBBY",
                            onTap: () {
                              if (widget.isHost) {
                                _db.child("rooms/${widget.roomId}").update({
                                  "status": "w",
                                  "winners": null,
                                  "penalty": 0
                                });
                              }
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => LobbyScreen(
                                            autoJoinRoom: widget.roomId,
                                            autoJoinPid: widget.myId,
                                            autoJoinName: widget.myName,
                                            isHost: widget.isHost,
                                          )));
                            },
                            icon: Icons.refresh_rounded,
                            baseColor: Colors.blueAccent,
                          ),
                        const SizedBox(height: 18),
                        ModernButton(
                          label: "EXIT TO MENU",
                          onTap: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const MainMenuScreen()),
                            (route) => false,
                          ),
                          icon: Icons.home_filled,
                          baseColor: Colors.white12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// STARRY BACKGROUND COMPONENTS
class _StarField extends StatefulWidget {
  final List<StarParticle> stars;
  final Color color;
  const _StarField({required this.stars, required this.color});

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
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
        painter: StarPainter(
            stars: widget.stars, color: widget.color, progress: _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  final List<StarParticle> stars;
  final Color color;
  final double progress;
  StarPainter(
      {required this.stars, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.3);
    for (var s in stars) {
      double x = s.pos.dx * size.width;
      double y = (s.pos.dy + (progress * s.speed)) % 1.0 * size.height;
      canvas.drawCircle(Offset(x, y), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class StarParticle {
  Offset pos;
  double size;
  double speed;
  StarParticle({required this.pos, required this.size, required this.speed});
}

// SHIMMER TEXT COMPONENT
class _ShimmerText extends StatefulWidget {
  final String text;
  final Color color;
  const _ShimmerText({required this.text, required this.color});

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
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
      builder: (c, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.color,
                Colors.white,
                widget.color,
              ],
              stops: [
                _ctrl.value - 0.2,
                _ctrl.value,
                _ctrl.value + 0.2,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.blackOpsOne(
              fontSize: 75,
              color: Colors.white,
              letterSpacing: 4,
              shadows: [
                Shadow(color: widget.color.withOpacity(0.6), blurRadius: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
