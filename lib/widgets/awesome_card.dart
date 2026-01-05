import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uno_game/models/uno_card.dart';
import 'package:uno_game/services/data_manager.dart';

class AwesomeCard extends StatelessWidget {
  final UnoCard card;
  final Size size;
  final bool glow;
  final String? deck;
  const AwesomeCard({
    super.key,
    required this.card,
    required this.size,
    this.glow = false,
    this.deck,
  });

  String _getCharacterAsset() {
    String d = (deck ?? DataManager.selectedDeck).toLowerCase();

    // SPIDER-MAN DECK (Pure Spiderman, Max Variety)
    if (d.contains("spiderman")) {
      int sVal = int.tryParse(card.symbol) ?? (card.symbol.hashCode % 10);

      if (card.color == CardColor.red) {
        // Variety for Red
        if (sVal % 3 == 0) return "assets/spiderman_classic.png";
        if (sVal % 3 == 1) return "assets/spiderman_miles.png";
        return "assets/spiderman_mask.png";
      }
      if (card.color == CardColor.blue) {
        // Variety for Blue
        if (sVal % 3 == 0) return "assets/spiderman_shield.png";
        if (sVal % 3 == 1) return "assets/spiderman_armor.png";
        return "assets/spiderman_standing.png";
      }
      if (card.color == CardColor.yellow) {
        // Variety for Yellow
        if (sVal % 3 == 0) return "assets/spiderman_hanging.png";
        if (sVal % 3 == 1) return "assets/spiderman_swing_2.png";
        return "assets/spiderman_logo.png";
      }
      if (card.color == CardColor.green) {
        // Variety for Green
        if (sVal % 3 == 0) return "assets/spiderman_action.png";
        if (sVal % 3 == 1) return "assets/spiderman_comic.png";
        return "assets/spiderman_classic.png";
      }
      // Wild/Black cards
      return (sVal % 2 == 0)
          ? "assets/spiderman_standing.png"
          : "assets/spiderman_logo.png";
    }

    // IRONMAN DECK (Pure Ironman, Max Variety)
    if (d.contains("ironman")) {
      int sVal = int.tryParse(card.symbol) ?? (card.symbol.hashCode % 10);

      if (card.color == CardColor.red) {
        if (sVal % 3 == 0) return "assets/ironman_fly.png";
        if (sVal % 3 == 1) return "assets/ironman_blast.png";
        return "assets/tony_stark_full_body.png";
      }
      if (card.color == CardColor.yellow) {
        if (sVal % 3 == 0) return "assets/ironman_land.png";
        if (sVal % 3 == 1) return "assets/ironman_kneel.png";
        return "assets/hulkbuster.png";
      }
      if (card.color == CardColor.blue) {
        if (sVal % 3 == 0) return "assets/ironman_flying.png";
        if (sVal % 3 == 1) return "assets/ironman_pose_1.png";
        return "assets/tony_stark_half.png";
      }
      if (card.color == CardColor.green) {
        if (sVal % 3 == 0) return "assets/ironman_pose_2.png";
        if (sVal % 3 == 1) return "assets/ironman_standing.png";
        return "assets/ironman_logo_circle.png";
      }
      // Black/Special
      return (sVal % 2 == 0)
          ? "assets/ironman_logo_circle.png"
          : "assets/ironman_standing.png";
    }

    // NARUTO DECK (Updated visuals)
    if (d.contains("naruto")) {
      // Use abs() to ensure positive index
      int sVal = (int.tryParse(card.symbol) ?? card.symbol.hashCode).abs();

      // Distribute assets across colors for max variety
      // EXPANDED VERSE V2:
      // Red: Power (Rasengan, Pain, Minato Cloak)
      // Blue: Skill (Sasuke, Minato, Kakashi)
      // Yellow: Legends (Jiraiya, Itachi, Gaara)
      // Green: Mix (Obito, Naruto Last, Naruto Standing)

      if (card.color == CardColor.red) {
        if (sVal % 3 == 0) return "assets/naruto_base.png"; // Replaced rasengan
        if (sVal % 3 == 1) return "assets/pain.png";
        return "assets/minato_cloak.png";
      }
      if (card.color == CardColor.blue) {
        if (sVal % 3 == 0) return "assets/pain.png";
        if (sVal % 3 == 1) return "assets/minato_cloak.png"; // Replaced minato
        return "assets/kakashi_new.png";
      }
      if (card.color == CardColor.yellow) {
        if (sVal % 3 == 0) return "assets/jiraiya.png";
        if (sVal % 3 == 1) return "assets/itachi.png";
        return "assets/gaara.png";
      }
      if (card.color == CardColor.green) {
        if (sVal % 3 == 0) return "assets/obito.png";
        if (sVal % 3 == 1) return "assets/naruto_last.png";
        return "assets/naruto_standing.png";
      }
      // Wilds - Use the new Base (Kid) and Itachi
      return (sVal % 2 == 0) ? "assets/naruto_base.png" : "assets/itachi.png";
    }

    // JJK DECK
    if (d.contains("jjk") || d.contains("jujutsu")) {
      if (card.color == CardColor.red)
        return "assets/sukuna.png"; // Replaced itadori
      if (card.color == CardColor.blue) return "assets/gojo.png";
      if (card.color == CardColor.yellow)
        return "assets/toji.png"; // Replaced megumi
      if (card.color == CardColor.green)
        return "assets/gojo.png"; // Replaced nobara
      return "assets/logo.png";
    }

    // ONE PIECE DECK
    if (d.contains("one piece") || d.contains("onepiece")) {
      if (card.color == CardColor.red) return "assets/luffy.png";
      if (card.color == CardColor.blue) return "assets/zoro.png";
      if (card.color == CardColor.yellow) return "assets/sanji.png";
      if (card.color == CardColor.green) return "assets/nami.png";
      return "assets/op_logo.png";
    }

    // CARS DECK (Premium Cars Variety)
    if (d.contains("cars") || d.contains("bmw")) {
      int sVal = (int.tryParse(card.symbol) ?? card.symbol.hashCode).abs();

      if (card.color == CardColor.red) {
        if (sVal % 3 == 0) return "assets/cars_ferrari.png";
        if (sVal % 3 == 1) return "assets/cars_hellcat.png";
        return "assets/cars_orange_bmw.png";
      }
      if (card.color == CardColor.blue) {
        if (sVal % 3 == 0) return "assets/cars_amg.png";
        if (sVal % 3 == 1) return "assets/cars_audi.png";
        return "assets/cars_blue_bmw.png";
      }
      if (card.color == CardColor.yellow) {
        if (sVal % 2 == 0) return "assets/cars_lambo.png";
        return "assets/cars_orange_bmw.png";
      }
      if (card.color == CardColor.green) {
        if (sVal % 2 == 0) return "assets/cars_fortuner.png";
        return "assets/cars_gwagon.png";
      }
      // Wild/Special - Performance & Utility
      if (sVal % 3 == 0) return "assets/cars_f1.png";
      if (sVal % 3 == 1) return "assets/cars_defender.png";
      return "assets/cars_audi.png";
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    String asset = _getCharacterAsset();
    bool hasPhoto = asset.isNotEmpty;

    // Feature: If deck is "Avatar Deck" or similar, show player's photo
    bool isPlayerPhotoCard =
        (deck ?? DataManager.selectedDeck).toLowerCase().contains("avatar") &&
            DataManager.profilePicPath != null;

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white, // Outer white border
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2, 4),
            blurRadius: 6,
          ),
          if (glow)
            BoxShadow(
              color: card.colorHex.withOpacity(0.8),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      padding: const EdgeInsets.all(4), // Inner spacing for border
      child: Container(
        decoration: BoxDecoration(
          color: card.colorHex,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 1. Subtle Big Number in Background (Top Right)
            Positioned(
              top: 5,
              right: 8,
              child: Opacity(
                opacity: 0.15,
                child: Text(
                  card.symbol,
                  style: GoogleFonts.poppins(
                    fontSize: size.width * 0.4,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // 2. Corner Symbols
            Positioned(
              top: 4,
              left: 6,
              child: Text(
                card.symbol,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size.width * 0.18,
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 6,
              child: RotatedBox(
                quarterTurns: 2,
                child: Text(
                  card.symbol,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.18,
                  ),
                ),
              ),
            ),

            // 3. Center Design (Tilted White Ellipse)
            Center(
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: size.width * 0.8,
                  height: size.height * 0.45,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.all(Radius.elliptical(
                          size.width * 0.8, size.height * 0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        )
                      ]),
                ),
              ),
            ),

            // 4. Center Content (The Photo or Character)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: isPlayerPhotoCard
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(DataManager.profilePicPath!),
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => _symbolText(),
                        ),
                      )
                    : hasPhoto
                        ? Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            height: size.height * 0.65,
                            errorBuilder: (ctx, err, st) => _symbolText(),
                          )
                        : _symbolText(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _symbolText() {
    return Text(
      card.symbol,
      textAlign: TextAlign.center,
      style: GoogleFonts.righteous(
        fontSize: size.width * 0.45,
        color: card.colorHex, // Symbol color matches card color on white oval
        shadows: [
          const Shadow(
            color: Colors.black12,
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}

class AwesomeBack extends StatelessWidget {
  final Size size;
  final String? deck;
  const AwesomeBack({super.key, required this.size, this.deck});
  @override
  Widget build(BuildContext context) {
    String d = (deck ?? "").toLowerCase();

    // CUSTOM BACKS
    if (d.contains("spiderman")) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blueAccent, width: 2),
          image: const DecorationImage(
            image: AssetImage("assets/spiderman_mask.png"),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (d.contains("ironman")) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.redAccent.shade700,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.amber, width: 2),
          image: const DecorationImage(
            image: AssetImage("assets/ironman_logo_circle.png"),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (d.contains("cars") || d.contains("bmw")) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blueAccent, width: 2),
          gradient: const RadialGradient(
            colors: [Colors.blueGrey, Colors.black],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.settings_input_component,
                color: Colors.blueAccent,
                size: 40,
              ),
              Text(
                "FAST",
                style: GoogleFonts.blackOpsOne(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // DEFAULT UNO BACK
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF111),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade800, width: 2),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Text(
            "UNO",
            style: GoogleFonts.blackOpsOne(
              fontSize: size.width * 0.2,
              color: Colors.yellow,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
