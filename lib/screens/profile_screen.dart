import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/data_manager.dart';
import '../widgets/background.dart';
import 'package:uno_game/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  final List<Map<String, dynamic>> _banners = DataManager.bannerPack;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  void _loadProfile() async {
    if (!DataManager.isInitialized) await DataManager.init();
    setState(() {
      _nameController.text = DataManager.playerName;
    });
  }

  void _saveName() async {
    String newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      // 1. Update Local DataManager (which saves to SharedPreferences)
      DataManager.playerName = newName;

      // 2. Update UI
      setState(() {
        _isEditingName = false;
      });

      // 3. Update Firestore if not a guest
      if (!DataManager.isGuest) {
        try {
          await FirestoreService.updateProfile(name: newName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Name updated successfully!")),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Field to sync: $e")),
          );
        }
      }
    }
  }

  void _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        DataManager.profilePicPath = image.path;
      });
      // Note: For cloud sync, we'd need to upload to Storage first,
      // but for now, we save locally.
    }
  }

  // SHOP LOGIC
  void _selectAvatar(Map<String, dynamic> item) {
    if (DataManager.ownedAvatars.contains(item['id'])) {
      setState(() {
        DataManager.selectedAvatar = item['id'];
        DataManager.profilePicPath = null;
      });
      if (!DataManager.isGuest)
        FirestoreService.updateProfile(avatar: item['id']);
      DataManager.playSound();
    } else {
      _showBuyDialog(item, "Avatar", () {
        DataManager.addAvatar(item['id']);
        setState(() {});
      });
    }
  }

  void _selectBanner(Map<String, dynamic> item) {
    if (DataManager.ownedBanners.contains(item['id'])) {
      setState(() {
        DataManager.selectedBanner = item['id'];
      });
      if (!DataManager.isGuest)
        FirestoreService.updateProfile(banner: item['id']);
      DataManager.playSound();
    } else {
      _showBuyDialog(item, "Banner", () {
        DataManager.addBanner(item['id']);
        setState(() {});
      });
    }
  }

  void _showBuyDialog(
      Map<String, dynamic> item, String type, VoidCallback onSuccess) {
    int price = item['price'];
    if (DataManager.coins >= price) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E2C),
                title: Text("Unlock $type?",
                    style: GoogleFonts.blackOpsOne(color: Colors.white)),
                content: Text(
                    "Price: $price Coins\nYou have: ${DataManager.coins}",
                    style: GoogleFonts.poppins(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("CANCEL",
                          style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber),
                      onPressed: () {
                        DataManager.coins -= price;
                        onSuccess();
                        Navigator.pop(ctx);
                        setState(() {});
                        DataManager.playSound();
                        if (!DataManager.isGuest) {
                          FirestoreService.updateCoins(DataManager.coins);
                          FirestoreService.syncUser(
                              FirebaseAuth.instance.currentUser!);
                        }
                      },
                      child: const Text("BUY",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)))
                ],
              ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Not enough coins!"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("PROFILE",
            style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 24)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.blackOpsOne(fontSize: 14),
          tabs: const [
            Tab(text: "STATS"),
            Tab(text: "AVATARS"),
            Tab(text: "BANNERS"),
          ],
        ),
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header (Always Visible)
              Padding(padding: const EdgeInsets.all(20), child: _buildHeader()),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStats(),
                    _buildShopGrid(DataManager.avatarPack, "Avatar"),
                    _buildShopGrid(_banners, "Banner"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Determine current banner colors
    var banner = _banners.firstWhere(
        (b) => b['id'] == DataManager.selectedBanner,
        orElse: () => _banners[0]);
    List<Color> bannerColors = banner['colors'] as List<Color>;

    // Determine current avatar url
    String avatarUrl = DataManager.getSelectedAvatarUrl();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: bannerColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.black45,
                  backgroundImage: DataManager.profilePicPath != null
                      ? FileImage(File(DataManager.profilePicPath!))
                      : (avatarUrl.startsWith('http')
                          ? NetworkImage(avatarUrl)
                          : AssetImage(avatarUrl) as ImageProvider),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.black, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isEditingName
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                                controller: _nameController,
                                style: GoogleFonts.blackOpsOne(
                                    color: Colors.white, fontSize: 20),
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Name",
                                    hintStyle:
                                        TextStyle(color: Colors.white54))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check,
                                color: Colors.greenAccent),
                            onPressed: _saveName,
                          ),
                        ],
                      )
                    : Row(children: [
                        Text(DataManager.playerName,
                            style: GoogleFonts.blackOpsOne(
                                color: Colors.white, fontSize: 22)),
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.white70, size: 18),
                            onPressed: () =>
                                setState(() => _isEditingName = true))
                      ]),
                Text(DataManager.email ?? "Guest Account",
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text("${DataManager.coins} COINS",
                        style: GoogleFonts.poppins(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)))
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStats() {
    int wins = DataManager.wins;
    int losses = DataManager.losses;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: _statCard("Total Wins", "$wins", Colors.greenAccent)),
            const SizedBox(width: 15),
            Expanded(
                child: _statCard("Total Losses", "$losses", Colors.redAccent))
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _statCard(
                    "Level", "${DataManager.level}", Colors.cyanAccent)),
            const SizedBox(width: 15),
            Expanded(child: _statCard("Win Streak", "0", Colors.orangeAccent))
          ]),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 32)),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12))
      ]),
    );
  }

  Widget _buildShopGrid(List<Map<String, dynamic>> items, String type) {
    bool isAvatar = type == "Avatar";
    var ownedList =
        isAvatar ? DataManager.ownedAvatars : DataManager.ownedBanners;
    var selectedId =
        isAvatar ? DataManager.selectedAvatar : DataManager.selectedBanner;

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        var item = items[i];
        bool owned = ownedList.contains(item['id']);
        bool selected = selectedId == item['id'];

        return GestureDetector(
          onTap: () => isAvatar ? _selectAvatar(item) : _selectBanner(item),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: selected
                    ? Border.all(color: Colors.greenAccent, width: 3)
                    : null,
                gradient:
                    !isAvatar ? LinearGradient(colors: item['colors']) : null,
                image: (isAvatar)
                    ? DecorationImage(
                        image: (item['url'] as String).startsWith('http')
                            ? NetworkImage(item['url'])
                            : AssetImage(item['url']) as ImageProvider,
                        fit: BoxFit.contain)
                    : null),
            child: Stack(
              children: [
                if (!owned)
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock, color: Colors.white),
                      Text("${item['price']}",
                          style: GoogleFonts.blackOpsOne(color: Colors.amber))
                    ])),
                  ),
                if (selected)
                  const Positioned(
                      top: 10,
                      right: 10,
                      child:
                          Icon(Icons.check_circle, color: Colors.greenAccent)),
              ],
            ),
          ),
        );
      },
    );
  }
}
