import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uno_game/services/data_manager.dart';
import 'package:uno_game/widgets/background.dart';
import '../services/firestore_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = "CARDS";

  final List<Map<String, dynamic>> cardItems = [
    {
      "name": "Spiderman Deck",
      "price": "2",
      "desc": "Web-slinging card vibes",
      "icon": Icons.gps_fixed,
      "color": Colors.red,
      "tag": "MARVEL",
      "image": "assets/spiderman_mask.png",
      "number": "7"
    },
    {
      "name": "Ironman Deck",
      "price": "2",
      "desc": "High-tech metallic finish",
      "icon": Icons.bolt,
      "color": Colors.orangeAccent,
      "tag": "MARVEL",
      "image": "assets/ironman.png",
      "number": "3"
    },
    {
      "name": "Naruto Deck",
      "price": "3",
      "desc": "Believe it! Ninja way cards",
      "icon": Icons.cyclone,
      "color": Colors.orange,
      "tag": "ANIME",
      "image": "assets/obito.png",
      "number": "9"
    },
    {
      "name": "One Piece Deck",
      "price": "3",
      "desc": "Pirate King's treasure deck",
      "icon": Icons.anchor,
      "color": Colors.blue,
      "tag": "ANIME",
      "image": "assets/logo.png", // Use logo as fallback
      "number": "OP"
    },
    {
      "name": "Neon Deck",
      "price": "5",
      "desc": "Glow in the dark cards",
      "icon": Icons.lightbulb,
      "color": Colors.cyanAccent,
      "tag": "CLASSIC",
      "number": "N"
    },
    {
      "name": "Void Deck",
      "price": "1",
      "desc": "Dark matter aesthetic",
      "icon": Icons.brightness_3,
      "color": Colors.deepPurpleAccent,
      "tag": "PREMIUM"
    },
    {
      "name": "Cars Deck",
      "price": "0",
      "desc": "Ultimate speed and luxury machines",
      "icon": Icons.directions_car,
      "color": Colors.blueGrey,
      "tag": "CARS",
      "image": "assets/cars_blue_bmw.png",
      "number": "V8"
    },
  ];

  final List<Map<String, dynamic>> avatarItems = [
    // ANIMAL
    {
      "name": "Lion King",
      "price": "1",
      "desc": "The jungle's majesty",
      "icon": Icons.pets,
      "color": Colors.amber,
      "tag": "ANIMAL"
    },
    {
      "name": "Tiger Strike",
      "price": "1",
      "desc": "Wild spirit animal",
      "icon": Icons.cruelty_free,
      "color": Colors.orange,
      "tag": "ANIMAL"
    },
    {
      "name": "Wolf Shadow",
      "price": "1",
      "desc": "Lone wolf warrior",
      "icon": Icons.nightlight_round,
      "color": Colors.grey,
      "tag": "ANIMAL"
    },
    // MALE
    {
      "name": "Super Male",
      "price": "0",
      "desc": "Heroic male avatar",
      "icon": Icons.face,
      "color": Colors.blue,
      "tag": "MALE"
    },
    {
      "name": "Ninja Boy",
      "price": "0",
      "desc": "Master of stealth",
      "icon": Icons.masks,
      "color": Colors.black,
      "tag": "MALE"
    },
    // FEMALE
    {
      "name": "Wonder Female",
      "price": "0",
      "desc": "Heroic female avatar",
      "icon": Icons.face_retouching_natural,
      "color": Colors.pink,
      "tag": "FEMALE"
    },
    {
      "name": "Empress",
      "price": "1",
      "desc": "Royal female glow",
      "icon": Icons.auto_awesome,
      "color": Colors.purpleAccent,
      "tag": "FEMALE"
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayItems = [];
    if (_selectedCategory == "CARDS") {
      displayItems = cardItems;
    } else if (_selectedCategory == "AVATARS") {
      displayItems = DataManager.avatarPack.map((a) {
        return {
          "name": a['id'],
          "price": a['price'].toString(),
          "desc": "Premium Player Avatar",
          "icon": Icons.face,
          "color": Colors.blueAccent,
          "tag": a['price'] == 0 ? "FREE" : "PREMIUM",
          "url": a['url'],
        };
      }).toList();
    } else {
      displayItems = DataManager.bannerPack.map((b) {
        return {
          "name": b['id'],
          "price": b['price'].toString(),
          "desc": "Profile Background Banner",
          "icon": Icons.brush,
          "color": (b['colors'] as List<Color>)[0],
          "tag": b['price'] == 0 ? "FREE" : "BANNERS",
          "colors": b['colors'],
        };
      }).toList();
    }

    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              _animatedEntrance(index: 0, child: _balanceHeader()),
              const SizedBox(height: 20),
              _animatedEntrance(index: 1, child: _categorySelector()),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: displayItems.length,
                  itemBuilder: (ctx, i) => _animatedEntrance(
                    index: i + 2,
                    child: _shopItem(displayItems[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _catBtn("CARDS"),
          const SizedBox(width: 15),
          _catBtn("AVATARS"),
          const SizedBox(width: 15),
          _catBtn("BANNERS"),
        ],
      ),
    );
  }

  Widget _catBtn(String label) {
    bool isSel = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? Colors.blueAccent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSel ? Colors.blueAccent : Colors.white12),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: isSel ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  Widget _animatedEntrance({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (ctx, double val, w) {
        return Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.8 + (0.2 * val),
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
          Text("ULTIMATE SHOP",
              style: GoogleFonts.blackOpsOne(
                  color: Colors.white, fontSize: 30, letterSpacing: 2)),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.history, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _balanceHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 20)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.elasticOut,
            builder: (ctx, val, child) => Transform.scale(
                scale: val,
                child: const Icon(Icons.stars, color: Colors.amber, size: 32)),
          ),
          const SizedBox(width: 15),
          Text(DataManager.coins.toString(),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text("COINS",
              style: GoogleFonts.poppins(
                  color: Colors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  void _buyItem(Map<String, dynamic> item) {
    int price = int.parse(item['price']);
    if (DataManager.coins >= price) {
      setState(() {
        DataManager.coins -= price;
        if (_selectedCategory == "CARDS") {
          DataManager.addDeck(item['name']);
        } else if (_selectedCategory == "AVATARS") {
          DataManager.addAvatar(item['name']);
        } else {
          DataManager.addBanner(item['name']);
        }
      });
      // Call Premium Pop-up instead of SnackBar
      _showPurchaseSuccessDialog(item);

      // Auto-save to cloud
      if (!DataManager.isGuest) FirestoreService.saveUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient coins! Win games to earn more."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showPurchaseSuccessDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.elasticOut,
          builder: (ctx, double val, child) {
            return Transform.scale(
              scale: val,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e).withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.cyanAccent, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 30)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    size: 60, color: Colors.greenAccent),
                const SizedBox(height: 15),
                Text("PURCHASE SUCCESSFUL!",
                    style: GoogleFonts.blackOpsOne(
                        color: Colors.white, fontSize: 22)),
                const SizedBox(height: 10),
                Text("You have unlocked\n'${item['name']}'",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(height: 25),
                // Item Preview
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: item.containsKey('image')
                      ? Image.asset(item['image'], height: 60)
                      : Icon(item['icon'],
                          size: 50, color: item['color'] ?? Colors.white),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text("OK",
                          style: GoogleFonts.poppins(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () {
                        // Equip Logic
                        setState(() {
                          if (_selectedCategory == "CARDS") {
                            DataManager.selectedDeck = item['name'];
                          } else if (_selectedCategory == "AVATARS") {
                            DataManager.selectedAvatar = item['name'];
                            DataManager.profilePicPath = null;
                            if (!DataManager.isGuest) {
                              FirestoreService.updateProfile(
                                  avatar: item['name']);
                            }
                          } else {
                            DataManager.selectedBanner = item['name'];
                            if (!DataManager.isGuest) {
                              FirestoreService.updateProfile(
                                  banner: item['name']);
                            }
                          }
                          // Save again after equip
                          if (!DataManager.isGuest)
                            FirestoreService.saveUserData();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Equipped ${item['name']}!"),
                            backgroundColor: Colors.cyan,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Text("EQUIP NOW",
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isOwned(String name) {
    if (_selectedCategory == "CARDS")
      return DataManager.ownedDecks.contains(name);
    if (_selectedCategory == "AVATARS")
      return DataManager.ownedAvatars.contains(name);
    if (_selectedCategory == "BANNERS")
      return DataManager.ownedBanners.contains(name);
    return false;
  }

  Widget _shopItem(Map<String, dynamic> item) {
    bool owned = _isOwned(item['name']);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
              color: (item['color'] as Color).withOpacity(0.1), blurRadius: 20)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Icon(item['icon'],
                  size: 100, color: (item['color'] as Color).withOpacity(0.05)),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(item['tag'],
                          style: TextStyle(
                              color: item['color'],
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    if (item.containsKey('image'))
                      _unoCard(item['image'], item['color'], item['number'])
                    else if (item.containsKey('url'))
                      ClipOval(
                        child: Image.network(
                          item['url'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) =>
                              Icon(Icons.face, size: 60, color: item['color']),
                        ),
                      )
                    else if (item.containsKey('colors'))
                      Container(
                        width: 90,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                                colors: item['colors'] as List<Color>),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4)
                            ]),
                      )
                    else
                      Icon(item['icon'], size: 60, color: item['color']),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(item['name'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(item['desc'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (!owned) {
                          _buyItem(item);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color)
                              .withOpacity(owned ? 0.8 : 0.15),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            if (owned)
                              BoxShadow(
                                  color:
                                      (item['color'] as Color).withOpacity(0.3),
                                  blurRadius: 10)
                          ],
                          border: Border.all(
                              color: (item['color'] as Color)
                                  .withOpacity(owned ? 1.0 : 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (owned)
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 16)
                            else ...[
                              const Icon(Icons.stars,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 8),
                            ],
                            const SizedBox(width: 6),
                            Text(owned ? "OWNED" : item['price'],
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _unoCard(String imgPath, Color color, String number) {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          const BoxShadow(
              color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // 1. Subtle Big Number
            Positioned(
              top: 5,
              right: 8,
              child: Opacity(
                opacity: 0.15,
                child: Text(
                  number,
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // 2. Corner numbers
            Positioned(
                top: 2,
                left: 4,
                child: Text(number,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))),
            Positioned(
                bottom: 2,
                right: 4,
                child: RotatedBox(
                    quarterTurns: 2,
                    child: Text(number,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)))),

            // 3. Center Design (Tilted White Ellipse)
            Center(
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 65,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius:
                        const BorderRadius.all(Radius.elliptical(65, 42)),
                  ),
                ),
              ),
            ),

            // 4. Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    imgPath,
                    fit: BoxFit.contain,
                    height: 55,
                    errorBuilder: (ctx, _, __) => Text(
                      number,
                      style: GoogleFonts.righteous(
                        fontSize: 35,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
