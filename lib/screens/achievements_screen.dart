import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../widgets/background.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> achievements = [
      // --- WINS (Elite Tiers) ---
      _createWinAchievement(1, "First Blood", "First online win",
          Icons.military_tech, Colors.redAccent),
      _createWinAchievement(
          5, "Rookie", "5 online wins", Icons.person_pin, Colors.blueGrey),
      _createWinAchievement(
          10, "Soldier", "10 online wins", Icons.security, Colors.blue),
      _createWinAchievement(
          25, "Warrior", "25 online wins", Icons.shield, Colors.cyan),
      _createWinAchievement(50, "Veteran", "50 online wins",
          Icons.military_tech_outlined, Colors.orange),
      _createWinAchievement(
          100, "Commander", "100 online wins", Icons.star, Colors.amber),
      _createWinAchievement(250, "General", "250 online wins",
          Icons.workspace_premium, Colors.deepOrange),
      _createWinAchievement(
          500, "Elite Hero", "500 online wins", Icons.bolt, Colors.white),
      _createWinAchievement(1000, "Legend", "1000 online wins",
          Icons.emoji_events, Colors.yellowAccent),
      _createWinAchievement(2000, "Immortal", "2000 online wins",
          Icons.auto_awesome, Colors.purpleAccent),

      // --- COINS (Fortune Tiers) ---
      // --- COINS (Fortune Tiers) ---
      _createCoinAchievement(
          1000, "Small Change", "1K coins", Icons.savings, Colors.green),
      _createCoinAchievement(
          5000, "Saving Up", "5K coins", Icons.wallet, Colors.teal),
      _createCoinAchievement(10000, "Wealthy", "10K coins",
          Icons.monetization_on, Colors.greenAccent),
      _createCoinAchievement(
          50000, "Rich", "50K coins", Icons.account_balance, Colors.cyanAccent),
      _createCoinAchievement(
          100000, "Tycoon", "100K coins", Icons.diamond, Colors.blueAccent),
      _createCoinAchievement(
          500000, "Millionaire", "500K coins", Icons.stars, Colors.yellow),
      _createCoinAchievement(1000000, "Gold Lord", "1 Million coins",
          Icons.all_inclusive, Colors.orange),
      _createCoinAchievement(10000000, "Trillionaire", "10 Million coins",
          Icons.public, Colors.purple),
      _createCoinAchievement(100000000, "Economic Ruler", "100 Million coins",
          Icons.key, Colors.white),

      // --- LEVELS (Evolution Tiers) ---
      _createLevelAchievement(
          2, "Beginner", "Lvl 2 reached", Icons.star_border, Colors.grey),
      _createLevelAchievement(
          5, "Apprentice", "Lvl 5 reached", Icons.star_half, Colors.blueGrey),
      _createLevelAchievement(
          10, "Skilled", "Lvl 10 reached", Icons.star, Colors.blue),
      _createLevelAchievement(
          20, "Expert", "Lvl 20 reached", Icons.verified, Colors.cyan),
      _createLevelAchievement(30, "Master", "Lvl 30 reached",
          Icons.workspace_premium, Colors.amber),
      _createLevelAchievement(
          50, "Elite", "Lvl 50 reached", Icons.military_tech, Colors.orange),
      _createLevelAchievement(75, "Grandmaster", "Lvl 75 reached",
          Icons.auto_awesome, Colors.purpleAccent),
      _createLevelAchievement(
          100, "God Like", "Lvl 100 reached", Icons.bolt, Colors.yellowAccent),
      _createLevelAchievement(
          200, "Supreme Being", "Lvl 200 reached", Icons.shield, Colors.white),
      _createLevelAchievement(500, "Ultimate Ruler", "Lvl 500 reached",
          Icons.all_inclusive, Colors.cyanAccent),

      // --- COLLECTION TIERS (The Curator) ---
      _createDeckAchievement(
          1, "Starter", "1 Deck owned", Icons.style, Colors.blueGrey),
      _createDeckAchievement(
          3, "Hobbyist", "3 Decks owned", Icons.layers, Colors.brown),
      _createDeckAchievement(5, "Collector", "5 Decks owned",
          Icons.view_carousel, Colors.purpleAccent),
      _createDeckAchievement(10, "Archive", "10 Decks owned",
          Icons.auto_awesome_motion, Colors.indigoAccent),
      _createDeckAchievement(20, "Deck Emperor", "20 Decks owned",
          Icons.library_books, Colors.amberAccent),

      _createAvatarAchievement(
          1, "New Face", "1 Avatar owned", Icons.face, Colors.pink),
      _createAvatarAchievement(5, "Identity", "5 Avatars owned", Icons.person,
          Colors.deepOrangeAccent),
      _createAvatarAchievement(
          10, "Masquerade", "10 Avatars owned", Icons.groups, Colors.blue),
      _createAvatarAchievement(25, "Avatar Lord", "25 Avatars owned",
          Icons.supervised_user_circle, Colors.purple),

      _createBannerAchievement(
          1, "Style", "1 Banner owned", Icons.brush, Colors.limeAccent),
      _createBannerAchievement(5, "Decorator", "5 Banners owned", Icons.palette,
          Colors.lightBlueAccent),
      _createBannerAchievement(
          10, "Artist", "10 Banners owned", Icons.art_track, Colors.purple),
      _createBannerAchievement(25, "Banner Emperor", "25 Banners owned",
          Icons.flag, Colors.redAccent),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("ACHIEVEMENTS",
            style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 24)),
        centerTitle: true,
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _statsHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: achievements.length,
                  itemBuilder: (ctx, i) => _achievementCard(achievements[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("WINS", DataManager.wins.toString(), Colors.cyanAccent),
          _statItem("LVL", DataManager.level.toString(), Colors.amber),
          _statItem("COINS", DataManager.coins.toString(), Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 22)),
        Text(label,
            style: GoogleFonts.poppins(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _achievementCard(Map<String, dynamic> data) {
    bool unlocked = data['unlocked'];
    Color color = data['color'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            unlocked ? color.withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: unlocked ? color.withOpacity(0.4) : Colors.white12),
        boxShadow: [
          if (unlocked)
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unlocked ? color : Colors.white10,
              shape: BoxShape.circle,
              boxShadow: [
                if (unlocked)
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)
              ],
            ),
            child: Icon(data['icon'],
                color: unlocked ? Colors.black : Colors.white24, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['title'],
                        style: GoogleFonts.blackOpsOne(
                            color: unlocked ? Colors.white : Colors.white54,
                            fontSize: 16)),
                    if (unlocked)
                      const Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 20),
                  ],
                ),
                Text(data['desc'],
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: data['progress'],
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.6)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: color.withOpacity(0.3), blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['current'],
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 10)),
                    Text(data['target'],
                        style: GoogleFonts.poppins(
                            color: color.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS FOR TIERED ACHIEVEMENTS ---

  Map<String, dynamic> _createWinAchievement(
      int target, String title, String desc, IconData icon, Color color) {
    return {
      "title": title,
      "desc": desc,
      "icon": icon,
      "color": color,
      "progress": (DataManager.wins / target).clamp(0.0, 1.0),
      "target": "$target Wins",
      "current": "${DataManager.wins} / $target",
      "unlocked": DataManager.wins >= target,
    };
  }

  Map<String, dynamic> _createCoinAchievement(
      int target, String title, String desc, IconData icon, Color color) {
    return {
      "title": title,
      "desc": desc,
      "icon": icon,
      "color": color,
      "progress": (DataManager.coins / target).clamp(0.0, 1.0),
      "target": "$target Coins",
      "current": "${DataManager.coins} / $target",
      "unlocked": DataManager.coins >= target,
    };
  }

  Map<String, dynamic> _createLevelAchievement(
      int target, String title, String desc, IconData icon, Color color) {
    return {
      "title": title,
      "desc": desc,
      "icon": icon,
      "color": color,
      "progress": (DataManager.level / target).clamp(0.0, 1.0),
      "target": "Lvl $target",
      "current": "Lvl ${DataManager.level} / $target",
      "unlocked": DataManager.level >= target,
    };
  }

  Map<String, dynamic> _createDeckAchievement(
      int target, String title, String desc, IconData icon, Color color) {
    return {
      "title": title,
      "desc": desc,
      "icon": icon,
      "color": color,
      "progress": (DataManager.ownedDecks.length / target).clamp(0.0, 1.0),
      "target": "$target Decks",
      "current": "${DataManager.ownedDecks.length} / $target",
      "unlocked": DataManager.ownedDecks.length >= target,
    };
  }

  Map<String, dynamic> _createAvatarAchievement(
      int target, String title, String desc, IconData icon, Color color) {
    return {
      "title": title,
      "desc": desc,
      "icon": icon,
      "color": color,
      "progress": (DataManager.ownedAvatars.length / target).clamp(0.0, 1.0),
      "target": "$target Avatars",
      "current": "${DataManager.ownedAvatars.length} / $target",
      "unlocked": DataManager.ownedAvatars.length >= target,
    };
  }

  Map<String, dynamic> _createBannerAchievement(
      int target, String title, String desc, IconData icon, Color color) {
    return {
      "title": title,
      "desc": desc,
      "icon": icon,
      "color": color,
      "progress": (DataManager.ownedBanners.length / target).clamp(0.0, 1.0),
      "target": "$target Banners",
      "current": "${DataManager.ownedBanners.length} / $target",
      "unlocked": DataManager.ownedBanners.length >= target,
    };
  }
}
