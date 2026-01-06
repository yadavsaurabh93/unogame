import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uno_game/services/data_manager.dart';
import 'package:uno_game/widgets/background.dart';

class ElitePassScreen extends StatefulWidget {
  const ElitePassScreen({super.key});

  @override
  State<ElitePassScreen> createState() => _ElitePassScreenState();
}

class _ElitePassScreenState extends State<ElitePassScreen> {
  final List<Map<String, dynamic>> _passTiers = List.generate(50, (index) {
    int level = index + 1;
    String rewardName = "";
    IconData icon = Icons.help_outline;
    Color color = Colors.grey;
    bool isPremium = level % 3 == 0;

    if (level == 1) {
      rewardName = "500 Coins";
      icon = Icons.monetization_on;
      color = Colors.amber;
    } else if (level == 5) {
      rewardName = "Elite Banner";
      icon = Icons.brush;
      color = Colors.purpleAccent;
    } else if (level == 10) {
      rewardName = "Neon Avatar";
      icon = Icons.face;
      color = Colors.cyanAccent;
    } else if (level % 5 == 0) {
      rewardName = "${level * 200} Coins";
      icon = Icons.monetization_on;
      color = Colors.amber;
    } else {
      rewardName = isPremium ? "Premium Gift" : "Bonus Coins";
      icon = isPremium ? Icons.card_giftcard : Icons.circle;
      color = isPremium ? Colors.pinkAccent : Colors.white24;
    }

    return {
      "level": level,
      "reward": rewardName,
      "icon": icon,
      "color": color,
      "isPremium": isPremium,
    };
  });

  @override
  Widget build(BuildContext context) {
    int currentPassLevel = (DataManager.level / 2).floor();
    if (currentPassLevel > 50) currentPassLevel = 50;
    if (currentPassLevel < 1) currentPassLevel = 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("ELITE PASS",
            style: GoogleFonts.blackOpsOne(letterSpacing: 2)),
        centerTitle: true,
      ),
      body: ModernBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Header Card
            _buildHeader(currentPassLevel),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                physics: const BouncingScrollPhysics(),
                itemCount: _passTiers.length,
                itemBuilder: (context, index) {
                  final tier = _passTiers[index];
                  bool isUnlocked = tier['level'] <= currentPassLevel;
                  return _buildTierItem(tier, isUnlocked);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int currentLevel) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple[900]!.withOpacity(0.8),
              Colors.blue[900]!.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2), blurRadius: 20)
          ]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("GOD PULSE",
                      style: GoogleFonts.rajdhani(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2)),
                  Text("SEASON 1",
                      style: GoogleFonts.blackOpsOne(
                          color: Colors.white, fontSize: 24)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.4))),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Text("Tier $currentLevel",
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (DataManager.level % 10) / 10,
              backgroundColor: Colors.white10,
              color: Colors.cyanAccent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("XP: ${((DataManager.level % 10) * 100).toInt()} / 1000",
                  style:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              Text("Next Reward: T-${currentLevel + 1}",
                  style: GoogleFonts.poppins(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTierItem(Map<String, dynamic> tier, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        DataManager.playSound();
        _showRewardPopup(tier, isUnlocked);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        child: Row(
          children: [
            // Level Indicator
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text("${tier['level']}",
                  style: GoogleFonts.blackOpsOne(
                      color: isUnlocked ? Colors.cyanAccent : Colors.white24,
                      fontSize: 20)),
            ),
            const SizedBox(width: 10),
            // Reward Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isUnlocked
                          ? Colors.cyanAccent.withOpacity(0.3)
                          : Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (tier['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tier['icon'] as IconData,
                          color: isUnlocked
                              ? tier['color'] as Color
                              : Colors.white24,
                          size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tier['reward'],
                              style: GoogleFonts.poppins(
                                  color: isUnlocked
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.bold)),
                          if (tier['isPremium'])
                            Text("PREMIUM ONLY",
                                style: GoogleFonts.poppins(
                                    color: Colors.pinkAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                        ],
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 20)
                    else
                      Icon(Icons.lock_outline,
                          color: Colors.white.withOpacity(0.2), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardPopup(Map<String, dynamic> tier, bool isUnlocked) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: isUnlocked ? Colors.cyanAccent : Colors.redAccent,
                  width: 2),
              boxShadow: [
                BoxShadow(
                    color: (isUnlocked ? Colors.cyanAccent : Colors.redAccent)
                        .withOpacity(0.3),
                    blurRadius: 30)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUnlocked ? Icons.check_circle_outline : Icons.lock,
                  size: 60,
                  color: isUnlocked ? Colors.cyanAccent : Colors.redAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  isUnlocked ? "REWARD UNLOCKED" : "REWARD LOCKED",
                  style: GoogleFonts.blackOpsOne(
                      color: Colors.white, fontSize: 22, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Text(
                  isUnlocked
                      ? "You have unlocked this reward!"
                      : "Reach Level ${tier['level']} to unlock!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tier['icon'], size: 30, color: tier['color']),
                      const SizedBox(width: 15),
                      Text(tier['reward'],
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    DataManager.playSound();
                    Navigator.pop(ctx);
                    if (isUnlocked) {
                      // Claim logic could go here
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Reward Claimed!"),
                          backgroundColor: Colors.green));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          isUnlocked ? Colors.cyan : Colors.blueGrey,
                          isUnlocked ? Colors.blueAccent : Colors.grey
                        ]),
                        borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      isUnlocked ? "CLAIM REWARD" : "KEEP PLAYING",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                          color: Colors.white, fontSize: 18),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
