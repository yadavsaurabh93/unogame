import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uno_game/services/firestore_service.dart';
import '../models/player.dart';
import '../models/uno_card.dart';
import '../services/data_manager.dart';
import '../utils/particles.dart';
import '../utils/shake_widget.dart';
import '../widgets/awesome_card.dart';
import '../widgets/background.dart';
import '../widgets/color_picker.dart';
import '../widgets/glow_avatar.dart';
import 'winner_screen.dart';

class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final String myId;
  final String myName;
  final bool isHost;
  const OnlineGameScreen({
    super.key,
    required this.roomId,
    required this.myId,
    this.myName = "Guest",
    required this.isHost,
  });
  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey();
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _discardKey = GlobalKey();
  late AnimationController _unoPulseCtrl;
  StreamSubscription? _gameSub;

  List<UnoCard> myHand = [];
  UnoCard topCard =
      UnoCard(id: "init", color: CardColor.red, value: CardValue.zero);
  bool isMyTurn = false;
  bool _isProcessingAction = false;
  bool _isExecutingPenalty = false;
  String currentTurnName = "WAITING";
  bool isEmojiMenuOpen = false;
  bool _showTurnAlert = false;

  List<Widget> _flyingCards = [];
  List<Widget> _particles = [];
  List<Widget> _emojis = [];
  List<Map<String, String>> _chatMessages = []; // Chat List
  bool _showChat = false;
  bool _hasUnread = false;
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  String alertText = "";
  Color alertColor = Colors.transparent;
  double alertScale = 0.0;

  bool showUnoBtn = false;
  Timer? _penaltyTimer;
  Timer? _integrityTimer; // Added Watchdog Timer
  bool _unoPressed = false;
  bool _hasDrawn = false;
  int direction = 1;
  int pendingPenalty = 0;
  List<String> winners = [];
  List<Player> allPlayers = [];
  List<String> activePlayersIds = [];
  Map<String, int> _prevCardCounts = {};
  bool _hasNavigatedToWinner = false;
  String? _lastReactionId;
  String _deck = "Neon Deck";
  bool _showTutorial = false; // TUTORIAL FLAG

  // HOST PERSISTENCE (Overlay Support)
  bool _showWinnerOverlay = false;
  String _winnerTitle = "";
  bool _winnerIsVictory = false;

  @override
  void initState() {
    super.initState();
    winners = [];
    _hasNavigatedToWinner = false;
    _unoPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 300), _initOnline);
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _penaltyTimer?.cancel();
    _integrityTimer?.cancel(); // Cancel watchdog
    _unoPulseCtrl.dispose();
    super.dispose();
  }

  void _initOnline() {
    for (int i = 0; i < 7; i++) myHand.add(_randomCard());
    myHand.sort();
    _updateMyCardCount();

    // TUTORIAL CHECK
    if (!DataManager.hasSeenTutorial) {
      if (mounted) setState(() => _showTutorial = true);
    }

    // HOST WATCHDOG: Keeps the game alive if someone leaves
    if (widget.isHost) {
      _integrityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted || activePlayersIds.isEmpty) return;
        _checkTurnIntegrity();
      });
    }

    _gameSub = _db.child("rooms/${widget.roomId}").onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      if (val == null || val is! Map) return;
      final data = val;

      if (data['topCard'] != null) {
        UnoCard newTop = UnoCard.fromData(data['topCard'].toString());
        if (newTop.toData() != topCard.toData()) {
          setState(() {
            topCard = newTop;
          });
          _spawnParticles(_getPos(_discardKey), topCard.colorHex);
        }
      }

      if (data['direction'] != null)
        direction = int.tryParse(data['direction'].toString()) ?? 1;
      if (data['penalty'] != null)
        pendingPenalty = int.tryParse(data['penalty'].toString()) ?? 0;
      if (data['deck'] != null) {
        setState(() => _deck = data['deck'].toString());
      }

      if (data['winners'] != null && data['winners'] is List) {
        setState(() => winners = List<String>.from(data['winners']));
        if (winners.contains(widget.myId) && !_hasNavigatedToWinner) {
          _hasNavigatedToWinner = true;
          _win("YOU WON!", true);
        }
      } else {
        if (data['winners'] == null) setState(() => winners = []);
      }

      if (data['reactions'] != null && data['reactions'] is Map) {
        Map r = data['reactions'] as Map;
        String latestId = r.keys.last.toString();
        if (_lastReactionId != latestId) {
          _lastReactionId = latestId;
          String em = r[latestId]['emoji'].toString();
          String from = r[latestId]['from'].toString();
          if (from != widget.myId) _showFloatingEmoji(em);
        }
      }

      if (data['players'] != null && data['players'] is Map) {
        Map playersMap = data['players'] as Map;
        List<Player> tempPlayers = [];
        playersMap.forEach((key, value) {
          if (value is Map) {
            String pId = key.toString();
            String pName = value['name'].toString();
            int cCount = int.tryParse(value['count'].toString()) ?? 0;
            if (pId != widget.myId && _prevCardCounts.containsKey(pId)) {
              int prev = _prevCardCounts[pId] ?? 0;
              if (cCount > prev) {
                int diff = cCount - prev;
                _showAlert("$pName DREW +$diff", Colors.orange);
              }
            }
            _prevCardCounts[pId] = cCount;
            tempPlayers.add(Player(id: pId, name: pName, cardCount: cCount));
          }
        });

        // FIXED SORTING: Critical for Turn Order
        tempPlayers.sort((a, b) => a.id.compareTo(b.id));

        List<String> currentActive = tempPlayers
            .where((p) => !winners.contains(p.id))
            .map((p) => p.id)
            .toList();

        setState(() {
          allPlayers = tempPlayers;
          activePlayersIds = currentActive;
        });

        if (currentActive.length == 1 &&
            winners.isNotEmpty &&
            !_hasNavigatedToWinner) {
          if (currentActive.first == widget.myId) {
            _hasNavigatedToWinner = true;
            _win("GAME OVER", false);
          }
        }
      }

      // TURN LOGIC
      if (data['turn'] != null) {
        String turnId = data['turn'].toString();

        if (turnId == widget.myId) {
          // IT IS MY TURN
          if (pendingPenalty > 0) {
            // I HAVE A PENALTY (+2/+4)
            if (!_isExecutingPenalty) {
              setState(() {
                isMyTurn = true; // Still my turn, but locked
                _isProcessingAction = true; // Block manual play
                currentTurnName = "PENALTY +$pendingPenalty";
                _isExecutingPenalty = true;
              });
              DataManager.vibrate();
              Future.delayed(
                  const Duration(milliseconds: 1500), _handlePenalty);
            }
          } else {
            // NORMAL TURN
            if (!isMyTurn || _isProcessingAction) {
              setState(() {
                isMyTurn = true;
                _isProcessingAction = false; // UNLOCK UI
                _hasDrawn = false;
                currentTurnName = "YOUR TURN";
                _showTurnAlert = true;
              });
              DataManager.vibrate();
              DataManager.playSound();
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _showTurnAlert = false);
              });
            }
          }
        } else {
          // OPPONENT TURN
          String tName = "OPPONENT";
          try {
            var p = allPlayers.firstWhere((p) => p.id == turnId,
                orElse: () => Player(id: "", name: "OPPONENT"));
            tName = p.name;
          } catch (e) {
            tName = "OPPONENT";
          }

          setState(() {
            isMyTurn = false;
            _isProcessingAction = false;
            _isExecutingPenalty = false;
            currentTurnName = "$tName'S TURN";
          });
        }
      }

      // CHAT LISTENER
      if (data['messages'] != null && data['messages'] is Map) {
        Map msgs = data['messages'] as Map;
        List<Map<String, String>> loaded = [];
        msgs.forEach((k, v) {
          if (v is Map) {
            loaded.add({
              "id": k.toString(),
              "name": v['name'].toString(),
              "msg": v['msg'].toString(),
              "uid": v['uid'].toString()
            });
          }
        });
        // Sort by ID (timestamp)
        loaded.sort((a, b) => a['id']!.compareTo(b['id']!));

        if (loaded.length > _chatMessages.length) {
          // New message arrived
          if (!_showChat) setState(() => _hasUnread = true);
          // Auto scroll
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_chatScroll.hasClients)
              _chatScroll.jumpTo(_chatScroll.position.maxScrollExtent);
          });
        }
        setState(() => _chatMessages = loaded);
      }
    });
  }

  void _checkTurnIntegrity() async {
    final s = await _db.child("rooms/${widget.roomId}").get();
    if (s.value == null) return;
    final d = s.value as Map;
    String cTurn = d['turn']?.toString() ?? "";

    if (!activePlayersIds.contains(cTurn)) {
      _showAlert("FIXING STUCK TURN...", Colors.orange);
      _forceAdvanceTurn(cTurn);
    }
  }

  void _forceAdvanceTurn(String stuckId) {
    if (activePlayersIds.isEmpty) return;
    activePlayersIds.sort();

    int currentIdx = activePlayersIds.indexOf(stuckId);
    if (currentIdx == -1) currentIdx = 0; // Fallback

    int count = activePlayersIds.length;
    int rawNext = currentIdx + (1 * direction);
    int nextIndex = (rawNext % count + count) % count;

    _db
        .child("rooms/${widget.roomId}")
        .update({"turn": activePlayersIds[nextIndex]});
  }

  void _sendReaction(String emoji) {
    String rid = DateTime.now().millisecondsSinceEpoch.toString();
    _db
        .child("rooms/${widget.roomId}/reactions/$rid")
        .set({"emoji": emoji, "from": widget.myId});
    _showFloatingEmoji(emoji);
    setState(() => isEmojiMenuOpen = false);
  }

  void _sendChat() {
    if (_chatCtrl.text.trim().isEmpty) return;
    String mid = DateTime.now().millisecondsSinceEpoch.toString();
    _db.child("rooms/${widget.roomId}/messages/$mid").set({
      "name": widget.myName,
      "msg": _chatCtrl.text.trim(),
      "uid": widget.myId
    });
    _chatCtrl.clear();
  }

  void _showFloatingEmoji(String emoji) {
    final k = UniqueKey();
    setState(() {
      _emojis.add(TweenAnimationBuilder(
          key: k,
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(seconds: 2),
          builder: (c, val, ch) {
            double jump = sin(val * pi) * 1.5;
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 -
                  20 +
                  (sin(val * 15) * 40),
              bottom: 100 + (val * 500),
              child: Transform.scale(
                scale: 1.0 + (jump * 0.5),
                child: Opacity(
                    opacity: 1 - val,
                    child: Text(emoji, style: const TextStyle(fontSize: 50))),
              ),
            );
          },
          onEnd: () {
            if (mounted)
              setState(
                  () => _emojis.removeWhere((element) => element.key == k));
          }));
    });
  }

  void _dismissTutorial() {
    DataManager.hasSeenTutorial = true;
    setState(() => _showTutorial = false);
  }

  void _handlePenalty() async {
    _showAlert("DRAWING +$pendingPenalty", Colors.orange);
    _shakeKey.currentState?.shake();
    for (int i = 0; i < pendingPenalty; i++) {
      if (!mounted) return;
      setState(() {
        myHand.add(_randomCard());
        DataManager.playDrawSound();
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() => myHand.sort());
    _updateMyCardCount();
    await _db.child("rooms/${widget.roomId}").update({"penalty": 0});
    _passTurn();
  }

  void _updateMyCardCount() {
    _db
        .child("rooms/${widget.roomId}/players/${widget.myId}")
        .update({"count": myHand.length});
  }

  UnoCard _randomCard() {
    int r = Random().nextInt(100);
    return (r < 10)
        ? UnoCard(
            id: "${Random().nextInt(9999)}",
            color: CardColor.black,
            value: Random().nextBool() ? CardValue.wildFour : CardValue.wild)
        : UnoCard(
            id: "${Random().nextInt(9999)}",
            color: CardColor.values[Random().nextInt(4)],
            value: CardValue.values[Random().nextInt(13)]);
  }

  void _playCard(UnoCard c) async {
    if (!isMyTurn || _isProcessingAction || activePlayersIds.isEmpty) {
      if (!isMyTurn) DataManager.vibrate();
      return;
    }

    if (c.canPlayOn(topCard)) {
      if (c.isWild) {
        CardColor? col = await showDialog(
            context: context, builder: (_) => const ColorPicker());
        if (col == null) return;
        c.color = col;
      }

      setState(() {
        myHand.remove(c);
        isMyTurn = false;
        _isProcessingAction = true;
      });
      _updateMyCardCount();

      _flyCard(
          start: const Offset(150, 600),
          end: _getPos(_discardKey),
          card: c,
          onComplete: () {
            DataManager.playCardSound();
          });

      int nextSteps = 1;
      int penaltyToAdd = 0;

      List<String> validActive = allPlayers
          .where((p) => !winners.contains(p.id))
          .map((p) => p.id)
          .toList();
      validActive.sort();

      int playerCount = validActive.length;

      if (c.value == CardValue.reverse) {
        if (playerCount == 2) {
          nextSteps = 2;
          _showAlert("REVERSE = SKIP!", Colors.orange);
        } else {
          direction *= -1;
          nextSteps = 1;
          _showAlert("REVERSING!", Colors.blue);
        }
      } else if (c.value == CardValue.skip) {
        nextSteps = 2;
        _showAlert("SKIPPING!", Colors.redAccent);
      } else if (c.value == CardValue.plusTwo) {
        nextSteps = 1;
        penaltyToAdd = 2;
      } else if (c.value == CardValue.wildFour) {
        nextSteps = 1;
        penaltyToAdd = 4;
      }

      String nextPlayerId = _calculateNextPlayer(
          current: widget.myId,
          players: validActive,
          step: nextSteps,
          dir: direction);

      Map<String, Object> updates = {
        "topCard": c.toData(),
        "turn": nextPlayerId,
        "direction": direction
      };
      if (penaltyToAdd > 0) updates["penalty"] = pendingPenalty + penaltyToAdd;

      _db.child("rooms/${widget.roomId}").update(updates);

      if (myHand.isEmpty) {
        List<String> updatedWinners = List.from(winners)..add(widget.myId);
        _db.child("rooms/${widget.roomId}").update({"winners": updatedWinners});
        return;
      }

      if (myHand.length == 1) {
        setState(() {
          showUnoBtn = true;
          _unoPressed = false;
        });
        _showAlert("SAY UNO!", Colors.yellow);
        _penaltyTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          if (!_unoPressed && myHand.length == 1) {
            _showAlert("CAUGHT! +2", Colors.red);
            _shakeKey.currentState?.shake();
            setState(() {
              myHand.add(_randomCard());
              myHand.add(_randomCard());
              showUnoBtn = false;
            });
            _updateMyCardCount();
          } else {
            setState(() => showUnoBtn = false);
          }
        });
      }
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _draw() {
    if (!isMyTurn || _hasDrawn || _isProcessingAction) return;
    DataManager.playDrawSound();
    setState(() {
      myHand.add(_randomCard());
      myHand.sort();
      _hasDrawn = true;
      showUnoBtn = false;
    });
    _updateMyCardCount();

    if (!myHand.last.canPlayOn(topCard)) {
      Future.delayed(const Duration(milliseconds: 800), _passTurn);
    }
  }

  String _calculateNextPlayer(
      {required String current,
      required List<String> players,
      required int step,
      required int dir}) {
    if (players.isEmpty) return current;
    int curIdx = players.indexOf(current);
    if (curIdx == -1) return players[0];

    int count = players.length;
    int rawNext = curIdx + (step * dir);
    int nextIndex = (rawNext % count + count) % count;
    return players[nextIndex];
  }

  void _passTurn() {
    if (activePlayersIds.isNotEmpty) {
      activePlayersIds.sort();

      String nextP = _calculateNextPlayer(
          current: widget.myId,
          players: activePlayersIds,
          step: 1,
          dir: direction);

      _db.child("rooms/${widget.roomId}").update({"turn": nextP});
      if (mounted)
        setState(() {
          isMyTurn = false;
          _isProcessingAction = false;
        });
    }
  }

  void _flyCard(
      {required Offset start,
      required Offset end,
      required UnoCard card,
      required VoidCallback onComplete}) {
    final k = UniqueKey();
    setState(() => _flyingCards.add(TweenAnimationBuilder(
        key: k,
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (c, v, ch) {
          double dx = lerpDouble(start.dx, end.dx, v)!;
          double dy = lerpDouble(start.dy, end.dy, v)!;
          return Positioned(
            left: dx,
            top: dy,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateZ(v * 4 * pi)
                ..rotateY(v * pi)
                ..scale(0.5 + 0.5 * v),
              child: AwesomeCard(card: card, size: const Size(50, 75)),
            ),
          );
        },
        onEnd: () {
          if (mounted) {
            setState(() => _flyingCards.removeWhere((w) => w.key == k));
            onComplete();
          }
        })));
  }

  void _spawnParticles(Offset pos, Color color) {
    if (!mounted) return;
    final k = UniqueKey();
    setState(() => _particles.add(Positioned(
        key: k,
        left: 0,
        top: 0,
        child: ParticleSystem(position: pos, color: color))));
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _particles.removeWhere((w) => w.key == k));
    });
  }

  void _showAlert(String t, Color c) {
    if (!mounted) return;
    setState(() {
      alertText = t;
      alertColor = c;
      alertScale = 1.0;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => alertScale = 0.0);
    });
  }

  void _win(String w, bool isVictory) {
    SystemSound.play(SystemSoundType.click);

    if (isVictory) {
      DataManager.addWin();
      FirestoreService.updateStats(
          wins: DataManager.wins,
          coins: DataManager.coins,
          level: DataManager.level);
      _showAlert("VICTORY! +50 XP", Colors.amber);
    } else {
      DataManager.addLoss();
      FirestoreService.updateStats(
          losses: DataManager.losses,
          coins: DataManager.coins,
          level: DataManager.level);
    }

    if (widget.isHost && activePlayersIds.length > 1) {
      setState(() {
        _winnerTitle = w;
        _winnerIsVictory = isVictory;
        _showWinnerOverlay = true;
      });
      return;
    }

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => WinnerScreen(
                w: w,
                m: isVictory,
                isOnline: true,
                roomId: widget.roomId,
                myId: widget.myId,
                myName: widget.myName,
                isHost: widget.isHost)));
  }

  Offset _getPos(GlobalKey k) {
    RenderBox? b = k.currentContext?.findRenderObject() as RenderBox?;
    return b != null ? b.localToGlobal(Offset.zero) : Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    List<Player> displayOpponents = allPlayers
        .where((p) => p.id != widget.myId && activePlayersIds.contains(p.id))
        .toList();

    Color statusColor = isMyTurn
        ? (pendingPenalty > 0 ? Colors.orange : Colors.greenAccent)
        : Colors.redAccent;
    Color statusShadow = isMyTurn
        ? (pendingPenalty > 0 ? Colors.orangeAccent : Colors.green)
        : Colors.red;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
      },
      child: Scaffold(
        body: ShakeWidget(
          key: _shakeKey,
          child: ModernBackground(
            child: SafeArea(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 15),
                        color: Colors.black54,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("ROOM: ${widget.roomId}",
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold)),
                            GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.exit_to_app,
                                    color: Colors.red)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: displayOpponents.length,
                            itemBuilder: (context, index) {
                              bool isOppTurn = currentTurnName.contains(
                                  displayOpponents[index].name.toUpperCase());
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  decoration: isOppTurn
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                              BoxShadow(
                                                  color: Colors.red,
                                                  blurRadius: 20)
                                            ])
                                      : null,
                                  child: GlowAvatar(
                                      name: displayOpponents[index].name,
                                      color: Colors.primaries[Random()
                                          .nextInt(Colors.primaries.length)],
                                      count: displayOpponents[index].cardCount),
                                ),
                              );
                            }),
                      ),
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                key: _discardKey,
                                child: AwesomeCard(
                                    card: topCard,
                                    size: const Size(120, 170),
                                    deck: _deck),
                              ),
                              const SizedBox(width: 30),
                              GestureDetector(
                                onTap: _draw,
                                child: Container(
                                    key: _deckKey,
                                    child: AwesomeBack(
                                        size: const Size(120, 170),
                                        deck: _deck)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          currentTurnName,
                          style: GoogleFonts.blackOpsOne(
                              color: statusColor,
                              fontSize: 32,
                              shadows: [
                                BoxShadow(color: statusShadow, blurRadius: 20)
                              ]),
                        ),
                      ),
                      SizedBox(
                        height: 250,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("MY CARDS: ${myHand.length}",
                                style: GoogleFonts.rajdhani(
                                    color: Colors.white54, fontSize: 16)),
                            const SizedBox(height: 5),
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics()),
                                clipBehavior: Clip.none,
                                scrollDirection: Axis.horizontal,
                                cacheExtent: 1000,
                                padding: const EdgeInsets.only(
                                    left: 20, right: 100, top: 40, bottom: 20),
                                itemCount: myHand.length,
                                itemBuilder: (ctx, i) {
                                  bool valid = myHand[i].canPlayOn(topCard);
                                  return Align(
                                    widthFactor: 0.7,
                                    child: Draggable<UnoCard>(
                                      affinity: Axis
                                          .vertical, // Fixes scroll conflict
                                      data: myHand[i],
                                      feedback: AwesomeCard(
                                          card: myHand[i],
                                          size: const Size(100, 150),
                                          deck: _deck),
                                      childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: AwesomeCard(
                                              card: myHand[i],
                                              size: const Size(80, 120),
                                              deck: _deck)),
                                      child: GestureDetector(
                                        onTap: () => _playCard(myHand[i]),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          transform: Matrix4.identity()
                                            ..translate(
                                                0.0,
                                                (valid &&
                                                        isMyTurn &&
                                                        pendingPenalty == 0)
                                                    ? -30.0
                                                    : 0.0),
                                          child: AwesomeCard(
                                              card: myHand[i],
                                              size: const Size(90, 130),
                                              glow: valid &&
                                                  isMyTurn &&
                                                  pendingPenalty == 0,
                                              deck: _deck),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ..._particles,
                  ..._flyingCards,
                  ..._emojis,
                  if (isEmojiMenuOpen)
                    Positioned(
                      right: 80,
                      bottom: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            color: Colors.white10,
                            child: Row(
                              children: ["😂", "😡", "😭", "😎", "🤡", "❤️"]
                                  .map((e) => GestureDetector(
                                        onTap: () {
                                          SystemSound.play(
                                              SystemSoundType.click);
                                          _sendReaction(e);
                                        },
                                        child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 5),
                                            padding: const EdgeInsets.all(5),
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 30))),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 20,
                    bottom: 200,
                    child: FloatingActionButton(
                      backgroundColor: Colors.purpleAccent,
                      child:
                          const Icon(Icons.emoji_emotions, color: Colors.white),
                      onPressed: () =>
                          setState(() => isEmojiMenuOpen = !isEmojiMenuOpen),
                    ),
                  ),
                  Center(
                      child: AnimatedScale(
                          scale: alertScale,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.bounceOut,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 20),
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  border:
                                      Border.all(color: alertColor, width: 4),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(alertText,
                                  style: GoogleFonts.blackOpsOne(
                                      fontSize: 40, color: Colors.white))))),
                  if (_showTurnAlert)
                    Center(
                        child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.black87,
                          border:
                              Border.all(color: Colors.greenAccent, width: 3),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text("YOUR TURN",
                          style: GoogleFonts.blackOpsOne(
                              fontSize: 50, color: Colors.greenAccent)),
                    )),
                  if (showUnoBtn)
                    Positioned(
                        bottom: 260,
                        right: 20,
                        child: ScaleTransition(
                          scale: _unoPulseCtrl,
                          child: FloatingActionButton.large(
                              backgroundColor: Colors.orange,
                              onPressed: () {
                                setState(() {
                                  _unoPressed = true;
                                  showUnoBtn = false;
                                });
                                _showAlert("SAFE!", Colors.green);
                                HapticFeedback.lightImpact();
                              },
                              child: const Text("UNO!",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                        )),
                  if (_showChat)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => setState(() => _showChat = false),
                        child: Container(
                          color: Colors.black54,
                          child: GestureDetector(
                            onTap: () {},
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF2C2C3E),
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20))),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: const BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.white10))),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("CHATROOM",
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                          IconButton(
                                              onPressed: () => setState(
                                                  () => _showChat = false),
                                              icon: const Icon(Icons.close,
                                                  color: Colors.white))
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                        child: ListView.builder(
                                            controller: _chatScroll,
                                            padding: const EdgeInsets.all(15),
                                            itemCount: _chatMessages.length,
                                            itemBuilder: (c, i) {
                                              final m = _chatMessages[i];
                                              bool isMe =
                                                  m['uid'] == widget.myId;
                                              return Align(
                                                alignment: isMe
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 10),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 250),
                                                  decoration: BoxDecoration(
                                                      color: isMe
                                                          ? Colors.blue
                                                          : Colors.white10,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (!isMe)
                                                        Text(m['name']!,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontSize:
                                                                        10)),
                                                      Text(m['msg']!,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            })),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              child: TextField(
                                            controller: _chatCtrl,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                                hintText: "Type a message...",
                                                hintStyle: const TextStyle(
                                                    color: Colors.white38),
                                                filled: true,
                                                fillColor: Colors.black26,
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                    borderSide:
                                                        BorderSide.none),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20)),
                                          )),
                                          const SizedBox(width: 10),
                                          CircleAvatar(
                                              backgroundColor: Colors.blue,
                                              child: IconButton(
                                                  onPressed: _sendChat,
                                                  icon: const Icon(Icons.send,
                                                      color: Colors.white,
                                                      size: 18)))
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                      bottom: 100,
                      right: 20,
                      child: Stack(
                        children: [
                          FloatingActionButton(
                            backgroundColor: const Color(0xFF2C2C3E),
                            onPressed: () {
                              setState(() {
                                _showChat = true;
                                _hasUnread = false;
                              });
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                if (_chatScroll.hasClients)
                                  _chatScroll.jumpTo(
                                      _chatScroll.position.maxScrollExtent);
                              });
                            },
                            child: const Icon(Icons.chat_bubble,
                                color: Colors.white),
                          ),
                          if (_hasUnread)
                            Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle)))
                        ],
                      )),
                  if (_showTutorial)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _dismissTutorial,
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("DRAG TO PLAY!",
                                        style: GoogleFonts.blackOpsOne(
                                            color: Colors.white,
                                            fontSize: 32,
                                            shadows: [
                                              BoxShadow(
                                                  color: Colors.blue,
                                                  blurRadius: 20)
                                            ])),
                                    const SizedBox(height: 20),
                                    const Icon(Icons.touch_app,
                                        size: 100, color: Colors.white),
                                    const SizedBox(height: 20),
                                    Text("Tap to Start",
                                        style: TextStyle(color: Colors.white70))
                                  ],
                                ),
                              ),
                              // Hand Animation Pointer (simplified for now)
                              Positioned(
                                bottom: 150,
                                left: MediaQuery.of(context).size.width / 2,
                                child: TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 1000),
                                  builder: (context, val, child) {
                                    return Transform.translate(
                                      offset: Offset(0, -100 * val),
                                      child: Opacity(
                                          opacity: 1 - val,
                                          child: Icon(Icons.pan_tool_alt,
                                              size: 60, color: Colors.yellow)),
                                    );
                                  },
                                  onEnd: () {},
                                  curve: Curves.easeInOut,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_showWinnerOverlay)
                    Positioned.fill(
                        child: WinnerScreen(
                            w: _winnerTitle,
                            m: _winnerIsVictory,
                            isOnline: true,
                            roomId: widget.roomId,
                            myId: widget.myId,
                            myName: widget.myName,
                            isHost: widget.isHost)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
