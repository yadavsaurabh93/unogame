import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/background.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  children: [
                    _aniRule(
                        0,
                        "The Objective",
                        "Be the first player to get rid of all your cards in each round.",
                        Icons.emoji_events),
                    _aniRule(
                        1,
                        "Matching Cards",
                        "Play a card that matches the top card of the Discard pile in either color, number, or symbol.",
                        Icons.compare_arrows),
                    _aniRule(
                        2,
                        "Action Cards",
                        "Draw Two, Skip, and Reverse cards add fun twists to the game!",
                        Icons.star),
                    _aniRule(
                        3,
                        "Wild Cards",
                        "Wild and Wild Draw Four cards let you change the color of play.",
                        Icons.palette),
                    _aniRule(
                        4,
                        "Saying UNO",
                        "When you have only one card left, you must press the UNO button before someone calls you out!",
                        Icons.notification_important),
                    _aniRule(
                        5,
                        "Winning",
                        "The first player to reach 0 cards wins the round!",
                        Icons.celebration),
                    const SizedBox(height: 30),
                    _animatedEntrance(
                      index: 6,
                      child: Center(
                        child: Text(
                          "GOOD LUCK PLAYER!",
                          style: GoogleFonts.blackOpsOne(
                              color: Colors.blueAccent,
                              fontSize: 24,
                              letterSpacing: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aniRule(int i, String t, String d, IconData ic) {
    return _animatedEntrance(index: i, child: _ruleTile(t, d, ic));
  }

  Widget _animatedEntrance({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 120)),
      curve: Curves.easeOutCubic,
      builder: (ctx, double val, w) {
        return Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(40 * (1 - val), 0),
            child: w,
          ),
        );
      },
      child: child,
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          Text("HOW TO PLAY",
              style: GoogleFonts.blackOpsOne(
                  color: Colors.white, fontSize: 30, letterSpacing: 2)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _ruleTile(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(desc,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
