import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlowAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final int count;
  const GlowAvatar({
    super.key,
    required this.name,
    required this.color,
    required this.count,
  });
  String _getAvatarAsset() {
    String n = name.toLowerCase();
    if (n.contains("lion")) return "assets/lion_king.png";
    if (n.contains("tiger")) return "assets/tiger_strike.png";
    if (n.contains("wolf")) return "assets/wolf_shadow.png";
    if (n.contains("male")) return "assets/super_male.png";
    if (n.contains("ninja")) return "assets/ninja_boy.png";
    if (n.contains("female")) return "assets/wonder_female.png";
    if (n.contains("empress")) return "assets/empress.png";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    String asset = _getAvatarAsset();
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2), // Clean ring
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 4),
                )
              ],
            ), // Clean shadow
            child: CircleAvatar(
              backgroundColor: const Color(0xFF2C2C2C), // Matte Dark
              radius: 25,
              backgroundImage: asset.isNotEmpty ? AssetImage(asset) : null,
              child: asset.isEmpty ? Icon(Icons.person, color: color) : null,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 20,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Text(
            "$count Cards",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
