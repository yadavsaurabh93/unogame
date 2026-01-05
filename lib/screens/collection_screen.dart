import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../widgets/background.dart';
import '../services/firestore_service.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _activeTab = "CARDS";

  // Data for rendering (should match ShopScreen names)
  final Map<String, List<Map<String, dynamic>>> collectionData = {
    "CARDS": [
      {
        "name": "Spiderman Deck",
        "image": "assets/spiderman_classic.png",
        "color": Colors.red,
        "number": "7"
      },
      {
        "name": "Ironman Deck",
        "image": "assets/ironman.png",
        "color": Colors.orangeAccent,
        "number": "3"
      },
      {
        "name": "Naruto Deck",
        "image": "assets/naruto_rasengan.png",
        "color": Colors.orange,
        "number": "9"
      },
      {
        "name": "JJK Deck",
        "image": "assets/gojo.png",
        "color": Colors.deepPurple,
        "number": "∞"
      },
      {
        "name": "One Piece Deck",
        "image": "assets/luffy.png",
        "color": Colors.blue,
        "number": "5"
      },
      {
        "name": "Neon Deck",
        "icon": Icons.lightbulb,
        "color": Colors.cyanAccent
      },
      {
        "name": "Retro Deck",
        "icon": Icons.videogame_asset,
        "color": Colors.pinkAccent
      },
      {
        "name": "Void Deck",
        "icon": Icons.brightness_3,
        "color": Colors.deepPurpleAccent
      },
      {
        "name": "Cars Deck",
        "image": "assets/cars_blue_bmw.png",
        "color": Colors.blueGrey,
        "number": "V8"
      },
    ],
    "AVATARS": [
      {"name": "Lion King", "icon": Icons.pets, "color": Colors.amber},
      {
        "name": "Tiger Strike",
        "icon": Icons.cruelty_free,
        "color": Colors.orange
      },
      {
        "name": "Wolf Shadow",
        "icon": Icons.nightlight_round,
        "color": Colors.grey
      },
      {"name": "Super Male", "icon": Icons.face, "color": Colors.blue},
      {"name": "Ninja Boy", "icon": Icons.masks, "color": Colors.black},
      {
        "name": "Wonder Female",
        "icon": Icons.face_retouching_natural,
        "color": Colors.pink
      },
      {
        "name": "Empress",
        "icon": Icons.auto_awesome,
        "color": Colors.purpleAccent
      },
      {
        "name": "Classic Male",
        "icon": Icons.account_circle,
        "color": Colors.grey
      },
    ],
    "BANNERS": [
      {"name": "Basic Blue", "icon": Icons.linear_scale, "color": Colors.blue},
      {"name": "Neon Strike", "icon": Icons.flash_on, "color": Colors.yellow},
    ],
    "AWARDS": [], // Will be populated dynamically
  };

  @override
  Widget build(BuildContext context) {
    List<dynamic> ownedItems = [];
    if (_activeTab == "CARDS") {
      // Filter owned decks from constant data or just names
      // For now using the existing hardcoded CARDS list for UI demo but filtered by ownedDecks
      ownedItems = collectionData["CARDS"]!
          .where((item) => DataManager.ownedDecks.contains(item['name']))
          .toList();
    } else if (_activeTab == "AVATARS") {
      ownedItems = DataManager.avatarPack
          .where((item) => DataManager.ownedAvatars.contains(item['id']))
          .toList();
    } else if (_activeTab == "BANNERS") {
      ownedItems = DataManager.bannerPack
          .where((item) => DataManager.ownedBanners.contains(item['id']))
          .toList();
    } else if (_activeTab == "AWARDS") {
      ownedItems = _getEarnedAchievements();
    }

    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              _tabSelector(),
              Expanded(
                child: ownedItems.isEmpty
                    ? _emptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: ownedItems.length,
                        itemBuilder: (ctx, i) => _collectionItem(ownedItems[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          const SizedBox(width: 10),
          Text("MY COLLECTION",
              style: GoogleFonts.blackOpsOne(
                  color: Colors.white, fontSize: 24, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _tabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: ["CARDS", "AVATARS", "BANNERS", "AWARDS"].map((t) {
          bool isAct = _activeTab == t;
          return Padding(
            padding:
                const EdgeInsets.only(right: 15), // Add spacing between tabs
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isAct ? Colors.blueAccent : Colors.transparent,
                          width: 3)),
                ),
                child: Text(t,
                    style: GoogleFonts.poppins(
                        color: isAct ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white10),
        const SizedBox(height: 20),
        Text("No items owned yet",
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 16)),
        const SizedBox(height: 10),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Go to Shop",
                style: TextStyle(color: Colors.blueAccent))),
      ],
    );
  }

  Widget _collectionItem(dynamic item) {
    bool isEquipped = false;
    String name = "";
    if (_activeTab == "CARDS") {
      name = item['name'];
      isEquipped = DataManager.selectedDeck == name;
    } else if (_activeTab == "AWARDS") {
      name = item['name'];
      isEquipped = false; // Awards can't be equipped, they are just trophies
    } else {
      name = item['id'];
      isEquipped = (_activeTab == "AVATARS")
          ? DataManager.selectedAvatar == name
          : DataManager.selectedBanner == name;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isEquipped ? Colors.cyanAccent : Colors.white10, width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10), // Added padding for better spacing
            if (_activeTab == "CARDS")
              item.containsKey('image')
                  ? _unoCardSmall(
                      item['image'], item['color'], item['number'] ?? "")
                  : Icon(item['icon'],
                      size: 50, color: item['color'] ?? Colors.cyanAccent)
            else if (_activeTab == "AVATARS")
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white10,
                backgroundImage: (item['url'] as String).startsWith('http')
                    ? NetworkImage(item['url'])
                    : AssetImage(item['url']) as ImageProvider,
              )
            else if (_activeTab == "BANNERS")
              Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient:
                      LinearGradient(colors: item['colors'] as List<Color>),
                ),
              )
            else if (_activeTab == "AWARDS") // --- NEW AWARD RENDERER ---
              Column(children: [
                Icon(item['icon'], size: 40, color: item['color']),
                const SizedBox(height: 5),
                Text(
                  item['desc'],
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                  textAlign: TextAlign.center,
                )
              ]),

            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 10),

            // Only show Equip button if NOT an Award
            if (_activeTab != "AWARDS")
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_activeTab == "CARDS") {
                      DataManager.selectedDeck = name;
                      // Auto-Save selection to Cloud
                      if (!DataManager.isGuest) FirestoreService.saveUserData();
                    } else if (_activeTab == "AVATARS") {
                      DataManager.selectedAvatar = name;
                      DataManager.profilePicPath = null;
                      if (!DataManager.isGuest) {
                        FirestoreService.updateProfile(avatar: name);
                        FirestoreService.saveUserData();
                      }
                    } else {
                      DataManager.selectedBanner = name;
                      if (!DataManager.isGuest) {
                        FirestoreService.updateProfile(banner: name);
                        FirestoreService.saveUserData();
                      }
                    }
                  });
                  DataManager.playSound();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isEquipped ? Colors.cyanAccent : Colors.white10,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text((isEquipped ? "EQUIPPED" : "EQUIP"),
                      style: TextStyle(
                          color: isEquipped ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              )
            else // FOR AWARDS SHOW 'UNLOCKED' BADGE
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text("UNLOCKED",
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _unoCardSmall(String imgPath, Color color, String number) {
    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Stack(
          children: [
            Center(
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 32,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius:
                        const BorderRadius.all(Radius.elliptical(32, 20)),
                  ),
                ),
              ),
            ),
            Center(
              child: Image.asset(
                imgPath,
                fit: BoxFit.contain,
                height: 30,
                errorBuilder: (ctx, _, __) => Text(number,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getEarnedAchievements() {
    // Basic logic to get some earned achievements for the collection view
    // In a real app, this should pull from the same list as AchievementsScreen
    List<Map<String, dynamic>> all = [
      {
        "id": "A1",
        "name": "First Blood",
        "desc": "First online win",
        "icon": Icons.military_tech,
        "color": Colors.redAccent,
        "type": "WINS",
        "target": 1
      },
      {
        "id": "A2",
        "name": "Wealthy",
        "desc": "10K coins",
        "icon": Icons.monetization_on,
        "color": Colors.greenAccent,
        "type": "COINS",
        "target": 10000
      },
      {
        "id": "A3",
        "name": "Skilled",
        "desc": "Lvl 10 reached",
        "icon": Icons.star,
        "color": Colors.blue,
        "type": "LEVEL",
        "target": 10
      },
      {
        "id": "A4",
        "name": "Starter",
        "desc": "1 Deck owned",
        "icon": Icons.style,
        "color": Colors.blueGrey,
        "type": "DECKS",
        "target": 1
      },
      {
        "id": "A5",
        "name": "Veteran",
        "desc": "50 wins",
        "icon": Icons.military_tech_outlined,
        "color": Colors.orange,
        "type": "WINS",
        "target": 50
      },
    ];

    return all.where((a) {
      if (a['type'] == "WINS") return DataManager.wins >= a['target'];
      if (a['type'] == "COINS") return DataManager.coins >= a['target'];
      if (a['type'] == "LEVEL") return DataManager.level >= a['target'];
      if (a['type'] == "DECKS")
        return DataManager.ownedDecks.length >= a['target'];
      return false;
    }).toList();
  }
}
