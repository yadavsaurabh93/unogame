import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../services/firestore_service.dart';
import '../widgets/background.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await FirestoreService.searchUsers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (DataManager.isGuest) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ModernBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.white24),
                const SizedBox(height: 20),
                Text("Please Login to add Real Friends",
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Text("Guest accounts cannot use social features.",
                    style: GoogleFonts.poppins(
                        color: Colors.white30, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("SOCIAL",
            style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 24)),
        centerTitle: true,
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              _searchBar(),
              if (_searchController.text.isNotEmpty)
                _buildSearchResults()
              else
                Expanded(
                  child: Column(
                    children: [
                      _buildPendingRequests(),
                      _buildFriendsList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchUsers,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search real players by name...",
          hintStyle: GoogleFonts.poppins(color: Colors.white38),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.cyanAccent),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers("");
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Text("No players found",
                      style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) {
                    final player = _searchResults[i];
                    if (player['uid'] == FirebaseAuth.instance.currentUser?.uid)
                      return const SizedBox();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(player[
                                'selectedAvatar'] ??
                            "https://api.dicebear.com/7.x/avataaars/png?seed=Felix"),
                      ),
                      title: Text(player['displayName'] ?? "Player",
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text("Level ${player['level']}",
                          style: const TextStyle(color: Colors.white54)),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add,
                            color: Colors.cyanAccent),
                        onPressed: () {
                          FirestoreService.sendFriendRequest(player['uid']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Friend request sent!")),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildPendingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getPendingRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox();
        final requests = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Text("PENDING REQUESTS (${requests.length})",
                  style: GoogleFonts.poppins(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: requests.length,
                itemBuilder: (ctx, i) {
                  final req = requests[i];
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(req['fromName'],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis)),
                        IconButton(
                          icon: const Icon(Icons.check,
                              color: Colors.greenAccent, size: 20),
                          onPressed: () => FirestoreService.acceptFriendRequest(
                              req['fromUid']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20),
            child: Text("MY FRIENDS",
                style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.getFriendsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 60, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text("No friends yet. Search and add real players!",
                            style: GoogleFonts.poppins(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                final friends = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: friends.length,
                  itemBuilder: (ctx, i) => _playerTile(friends[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerTile(Map<String, dynamic> player) {
    bool online = player['isOnline'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[900],
                backgroundImage: NetworkImage(player['selectedAvatar'] ??
                    "https://api.dicebear.com/7.x/avataaars/png?seed=Felix"),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: online ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF0F0F1E), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player['displayName'] ?? "Player",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(online ? "Online" : "Offline",
                    style: GoogleFonts.poppins(
                        color: online ? Colors.greenAccent : Colors.white24,
                        fontSize: 12)),
              ],
            ),
          ),
          if (online)
            TextButton(
              onPressed: () {
                DataManager.playSound();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          "Game invite sent to ${player['displayName']}!")),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("INVITE",
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white24),
            onPressed: () => _showFriendOptions(player),
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(Map<String, dynamic> friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.redAccent),
            title: Text("Remove ${friend['displayName']}",
                style: const TextStyle(color: Colors.white)),
            onTap: () {
              FirestoreService.removeFriend(friend['uid']);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
