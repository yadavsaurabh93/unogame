import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

enum BotDifficulty { easy, medium, hard }

class DataManager {
  static late SharedPreferences _prefs;
  static bool isInitialized = false;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Profile data
  static String get playerName => _prefs.getString('playerName') ?? "Guest";
  static set playerName(String v) => _prefs.setString('playerName', v);

  static bool get isGuest => _prefs.getBool('isGuest') ?? true;
  static set isGuest(bool v) => _prefs.setBool('isGuest', v);

  static String? get email => _prefs.getString('email');
  static set email(String? v) =>
      v == null ? _prefs.remove('email') : _prefs.setString('email', v);

  static int get wins => _prefs.getInt('wins') ?? 0;
  static set wins(int v) => _prefs.setInt('wins', v);

  static int get losses => _prefs.getInt('losses') ?? 0;
  static set losses(int v) => _prefs.setInt('losses', v);

  static String? get profilePicPath => _prefs.getString('profilePicPath');
  static set profilePicPath(String? v) => v == null
      ? _prefs.remove('profilePicPath')
      : _prefs.setString('profilePicPath', v);

  // Settings
  static bool get soundEnabled => _prefs.getBool('soundEnabled') ?? true;
  static set soundEnabled(bool v) => _prefs.setBool('soundEnabled', v);

  static bool get vibrationEnabled =>
      _prefs.getBool('vibrationEnabled') ?? true;
  static set vibrationEnabled(bool v) => _prefs.setBool('vibrationEnabled', v);

  static bool get fastMode => _prefs.getBool('fastMode') ?? false;
  static set fastMode(bool v) => _prefs.setBool('fastMode', v);

  static bool get hasSeenTutorial => _prefs.getBool('hasSeenTutorial') ?? false;
  static set hasSeenTutorial(bool v) => _prefs.setBool('hasSeenTutorial', v);

  // Shop & Economy
  static int get coins => _prefs.getInt('coins') ?? 5000;
  static set coins(int v) => _prefs.setInt('coins', v);

  static int get level => _prefs.getInt('level') ?? 1;
  static set level(int v) => _prefs.setInt('level', v);

  // SPIN TRACKING
  static String get lastSpinDate => _prefs.getString('lastSpinDate') ?? "";
  static set lastSpinDate(String v) => _prefs.setString('lastSpinDate', v);

  static int get dailySpinsUsed => _prefs.getInt('dailySpinsUsed') ?? 0;
  static set dailySpinsUsed(int v) => _prefs.setInt('dailySpinsUsed', v);

  // XP & PROGRESSION
  static int get xp => _prefs.getInt('xp') ?? 0;
  static set xp(int v) => _prefs.setInt('xp', v);

  static void addWin() {
    wins++;
    coins += 100; // Reward
    xp += 50;
    _checkLevelUp();
    if (!isGuest) {
      FirestoreService.updateStats(
          wins: wins, coins: coins, xp: xp, level: level);
    }
  }

  static void addLoss() {
    losses++;
    coins += 20; // Consolation
    xp += 10;
    _checkLevelUp();
    if (!isGuest) {
      FirestoreService.updateStats(
          losses: losses, coins: coins, xp: xp, level: level);
    }
  }

  static void _checkLevelUp() {
    // Simple Formula: Level up every 100 XP * Level
    // e.g. Lvl 1->2 needs 100 XP (2 wins). Lvl 2->3 needs 200 XP.
    int requiredXp = level * 100;
    if (xp >= requiredXp) {
      xp -= requiredXp; // Carry over excess XP
      level++;
      playSound(); // Ding!
    }
  }

  // STREAK TRACKING
  static int get currentStreak => _prefs.getInt('currentStreak') ?? 0;
  static set currentStreak(int v) => _prefs.setInt('currentStreak', v);

  static String get lastLoginDate => _prefs.getString('lastLoginDate') ?? "";
  static set lastLoginDate(String v) => _prefs.setString('lastLoginDate', v);

  // DECK MANAGEMENT
  static List<String> get ownedDecks =>
      _prefs.getStringList('ownedDecks') ?? ["Neon Deck", "Retro Deck"];
  static set ownedDecks(List<String> v) =>
      _prefs.setStringList('ownedDecks', v);

  static String get selectedDeck =>
      _prefs.getString('selectedDeck') ?? "Neon Deck";
  static set selectedDeck(String v) => _prefs.setString('selectedDeck', v);

  // AVATAR MANAGEMENT
  static List<String> get ownedAvatars =>
      _prefs.getStringList('ownedAvatars') ?? ["Classic Male"];
  static set ownedAvatars(List<String> v) =>
      _prefs.setStringList('ownedAvatars', v);

  static String get selectedAvatar =>
      _prefs.getString('selectedAvatar') ?? "Classic Male";
  static set selectedAvatar(String v) => _prefs.setString('selectedAvatar', v);

  // BANNER MANAGEMENT
  static List<String> get ownedBanners =>
      _prefs.getStringList('ownedBanners') ?? ["Basic Blue"];
  static set ownedBanners(List<String> v) =>
      _prefs.setStringList('ownedBanners', v);

  static String get selectedBanner =>
      _prefs.getString('selectedBanner') ?? "Basic Blue";
  static set selectedBanner(String v) => _prefs.setString('selectedBanner', v);

  // AWARD MANAGEMENT
  static String get selectedAward => _prefs.getString('selectedAward') ?? "";
  static set selectedAward(String v) => _prefs.setString('selectedAward', v);

  // CLAIMED TIERS (ELITE PASS)
  static List<String> get claimedTiers =>
      _prefs.getStringList('claimedTiers') ?? [];
  static set claimedTiers(List<String> v) =>
      _prefs.setStringList('claimedTiers', v);

  static void addClaimedTier(int tierLevel) {
    List<String> list = claimedTiers;
    String t = tierLevel.toString();
    if (!list.contains(t)) {
      list.add(t);
      claimedTiers = list;
    }
  }

  static void addDeck(String name) {
    List<String> list = ownedDecks;
    if (!list.contains(name)) {
      list.add(name);
      ownedDecks = list;
    }
  }

  static void addAvatar(String name) {
    List<String> list = ownedAvatars;
    if (!list.contains(name)) {
      list.add(name);
      ownedAvatars = list;
    }
  }

  static void addBanner(String name) {
    List<String> list = ownedBanners;
    if (!list.contains(name)) {
      list.add(name);
      ownedBanners = list;
    }
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    isInitialized = true;
  }

  static void playSound() {
    if (soundEnabled) {
      _audioPlayer.play(AssetSource('click.wav')).catchError((e) {
        // Fallback to SystemSound if file missing
        SystemSound.play(SystemSoundType.click);
      });
    }
  }

  static void playCardSound() {
    if (soundEnabled) {
      _audioPlayer.play(AssetSource('card_slide.wav')).catchError((e) {
        SystemSound.play(SystemSoundType.click);
      });
    }
  }

  static void playDrawSound() {
    if (soundEnabled) {
      _audioPlayer.play(AssetSource('draw.wav')).catchError((e) {
        SystemSound.play(SystemSoundType.click);
      });
    }
  }

  static void vibrate() {
    if (vibrationEnabled) HapticFeedback.lightImpact();
  }

  // Dummy save since setters auto-save
  static void save() {}

  /// Clears all user-specific data from SharedPreferences.
  /// Used when logging out to ensure the next session starts fresh (or Guest resets).
  static Future<void> resetProfile() async {
    await _prefs.remove('playerName');
    await _prefs.remove('email');
    await _prefs.remove('isGuest');
    await _prefs.remove('coins');
    await _prefs.remove('level');
    await _prefs.remove('wins');
    await _prefs.remove('losses');
    await _prefs.remove('ownedDecks');
    await _prefs.remove('selectedDeck');
    await _prefs.remove('ownedAvatars');
    await _prefs.remove('selectedAvatar');
    await _prefs.remove('lastSpinDate');
    await _prefs.remove('dailySpinsUsed');
    await _prefs.remove('profilePicPath'); // Clear profile photo
    await _prefs.remove('hasSeenTutorial'); // Reset tutorial
    // Keep Settings (Sound/Vib) as they are usually device-specific preferences
  }

  // AVATAR DATA (Shared)
  static final List<Map<String, dynamic>> avatarPack = [
    // FREE
    {
      "id": "Classic Male",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Felix",
      "price": 0
    },
    {
      "id": "Classic Female",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Aneka",
      "price": 0
    },

    // CHEAP (500)
    {
      "id": "Rookie Boy",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Bob",
      "price": 500
    },
    {
      "id": "Rookie Girl",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Alice",
      "price": 500
    },
    {
      "id": "Glasses Guy",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Caleb",
      "price": 500
    },
    {
      "id": "Happy Girl",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Daisy",
      "price": 500
    },

    // MID (1000-1500)
    {
      "id": "Cyber Punk",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Cyber",
      "price": 1000
    },
    {
      "id": "Cool Cat",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Leo",
      "price": 1000
    },
    {
      "id": "Bearded Man",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Jack",
      "price": 1200
    },
    {
      "id": "Ninja",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Ninja",
      "price": 1500
    },
    {
      "id": "Samurai",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Samurai",
      "price": 1500
    },

    // PREMIUM (2000-3000)
    {
      "id": "Robot V1",
      "url": "https://api.dicebear.com/7.x/bottts/png?seed=Robo1",
      "price": 2000
    },
    {
      "id": "Robot V2",
      "url": "https://api.dicebear.com/7.x/bottts/png?seed=Robo2",
      "price": 2000
    },
    {
      "id": "Monster Red",
      "url": "https://api.dicebear.com/7.x/bottts/png?seed=MonsterRed",
      "price": 2500
    },
    {
      "id": "Monster Green",
      "url": "https://api.dicebear.com/7.x/bottts/png?seed=MonsterGreen",
      "price": 2500
    },
    {
      "id": "Space Explorer",
      "url": "https://api.dicebear.com/7.x/adventurer/png?seed=Space",
      "price": 3000
    },
    {
      "id": "Wizard",
      "url": "https://api.dicebear.com/7.x/adventurer/png?seed=Wizard",
      "price": 3000
    },

    // LEGENDARY (5000+)
    {
      "id": "King",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=King",
      "price": 5000
    },
    {
      "id": "Queen",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Queen",
      "price": 5000
    },
    {
      "id": "Gold Bot",
      "url": "https://api.dicebear.com/7.x/bottts/png?seed=Gold",
      "price": 0
    },
    {
      "id": "Diamond",
      "url": "https://api.dicebear.com/7.x/avataaars/png?seed=Diamond",
      "price": 10000
    },
    {"id": "Gojo Suit", "url": "assets/gojo_suit.png", "price": 5000},
  ];

  static final List<Map<String, dynamic>> bannerPack = [
    {
      "id": "Basic Blue",
      "colors": [Color(0xFF2196F3), Color(0xFF21CBF3)],
      "price": 0
    },
    {
      "id": "Sunset",
      "colors": [Color(0xFFFF512F), Color(0xFFDD2476)],
      "price": 500
    },
    {
      "id": "Forest",
      "colors": [Color(0xFF11998e), Color(0xFF38ef7d)],
      "price": 500
    },
    {
      "id": "Purple Haze",
      "colors": [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      "price": 500
    },
    {
      "id": "Ocean View",
      "colors": [Color(0xFF00c6ff), Color(0xFF0072ff)],
      "price": 500
    },
    {
      "id": "Royal",
      "colors": [Color(0xFF2b5876), Color(0xFF4e4376)],
      "price": 1000
    },
    {
      "id": "Fire & Ice",
      "colors": [Color(0xFFC33764), Color(0xFF1D2671)],
      "price": 1000
    },
    {
      "id": "Neon City",
      "colors": [Color(0xFFf12711), Color(0xFFf5af19)],
      "price": 1000
    },
    {
      "id": "Lush Green",
      "colors": [Color(0xFF56ab2f), Color(0xFFa8e063)],
      "price": 1000
    },
    {
      "id": "Dark Void",
      "colors": [Color(0xFF000000), Color(0xFF434343)],
      "price": 2000
    },
    {
      "id": "Gold Rush",
      "colors": [Color(0xFFFFD700), Color(0xFFFDB931)],
      "price": 3000
    },
    {
      "id": "Midnight",
      "colors": [Color(0xFF232526), Color(0xFF414345)],
      "price": 3000
    },
    {
      "id": "Rainbow",
      "colors": [Color(0xFFFF0000), Color(0xFF0000FF)],
      "price": 5000
    },
    {
      "id": "Cyberpunk",
      "colors": [Color(0xFFff00cc), Color(0xFF333399)],
      "price": 5000
    },
    {
      "id": "Matrix",
      "colors": [Color(0xFF000000), Color(0xFF00FF00)],
      "price": 5000
    },
  ];

  static String getSelectedAvatarUrl() {
    // If not found, return default
    var item = avatarPack.firstWhere((a) => a['id'] == selectedAvatar,
        orElse: () => avatarPack[0]);
    return item['url'];
  }

  // RANK SYSTEM
  static Map<String, dynamic> getRankInfo() {
    int lvl = level;
    if (lvl >= 401)
      return {
        "name": "GOD PULSE",
        "color": Colors.white,
        "icon": Icons.all_inclusive_rounded,
        "glow": Colors.cyanAccent.withOpacity(0.8)
      };
    if (lvl >= 201)
      return {
        "name": "MASTER",
        "color": Colors.redAccent,
        "icon": Icons.auto_awesome_rounded,
        "glow": Colors.red.withOpacity(0.5)
      };
    if (lvl >= 101)
      return {
        "name": "DIAMOND",
        "color": Colors.blueAccent,
        "icon": Icons.diamond_rounded,
        "glow": Colors.blue.withOpacity(0.5)
      };
    if (lvl >= 61)
      return {
        "name": "PLATINUM",
        "color": Colors.cyanAccent,
        "icon": Icons.shield_rounded,
        "glow": Colors.cyan.withOpacity(0.4)
      };
    if (lvl >= 31)
      return {
        "name": "GOLD",
        "color": Colors.amber,
        "icon": Icons.workspace_premium_rounded,
        "glow": Colors.amber.withOpacity(0.4)
      };
    if (lvl >= 16)
      return {
        "name": "SILVER",
        "color": Colors.grey[300]!,
        "icon": Icons.military_tech_rounded,
        "glow": Colors.white24
      };
    if (lvl >= 6)
      return {
        "name": "BRONZE",
        "color": Colors.brown[400]!,
        "icon": Icons.shield_moon_rounded,
        "glow": Colors.transparent
      };
    return {
      "name": "BRONZE 1",
      "color": Colors.brown[400]!,
      "icon": Icons.shield_moon_rounded,
      "glow": Colors.transparent
    };
  }

  static void checkDailyStreak() {
    String today = DateTime.now().toString().split(' ')[0];
    if (lastLoginDate == today) return;

    DateTime last =
        lastLoginDate == "" ? DateTime.now() : DateTime.parse(lastLoginDate);
    int diff = DateTime.now().difference(last).inDays;

    if (diff == 1) {
      currentStreak += 1;
    } else if (diff > 1) {
      currentStreak = 1;
    } else if (lastLoginDate == "") {
      currentStreak = 1;
    }
    lastLoginDate = today;
  }

  // NOTIFICATIONS (Persistent Session)
  static List<Map<String, dynamic>> notifications = [];

  static void removeNotification(int id) {
    notifications.removeWhere((n) => n['id'] == id);
  }

  static void clearNotifications() {
    notifications.clear();
  }

  static void markAllNotificationsRead() {
    for (var n in notifications) {
      n['isRead'] = true;
    }
  }
}
