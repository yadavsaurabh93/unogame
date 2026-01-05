import 'dart:io';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uno_game/services/data_manager.dart';
import 'package:uno_game/services/auth_service.dart';
import 'package:uno_game/widgets/background.dart';
import 'package:uno_game/screens/collection_screen.dart';
import 'package:uno_game/screens/leaderboard_screen.dart';
import 'package:uno_game/screens/lobby_screen.dart';
import 'package:uno_game/screens/offline_game_screen.dart';
import 'package:uno_game/screens/pass_play_game_screen.dart';
import 'package:uno_game/screens/profile_screen.dart';
import 'package:uno_game/screens/rules_screen.dart';
import 'package:uno_game/screens/shop_screen.dart';
import 'package:uno_game/screens/support_screen.dart';
import 'package:uno_game/screens/daily_spin_screen.dart';
import 'package:uno_game/screens/auth_screen.dart';
import 'package:uno_game/screens/achievements_screen.dart';
import 'package:uno_game/screens/social_screen.dart';
import 'package:uno_game/screens/elite_pass_screen.dart';
import 'package:uno_game/screens/notification_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:uno_game/services/firestore_service.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription? _inviteSubscription;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _initData();
  }

  @override
  void dispose() {
    _inviteSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _initData() async {
    if (!DataManager.isInitialized) await DataManager.init();
    DataManager.checkDailyStreak();
    setState(() {});

    // Auto-show Daily Reward if first login today
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String today = DateTime.now().toString().split(' ')[0];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lastShown = prefs.getString('lastRewardShownDate') ?? "";

      if (lastShown != today) {
        _showDailyRewardDialog();
        prefs.setString('lastRewardShownDate', today);
      }
    });

    // REAL-TIME BATTLE INVITE LISTENER
    if (!DataManager.isGuest) {
      _inviteSubscription =
          FirestoreService.getBattleInvitesStream().listen((invites) {
        if (invites.isNotEmpty && mounted) {
          // Show the most recent one
          var latest = invites.first;
          _showRealTimeInvite(latest['fromName'], latest['fromUid']);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: Colors.cyanAccent, size: 30),
            onPressed: () {
              DataManager.playSound();
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 28),
                onPressed: () async {
                  DataManager.playSound();
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationScreen()));
                  // Refresh state on return to update badge
                  setState(() {});
                },
              ),
              if (DataManager.notifications.any((n) => !n['isRead']))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text(
                        "${DataManager.notifications.where((n) => !n['isRead']).length}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            onPressed: () {
              DataManager.playSound();
              _showSettings();
            },
          )
        ],
      ),
      body: ModernBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HEADER & PROFILE BADGE
                  Text("UNO",
                      style: GoogleFonts.blackOpsOne(
                          fontSize: 40, color: Colors.white, height: 1)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("GOD PULSE",
                          style: GoogleFonts.rajdhani(
                              fontSize: 28,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              height: 1)),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // PLAYER CARD (Glass)
                  GestureDetector(
                    onTap: () {
                      DataManager.playSound();
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UserProfileScreen()))
                          .then((_) => setState(() {}));
                    },
                    child: Builder(builder: (context) {
                      // Get current banner colors
                      var banner = DataManager.bannerPack.firstWhere(
                          (b) => b['id'] == DataManager.selectedBanner,
                          orElse: () => DataManager.bannerPack[0]);
                      List<Color> bannerColors =
                          (banner['colors'] as List).cast<Color>();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                bannerColors[0].withOpacity(0.8),
                                bannerColors[1].withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: bannerColors[0].withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                  color: bannerColors[0].withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10))
                            ]),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.cyanAccent, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.cyanAccent.withOpacity(0.4),
                                        blurRadius: 10)
                                  ]),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[900],
                                backgroundImage: DataManager.profilePicPath !=
                                        null
                                    ? FileImage(
                                        File(DataManager.profilePicPath!))
                                    : (DataManager.getSelectedAvatarUrl()
                                            .startsWith('http')
                                        ? NetworkImage(
                                            DataManager.getSelectedAvatarUrl())
                                        : AssetImage(DataManager
                                                .getSelectedAvatarUrl())
                                            as ImageProvider),
                                child: null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DataManager.playerName,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      Builder(builder: (context) {
                                        var rank = DataManager.getRankInfo();
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: (rank['color'] as Color)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color:
                                                      (rank['color'] as Color)
                                                          .withOpacity(0.5),
                                                  width: 0.5),
                                              boxShadow: [
                                                BoxShadow(
                                                    color:
                                                        (rank['glow'] as Color),
                                                    blurRadius: 4)
                                              ]),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(rank['icon'] as IconData,
                                                  size: 10,
                                                  color:
                                                      rank['color'] as Color),
                                              const SizedBox(width: 4),
                                              Text(rank['name'],
                                                  style: GoogleFonts.poppins(
                                                      color: rank['color']
                                                          as Color,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5)),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(width: 8),
                                      Icon(Icons.stars,
                                          size: 14, color: Colors.amber[400]),
                                      const SizedBox(width: 4),
                                      Text("Lvl ${DataManager.level}",
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.monetization_on,
                                          size: 14, color: Colors.amber[400]),
                                      const SizedBox(width: 4),
                                      Text("${DataManager.coins}",
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Rank Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: (DataManager.level % 10) / 10,
                                      backgroundColor: Colors.white10,
                                      color: Colors.cyanAccent,
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right,
                                  color: Colors.white70),
                            )
                          ],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 30),

                  // 2. MAIN "PLAY ONLINE" BUTTON (Pulsing Glow)
                  AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return GestureDetector(
                          onTap: () {
                            DataManager.playSound();
                            if (DataManager.isGuest) {
                              _showLoginDialog();
                              return;
                            }
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LobbyScreen()))
                                .then((_) => setState(() {}));
                          },
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2E3192),
                                      Color(0xFF1BFFFF)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF1BFFFF)
                                          .withOpacity(
                                              0.4 + (_controller.value * 0.2)),
                                      blurRadius: 20 + (_controller.value * 10),
                                      spreadRadius: 1)
                                ]),
                            child: Stack(
                              children: [
                                Positioned(
                                    right: -20,
                                    top: -20,
                                    child: Icon(Icons.public,
                                        size: 120,
                                        color: Colors.white.withOpacity(0.1))),
                                Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        child: const Icon(Icons.bolt,
                                            color: Colors.white, size: 28),
                                      ),
                                      const SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text("ONLINE BATTLE",
                                              style: GoogleFonts.blackOpsOne(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  letterSpacing: 1)),
                                          Text("Ranked Multiplayer",
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.arrow_forward,
                                          color: Colors.white)
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                  const SizedBox(height: 16),

                  // 3. SECONDARY PLAY MODES (Row)
                  Row(
                    children: [
                      Expanded(
                        child: _gameModeCard(
                            "COMPUTER", Icons.smart_toy, Colors.purpleAccent,
                            () {
                          DataManager.playSound();
                          _showDifficultyDialog(context);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _gameModeCard(
                            "LOCAL", Icons.people, Colors.orangeAccent, () {
                          DataManager.playSound();
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PassPlayGameScreen()))
                              .then((_) => setState(() {}));
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  // New Elite Pass Banner
                  GestureDetector(
                    onTap: () {
                      DataManager.playSound();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ElitePassScreen()));
                    },
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.3),
                                blurRadius: 15)
                          ]),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          const Icon(Icons.workspace_premium,
                              color: Colors.amber, size: 30),
                          const SizedBox(width: 15),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ELITE PASS",
                                  style: GoogleFonts.blackOpsOne(
                                      color: Colors.white, fontSize: 18)),
                              Text("Season 1: God Pulse",
                                  style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            margin: const EdgeInsets.only(right: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text("VIEW",
                                style: GoogleFonts.blackOpsOne(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text("EXPLORE",
                      style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),

                  // 4. BENTO GRID (Utilities)
                  Row(
                    children: [
                      Expanded(
                        child: _bentoCard(
                            "Leaderboard",
                            Icons.emoji_events,
                            Colors.amber,
                            () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const LeaderboardScreen()))
                                .then((_) => setState(() {}))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _bentoCard(
                            "Shop",
                            Icons.shopping_bag,
                            Colors.pinkAccent,
                            () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ShopScreen()))
                                .then((_) => setState(() {}))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _bentoCard(
                            "Collection",
                            Icons.style,
                            Colors.blueAccent,
                            () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CollectionScreen()))
                                .then((_) => setState(() {}))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _bentoCard(
                            "Daily Spin",
                            Icons.casino,
                            Colors.greenAccent,
                            () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const DailySpinScreen()))
                                .then((_) => setState(() {}))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _bentoCard(
                            "Awards",
                            Icons.military_tech,
                            Colors.orangeAccent,
                            () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AchievementsScreen()))
                                .then((_) => setState(() {}))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _bentoCard(
                            "Friends",
                            Icons.people_alt,
                            Colors.purpleAccent,
                            () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SocialScreen()))
                                .then((_) => setState(() {}))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _bentoCard(
                      "Help &  AI Support",
                      Icons.smart_toy_outlined,
                      Colors.cyanAccent,
                      () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SupportScreen()))
                          .then((_) => setState(() {}))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameModeCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: GoogleFonts.blackOpsOne(
                        color: Colors.white, fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _bentoCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        DataManager.playSound();
        onTap();
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withOpacity(0.1)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500))
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E2C),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => StatefulBuilder(
              builder: (ctx, setSt) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Text("SETTINGS",
                        style: GoogleFonts.blackOpsOne(
                            color: Colors.white,
                            fontSize: 24,
                            letterSpacing: 1)),
                    const SizedBox(height: 20),
                    _settingToggle("Sound Effects", Icons.volume_up,
                        Colors.blue, DataManager.soundEnabled, (v) {
                      DataManager.soundEnabled = v;
                      setSt(() {});
                      setState(() {});
                    }),
                    _settingToggle("Vibration", Icons.vibration, Colors.orange,
                        DataManager.vibrationEnabled, (v) {
                      DataManager.vibrationEnabled = v;
                      setSt(() {});
                      setState(() {});
                    }),
                    _settingToggle("Fast Mode", Icons.speed, Colors.red,
                        DataManager.fastMode, (v) {
                      DataManager.fastMode = v;
                      setSt(() {});
                      setState(() {});
                    }),
                    if (!DataManager.isGuest) ...[
                      const SizedBox(height: 20),
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child:
                                  const Icon(Icons.email, color: Colors.blue)),
                          title: Text("Account",
                              style: GoogleFonts.poppins(
                                  color: Colors.white54, fontSize: 12)),
                          subtitle: Text(DataManager.email ?? "No Email",
                              style: GoogleFonts.poppins(color: Colors.white)))
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await AuthService.logout();
                          if (mounted)
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AuthScreen()),
                                (r) => false);
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(
                            DataManager.isGuest
                                ? "RESET GUEST & EXIT"
                                : "LOGOUT",
                            style: GoogleFonts.blackOpsOne()),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  Widget _settingToggle(String title, IconData icon, Color color, bool value,
      Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w500)),
      secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20)),
      value: value,
      onChanged: onChanged,
      activeColor: color,
    );
  }

  void _showLoginDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Text("LOGIN REQUIRED",
                  style: GoogleFonts.blackOpsOne(
                      color: Colors.white, fontSize: 24)),
              content: Text("Login to play Online!",
                  style: GoogleFonts.poppins(color: Colors.white70)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CANCEL",
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: const StadiumBorder()),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthScreen()));
                    },
                    child: const Text("LOGIN NOW",
                        style: TextStyle(color: Colors.white)))
              ],
            ));
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("SELECT DIFFICULTY",
                style: GoogleFonts.blackOpsOne(color: Colors.white)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              _diffBtn(ctx, "EASY", BotDifficulty.easy, Colors.green),
              _diffBtn(ctx, "MEDIUM", BotDifficulty.medium, Colors.blue),
              _diffBtn(ctx, "HARD", BotDifficulty.hard, Colors.red)
            ])));
  }

  Widget _diffBtn(BuildContext ctx, String label, BotDifficulty diff, Color c) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: InkWell(
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => OfflineGameScreen(difficulty: diff)));
            },
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.withOpacity(0.5))),
                child: Center(
                    child: Text(label,
                        style: GoogleFonts.blackOpsOne(
                            color: c, fontSize: 16))))));
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1E).withOpacity(0.85),
            border: const Border(right: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              _sidebarHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _sidebarLabel("PLAYER MENU"),
                    _sidebarItem(
                        Icons.person_outline,
                        "My Profile",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserProfileScreen()))),
                    _sidebarItem(
                        Icons.workspace_premium_outlined,
                        "Elite Pass",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ElitePassScreen())),
                        color: Colors.amberAccent),
                    _sidebarItem(
                        Icons.shopping_bag_outlined,
                        "Elite Shop",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ShopScreen()))),
                    _sidebarItem(
                        Icons.style_outlined,
                        "Gallary & Collection",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CollectionScreen()))),
                    const Divider(color: Colors.white10, height: 40),
                    _sidebarLabel("RANKINGS & SOCIAL"),
                    _sidebarItem(
                        Icons.emoji_events_outlined,
                        "World Leaderboard",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LeaderboardScreen()))),
                    _sidebarItem(
                        Icons.military_tech_outlined,
                        "Uno Achievements",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AchievementsScreen()))),
                    _sidebarItem(
                        Icons.people_alt_outlined,
                        "Friends & Chat",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SocialScreen()))),
                    const Divider(color: Colors.white10, height: 40),
                    _sidebarLabel("QUICK LINKS"),
                    _sidebarItem(
                        Icons.casino_outlined,
                        "Lucky Daily Spin",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DailySpinScreen()))),
                    _sidebarItem(
                        Icons.menu_book_outlined,
                        "Game Instructions",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RulesScreen()))),
                    _sidebarItem(
                        Icons.smart_toy_outlined,
                        "AI Support",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SupportScreen()))),
                    const Divider(color: Colors.white10, height: 40),
                    _sidebarItem(Icons.logout_rounded, "Logout Account",
                        () => _showSettings(),
                        color: Colors.redAccent),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text("v2.4.0 • God Pulse Edition",
                    style: GoogleFonts.poppins(
                        color: Colors.white24, fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyanAccent.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.cyanAccent.withOpacity(0.1),
            backgroundImage:
                DataManager.getSelectedAvatarUrl().startsWith('http')
                    ? NetworkImage(DataManager.getSelectedAvatarUrl())
                    : AssetImage(DataManager.getSelectedAvatarUrl())
                        as ImageProvider,
          ),
          const SizedBox(height: 15),
          Text(DataManager.playerName,
              style:
                  GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 22)),
          Row(
            children: [
              Builder(builder: (context) {
                var rank = DataManager.getRankInfo();
                return Icon(rank['icon'] as IconData,
                    color: rank['color'] as Color, size: 16);
              }),
              const SizedBox(width: 4),
              Text(DataManager.getRankInfo()['name'],
                  style: GoogleFonts.poppins(
                      color: DataManager.getRankInfo()['color'] as Color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 15),
              Icon(Icons.stars, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text("Level ${DataManager.level}",
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text("${DataManager.coins} Coins",
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 15),
              Icon(Icons.flash_on, color: Colors.orangeAccent, size: 14),
              const SizedBox(width: 4),
              Text("${DataManager.currentStreak} Day Streak",
                  style: GoogleFonts.poppins(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebarLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(text,
          style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5)),
    );
  }

  Widget _sidebarItem(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.white70}) {
    return ListTile(
      onTap: () {
        DataManager.playSound();
        Navigator.pop(context);
        onTap();
      },
      leading: Icon(icon, color: color, size: 22),
      title: Text(title,
          style: GoogleFonts.poppins(
              color: color, fontSize: 15, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      hoverColor: Colors.white10,
    );
  }

  void _showDailyRewardDialog() {
    int reward = 100 * DataManager.currentStreak;
    if (reward > 1000) reward = 1000;

    DataManager.coins += reward;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 40)
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.cyanAccent, size: 50),
                ),
                const SizedBox(height: 20),
                Text("DAILY BONUS!",
                    style: GoogleFonts.blackOpsOne(
                        color: Colors.white, fontSize: 24, letterSpacing: 1)),
                const SizedBox(height: 10),
                Text("Day ${DataManager.currentStreak} Streak Reward",
                    style: GoogleFonts.poppins(
                        color: Colors.cyanAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          color: Colors.amber, size: 32),
                      const SizedBox(width: 12),
                      Text("+$reward",
                          style: GoogleFonts.blackOpsOne(
                              color: Colors.white, fontSize: 36)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      DataManager.playSound();
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text("CLAIM NOW",
                        style: GoogleFonts.blackOpsOne(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRealTimeInvite(String inviter, String fromUid) {
    // Show a premium overlay popup at the top of the screen
    showDialog(
      context: context,
      barrierColor: Colors.black26, // Subtle dimming
      builder: (ctx) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ]),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt,
                          color: Colors.cyanAccent, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("BATTLE INVITE!",
                              style: GoogleFonts.blackOpsOne(
                                  color: Colors.white, fontSize: 14)),
                          Text("$inviter challenged you!",
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // REJECT BUTTON
                    GestureDetector(
                      onTap: () {
                        DataManager.playSound();
                        FirestoreService.clearBattleInvite(fromUid);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.redAccent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ACCEPT BUTTON
                    GestureDetector(
                      onTap: () {
                        DataManager.playSound();
                        FirestoreService.clearBattleInvite(fromUid);
                        Navigator.pop(ctx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LobbyScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            color: Colors.greenAccent, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
