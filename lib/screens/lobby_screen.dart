import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import '../services/data_manager.dart';
import '../widgets/background.dart';
import '../widgets/exit_button.dart';
import '../widgets/modern_button.dart';
import 'online_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String? autoJoinRoom;
  final String? autoJoinPid;
  final String? autoJoinName;
  final bool? isHost;

  const LobbyScreen(
      {super.key,
      this.autoJoinRoom,
      this.autoJoinPid,
      this.autoJoinName,
      this.isHost});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _nC = TextEditingController();
  final _rC = TextEditingController();
  bool _isLoading = false;
  String? _rid;
  String? _myPid;
  String? _hostId;
  List<Player> _pl = [];
  StreamSubscription? _roomSub;
  String _selectedDeck = DataManager.selectedDeck;

  @override
  void initState() {
    super.initState();
    // Auto-fill from DataManager if exists
    if (DataManager.isInitialized) {
      _nC.text = DataManager.playerName;
    }

    // HANDLE AUTO-JOIN (Coming from WinnerScreen)
    if (widget.autoJoinRoom != null && widget.autoJoinPid != null) {
      _rid = widget.autoJoinRoom;
      _myPid = widget.autoJoinPid;
      _nC.text = widget.autoJoinName ?? DataManager.playerName;
      if (widget.isHost == true) _hostId = _myPid;

      // Allow slight delay for UI to settle then listen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _listenToRoom(_rid!);
      });
    }
  }

  void _j(String r, bool h) {
    if (r.isEmpty && !h) return;
    if (_nC.text.isEmpty) return;

    // SAVE NAME
    DataManager.playerName = _nC.text;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    String pid =
        "p${Random().nextInt(999999)}"; // Increased range (Fix ID collision)
    String finalRoom = h ? "${Random().nextInt(9000) + 1000}" : r;
    String name = _nC.text;

    setState(() {
      _myPid = pid;
      _rid = finalRoom;
      _pl = [Player(id: pid, name: name)];
      if (h) _hostId = pid;
    });

    if (h) {
      _db.child("rooms/$finalRoom").set({
        "status": "w",
        "direction": 1,
        "host": pid,
        "winners": null,
        "penalty": 0,
        "reactions": {},
        "players": {
          pid: {"name": name, "count": 0}
        }
      }).then((_) {
        _listenToRoom(finalRoom);
        if (mounted) setState(() => _isLoading = false);
      });
    } else {
      _db
          .child("rooms/$finalRoom/players/$pid")
          .set({"name": name, "count": 0}).then((_) {
        _listenToRoom(finalRoom);
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  void _listenToRoom(String r) {
    _roomSub = _db.child("rooms/$r").onValue.listen((e) {
      final data = e.snapshot.value;
      if (data == null || data is! Map) return;
      final d = data;

      if (d['host'] != null) setState(() => _hostId = d['host'].toString());

      if (d['players'] != null && d['players'] is Map) {
        Map playersMap = d['players'] as Map;
        List<Player> t = [];
        playersMap.forEach((k, v) {
          if (v is Map) {
            t.add(Player(id: k.toString(), name: v['name'].toString()));
          }
        });
        // CRITICAL SORT: Ensures everyone has same list order
        t.sort((a, b) => a.id.compareTo(b.id));

        if (_myPid != null && _myPid != _hostId) {
          if (!playersMap.containsKey(_myPid)) {
            if (!_isLoading) {
              _roomSub?.cancel();
              setState(() {
                _rid = null;
                _myPid = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You were kicked by host")));
              return;
            }
          }
        }
        if (mounted) setState(() => _pl = t);
      }

      if (d['status'] == "p") {
        _roomSub?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          bool amIHost = _myPid == _hostId;
          if (mounted)
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => OnlineGameScreen(
                        roomId: r,
                        myId: _myPid!,
                        myName: _nC.text,
                        isHost: amIHost)));
        });
      }
    });
  }

  void _kickPlayer(String pid) {
    if (_rid != null) _db.child("rooms/$_rid/players/$pid").remove();
  }

  void _showDeckPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("CHOOSE GAME DECK",
                style: GoogleFonts.blackOpsOne(
                    color: Colors.white, fontSize: 20, letterSpacing: 1.5)),
            const SizedBox(height: 5),
            Text("Select one of your owned decks",
                style:
                    GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: DataManager.ownedDecks.length,
                itemBuilder: (ctx, i) {
                  String deck = DataManager.ownedDecks[i];
                  bool isSel = _selectedDeck == deck;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDeck = deck);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 130,
                      margin: const EdgeInsets.only(right: 15, bottom: 20),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSel ? Colors.blueAccent : Colors.white12,
                            width: 2),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    blurRadius: 10)
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              deck.contains("Marvel") ||
                                      deck.contains("Spiderman") ||
                                      deck.contains("Ironman")
                                  ? Icons.stars
                                  : Icons.style,
                              color: isSel ? Colors.blueAccent : Colors.white70,
                              size: 40),
                          const SizedBox(height: 10),
                          Text(deck,
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                              textAlign: TextAlign.center),
                          if (isSel)
                            const Icon(Icons.check_circle,
                                color: Colors.blueAccent, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _startGame() {
    if (_pl.isEmpty) return;
    _pl.sort((a, b) => a.id.compareTo(b.id)); // Double Ensure Sort
    String firstPlayerId = _pl[0].id;
    _db.child("rooms/$_rid").update({
      "status": "p",
      "turn": firstPlayerId,
      "topCard": "red_one", // Default start card
      "activePlayers": _pl.map((e) => e.id).toList(),
      "winners": null, // Reset winners
      "penalty": 0,
      "direction": 1,
      "gameStartedAt": ServerValue.timestamp, // Mark start time
      "reactions": {},
      "selectedDeck": _selectedDeck, // SYNC DECK FOR EVERYONE
      "deck": _selectedDeck // Ensure deck key is used for reliability
    });
  }

  void _leaveLobby() {
    if (_rid != null && _myPid != null) {
      _roomSub?.cancel();
      _db.child("rooms/$_rid/players/$_myPid").remove();
    }
    // Directly go back to main menu
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }

  InputDecoration _neonInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white10,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.cyan.withOpacity(0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.cyan, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rid != null) {
      return Scaffold(
          body: ModernBackground(
              child: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, child: ExitButton(onTap: _leaveLobby)),
            Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ROOM: $_rid",
                        style: GoogleFonts.blackOpsOne(
                            fontSize: 50, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text(_myPid == _hostId ? "You are Host" : "Waiting...",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 18)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                          itemCount: _pl.length,
                          itemBuilder: (c, i) {
                            bool isHost = _pl[i].id == _hostId;
                            bool isMe = _pl[i].id == _myPid;
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                            "${_pl[i].name} ${isHost ? '(HOST)' : ''}",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22)),
                                      ),
                                    ),
                                    if (_myPid == _hostId && !isMe)
                                      IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _kickPlayer(_pl[i].id))
                                  ],
                                ),
                              ),
                            );
                          }),
                    ),
                    if (_myPid == _hostId)
                      Column(
                        children: [
                          ModernButton(
                            label: "CHANGE DECK ($_selectedDeck)",
                            onTap: _showDeckPicker,
                            icon: Icons.style,
                            baseColor: Colors.blueGrey,
                          ),
                          const SizedBox(height: 15),
                          ModernButton(
                              label: "START GAME",
                              onTap: _startGame,
                              icon: Icons.play_arrow,
                              baseColor: Colors.green),
                        ],
                      ),
                  ]),
            ),
          ],
        ),
      )));
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ModernBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 0, left: 0, child: ExitButton()),
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24, width: 1.5),
                      boxShadow: [
                        const BoxShadow(color: Colors.black26, blurRadius: 30)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("MULTIPLAYER",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 30),
                            TextField(
                                controller: _nC,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                                decoration: _neonInputDecoration("Nickname")),
                            const SizedBox(height: 20),
                            TextField(
                                controller: _rC,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                                decoration: _neonInputDecoration(
                                    "Room Code (Optional)")),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                    child: ModernButton(
                                        label: "JOIN",
                                        width: double.infinity,
                                        onTap: () => _j(_rC.text, false),
                                        baseColor: const Color(0xFF4A90E2),
                                        icon: Icons.login,
                                        isLoading: _isLoading)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: ModernButton(
                                        label: "CREATE",
                                        width: double.infinity,
                                        onTap: () => _j("", true),
                                        baseColor: const Color(0xFF9013FE),
                                        icon: Icons.add,
                                        isLoading: _isLoading)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
