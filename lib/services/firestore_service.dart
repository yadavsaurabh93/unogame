import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data_manager.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// createOrUpdateUser:
  /// Called after successful Login/Signup.
  /// - If user doc doesn't exist, create it with defaults.
  /// - If it exists, fetch data and update local DataManager.
  static Future<void> syncUser(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // New User: Create with defaults
      final newUser = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? "Player",
        'coins': 1000,
        'level': 1,
        'wins': 0,
        'losses': 0,
        'joinedAt': FieldValue.serverTimestamp(),
        // Add more default fields here
      };
      await docRef.set(newUser);

      // Sync to Local
      DataManager.playerName = user.displayName ?? "Player";
      DataManager.email = user.email;
      DataManager.coins = 1000;
      DataManager.level = 1;
    } else {
      // Existing User: Sync to Local
      final data = doc.data() as Map<String, dynamic>;
      DataManager.playerName =
          data['displayName'] ?? user.displayName ?? "Player";
      DataManager.email = data['email'] ?? user.email;
      DataManager.coins = data['coins'] ?? 0;
      DataManager.level = data['level'] ?? 1;
      DataManager.wins = data['wins'] ?? 0;
      DataManager.losses = data['losses'] ?? 0;

      // Sync Inventory & Streak
      if (data['ownedDecks'] != null) {
        DataManager.ownedDecks = List<String>.from(data['ownedDecks']);
      }
      if (data['selectedDeck'] != null) {
        DataManager.selectedDeck = data['selectedDeck'];
      }
      if (data['ownedAvatars'] != null) {
        DataManager.ownedAvatars = List<String>.from(data['ownedAvatars']);
      }
      if (data['selectedAvatar'] != null) {
        DataManager.selectedAvatar = data['selectedAvatar'];
      }
      if (data['ownedBanners'] != null) {
        DataManager.ownedBanners = List<String>.from(data['ownedBanners']);
      }
      if (data['selectedBanner'] != null) {
        DataManager.selectedBanner = data['selectedBanner'];
      }
      if (data['selectedAward'] != null) {
        DataManager.selectedAward = data['selectedAward'];
      }
      if (data['claimedTiers'] != null) {
        DataManager.claimedTiers = List<String>.from(data['claimedTiers']);
      }
      if (data['currentStreak'] != null) {
        DataManager.currentStreak = data['currentStreak'];
      }
      if (data['lastLoginDate'] != null) {
        DataManager.lastLoginDate = data['lastLoginDate'];
      }
      if (data['dailySpinsUsed'] != null) {
        DataManager.dailySpinsUsed = data['dailySpinsUsed'];
      }
      if (data['lastSpinDate'] != null) {
        DataManager.lastSpinDate = data['lastSpinDate'];
      }
    }
    DataManager.isGuest = false;
    updateOnlineStatus(true);
  }

  /// Saves ALL local DataManager state to Firestore.
  /// Call this before logout or after major purchases.
  static Future<void> saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'coins': DataManager.coins,
      'level': DataManager.level,
      'wins': DataManager.wins,
      'losses': DataManager.losses,
      'ownedDecks': DataManager.ownedDecks,
      'selectedDeck': DataManager.selectedDeck,
      'ownedAvatars': DataManager.ownedAvatars,
      'selectedAvatar': DataManager.selectedAvatar,
      'ownedBanners': DataManager.ownedBanners,
      'selectedBanner': DataManager.selectedBanner,
      'selectedAward': DataManager.selectedAward,
      'claimedTiers': DataManager.claimedTiers,
      'currentStreak': DataManager.currentStreak,
      'lastLoginDate': DataManager.lastLoginDate,
      'dailySpinsUsed': DataManager.dailySpinsUsed,
      'lastSpinDate': DataManager.lastSpinDate,
      'lastSynced': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _db
        .collection('users')
        .orderBy('coins', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  static Future<void> updateCoins(int newBalance) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({'coins': newBalance});
  }

  static Future<void> updateProfile(
      {String? name, String? avatar, String? banner}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> updates = {};
    if (name != null) updates['displayName'] = name;
    if (avatar != null) updates['selectedAvatar'] = avatar;
    if (banner != null) updates['selectedBanner'] = banner;

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(user.uid).update(updates);
    }
  }

  static Future<void> updateStats(
      {int? wins, int? losses, int? level, int? coins, int? xp}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> updates = {};
    if (wins != null) updates['wins'] = wins;
    if (losses != null) updates['losses'] = losses;
    if (level != null) updates['level'] = level;
    if (coins != null) updates['coins'] = coins;
    if (xp != null) updates['xp'] = xp;

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(user.uid).update(updates);
    }
  }

  // --- FRIEND SYSTEM ---

  static Future<void> updateOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> sendFriendRequest(String targetUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == targetUid) return;

    await _db
        .collection('users')
        .doc(targetUid)
        .collection('requests')
        .doc(user.uid)
        .set({
      'fromUid': user.uid,
      'fromName': DataManager.playerName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> acceptFriendRequest(String fromUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Add to my friends list
    await _db.collection('users').doc(user.uid).update({
      'friends': FieldValue.arrayUnion([fromUid])
    });

    // 2. Add to their friends list
    await _db.collection('users').doc(fromUid).update({
      'friends': FieldValue.arrayUnion([user.uid])
    });

    // 3. Remove the request
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('requests')
        .doc(fromUid)
        .delete();
  }

  static Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    // We first get the list of friend UIDs
    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null || data['friends'] == null) return [];

      List<String> friendUids = List<String>.from(data['friends']);
      if (friendUids.isEmpty) return [];

      // Fetch full data for each friend
      final friendDocs =
          await _db.collection('users').where('uid', whereIn: friendUids).get();
      return friendDocs.docs.map((doc) => doc.data()).toList();
    });
  }

  static Stream<List<Map<String, dynamic>>> getPendingRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('requests')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => doc.data()).toList();
    });
  }

  static Future<void> removeFriend(String friendUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'friends': FieldValue.arrayRemove([friendUid])
    });
    await _db.collection('users').doc(friendUid).update({
      'friends': FieldValue.arrayRemove([user.uid])
    });
  }

  // --- BATTLE INVITE SYSTEM ---

  static Future<void> sendBattleInvite(String targetUid,
      [String? roomId]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == targetUid) return;

    await _db
        .collection('users')
        .doc(targetUid)
        .collection('battle_invites')
        .doc(user.uid)
        .set({
      'fromUid': user.uid,
      'fromName': DataManager.playerName,
      'roomId': roomId ?? "",
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  static Stream<List<Map<String, dynamic>>> getBattleInvitesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('battle_invites')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => doc.data()).toList();
    });
  }

  static Future<void> clearBattleInvite(String fromUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('battle_invites')
        .doc(fromUid)
        .delete();
  }
}
