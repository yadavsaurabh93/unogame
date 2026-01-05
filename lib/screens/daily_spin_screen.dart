import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../widgets/background.dart';
import '../widgets/modern_button.dart';

class DailySpinScreen extends StatefulWidget {
  const DailySpinScreen({super.key});

  @override
  State<DailySpinScreen> createState() => _DailySpinScreenState();
}

class _DailySpinScreenState extends State<DailySpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;
  bool _spinning = false;
  int _reward = 0;
  final List<int> _rewards = [100, 50, 500, 200, 1000, 300, 150, 50];
  final List<Color> _colors = const [
    Color(0xFFFF0000),
    Color(0xFF0000FF),
    Color(0xFFFFD700),
    Color(0xFF00FF00),
    Color(0xFF800080),
    Color(0xFFFFA500),
    Color(0xFF00FFFF),
    Color(0xFFFF1493)
  ];

  @override
  void initState() {
    super.initState();
    _checkSpinAvailability();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4)); // smoother
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.decelerate);
  }

  void _checkSpinAvailability() {
    String today = DateTime.now().toIso8601String().split('T')[0];
    if (DataManager.lastSpinDate != today) {
      DataManager.lastSpinDate = today;
      DataManager.dailySpinsUsed = 0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning) return;
    if (DataManager.dailySpinsUsed >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Daily limit reached! Come back tomorrow."),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _spinning = true);
    // Ensure at least 5 full spins + random
    double baseRot = _ctrl.value; // Start from current
    double targetRot =
        baseRot + (5 * 2 * pi) + (Random().nextDouble() * (2 * pi));

    _ctrl.duration = const Duration(seconds: 4);

    // We need to animate from 'baseRot' to 'targetRot'.
    // AnimationController works better 0->1.
    // Let's us animateTo? No, easier to reimplement Tween.
    _ctrl.reset();
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.decelerate);

    // We treat the "value" of controller as 0..1, and map it to rotation.
    // But we want to start from current visual rotation?
    // Actually simpler: Just reset to 0? No, that jumps.
    // Logic: `currentRotation % 2pi` -> Start there.
    // But easier: Reset to 0 works fine if we assume the wheel is symmetrical/stateless or if we always land on a center?
    // User won't notice a jump if it starts spinning fast immediately.
    // Let's try standard spin wheel logic:

    double spins = 5 + Random().nextDouble();
    double angle = spins * 2 * pi;

    _ctrl.forward(from: 0).then((_) {
      // Completed
      double finalRot = angle;
      // Calc index
      // Rot starts at 0?
      // Let's rely on the animation value mapping.
    });

    // Actually, let's fix the logic to be robust.
    // We will just animate 0 -> 1. And use that to interpolate 0 -> angle.
    // In build: Rotation = animation.value * angle.
  }

  // Proper simplified spin
  void _startSpin() {
    if (_spinning) return;
    if (DataManager.dailySpinsUsed >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Daily limit reached!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _spinning = true);
    double spins = 5 + Random().nextDouble();
    double endAngle = spins * 2 * pi;

    // Reset controller
    _ctrl.reset();

    Animation<double> curve =
        CurvedAnimation(parent: _ctrl, curve: Curves.decelerate);
    // Explicitly drive the rotation
    _animation = Tween<double>(begin: 0, end: endAngle).animate(curve)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _calculateReward(endAngle);
        }
      });

    _ctrl.forward();
  }

  void _calculateReward(double totalAngle) {
    double anglePerItem = (2 * pi) / _rewards.length;

    // The wheel rotates clockwise by totalAngle.
    // To find what's under the static pointer at the top:
    double normalizedRotation = totalAngle % (2 * pi);
    double winningPosition = (2 * pi - normalizedRotation) % (2 * pi);

    // Use floor to get the exact index under the pointer
    int index = (winningPosition / anglePerItem).floor() % _rewards.length;

    setState(() {
      _spinning = false;
      _reward = _rewards[index];
      DataManager.coins += _reward;
      DataManager.dailySpinsUsed += 1;
    });
    _showWinDialog();
  }

  void _showWinDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Stack(alignment: Alignment.center, children: [
              // Glow
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(color: Colors.amber, blurRadius: 50)
                    ]),
              ),
              AlertDialog(
                backgroundColor: Colors.black.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.amber, width: 2)),
                title: Center(
                    child: Text("JACKPOT!",
                        style: GoogleFonts.blackOpsOne(
                            color: Colors.amber, fontSize: 32))),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars,
                        color: Colors.yellowAccent, size: 80),
                    const SizedBox(height: 20),
                    Text("+ $_reward",
                        style: GoogleFonts.blackOpsOne(
                            color: Colors.white, fontSize: 50)),
                    Text("COINS",
                        style: GoogleFonts.poppins(color: Colors.white70)),
                  ],
                ),
                actions: [
                  Center(
                      child: ModernButton(
                          label: "CLAIM REWARD",
                          width: 200,
                          onTap: () => Navigator.pop(ctx),
                          icon: Icons.check_circle,
                          baseColor: Colors.green))
                ],
              )
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildWheelSection(),
                        const SizedBox(height: 40),
                        _buildFooterStats(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            "DAILY SPIN",
            style: GoogleFonts.blackOpsOne(
              color: Colors.white,
              fontSize: 26,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.blueAccent, blurRadius: 10),
              ],
            ),
          ),
          const Spacer(),
          _buildCoinDisplay(),
        ],
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            "${DataManager.coins}",
            style: GoogleFonts.blackOpsOne(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing Outer Glow
        _buildPulsingGlow(),

        // Decorative Ring
        Container(
          width: 325,
          height: 325,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.purple.withOpacity(0.2),
                Colors.blue.withOpacity(0.2),
              ],
            ),
            border: Border.all(color: Colors.white12, width: 2),
          ),
        ),

        // The Wheel
        Transform.rotate(
          angle: _animation.value,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: WheelPainter(rewards: _rewards, colors: _colors),
            ),
          ),
        ),

        // Outer Static Rim with Dots
        _buildOuterRimDots(),

        // Pointer (Modernized)
        Positioned(
          top: -15,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent, blurRadius: 15),
                  ],
                ),
                child: const Icon(Icons.arrow_drop_down,
                    color: Colors.red, size: 30),
              ),
            ],
          ),
        ),

        // Center Spin Button
        GestureDetector(
          onTap: _startSpin,
          child: Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white, Colors.grey[300]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: Colors.blueAccent, width: 5),
            ),
            child: Center(
              child: Text(
                "SPIN",
                style: GoogleFonts.blackOpsOne(
                  color: Colors.black,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingGlow() {
    return Container(
      width: 360,
      height: 360,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.15),
            blurRadius: 60,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildOuterRimDots() {
    return Container(
      width: 310,
      height: 310,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38, width: 6),
      ),
      child: Stack(
        children: List.generate(12, (index) {
          double angle = (index * 30) * pi / 180;
          return Align(
            alignment: Alignment(cos(angle), sin(angle)),
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooterStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("TOP REWARD", "1000", Colors.greenAccent),
            Container(width: 1, height: 40, color: Colors.white12),
            _buildStatItem("SPINS LEFT", "${2 - DataManager.dailySpinsUsed}/2",
                Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.blackOpsOne(
            color: color,
            fontSize: 26,
            shadows: [
              Shadow(color: color.withOpacity(0.5), blurRadius: 10),
            ],
          ),
        ),
      ],
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<int> rewards;
  final List<Color> colors;
  WheelPainter({required this.rewards, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2;
    double angle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      // Slice with Gradient
      Paint p = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i],
            colors[i].withOpacity(0.7),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          (i * angle) - pi / 2, angle, true, p);

      // Radial Line/Divider
      Paint lineP = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      double startX = center.dx + 40 * cos((i * angle) - pi / 2);
      double startY = center.dy + 40 * sin((i * angle) - pi / 2);
      double endX = center.dx + radius * cos((i * angle) - pi / 2);
      double endY = center.dy + radius * sin((i * angle) - pi / 2);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), lineP);

      // Text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i * angle) - pi / 2 + angle / 2);
      canvas.translate(radius * 0.72, 0);
      canvas.rotate(pi / 2);

      TextPainter tp = TextPainter(
        text: TextSpan(
          text: "${rewards[i]}",
          style: GoogleFonts.blackOpsOne(
            color: Colors.white,
            fontSize: 14,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
