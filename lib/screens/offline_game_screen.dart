import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/uno_card.dart';
import '../services/data_manager.dart';
import '../utils/particles.dart';
import '../utils/shake_widget.dart';
import '../widgets/awesome_card.dart';
import '../widgets/background.dart';
import '../widgets/color_picker.dart';
import '../widgets/exit_button.dart';
import '../widgets/glow_avatar.dart';
import 'winner_screen.dart';

class OfflineGameScreen extends StatefulWidget {
  final BotDifficulty difficulty;
  const OfflineGameScreen({super.key, this.difficulty = BotDifficulty.medium});
  @override
  State<OfflineGameScreen> createState() => _OfflineGameScreenState();
}

class _OfflineGameScreenState extends State<OfflineGameScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey();
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _discardKey = GlobalKey();

  List<UnoCard> myHand = [];
  List<UnoCard> botHand = [];
  UnoCard topCard =
      UnoCard(id: "init", color: CardColor.red, value: CardValue.zero);
  bool isMyTurn = true;
  bool isDealing = true;
  bool _isProcessingAction = false;

  List<Widget> _flyingCards = [];
  List<Widget> _particles = [];
  String alertText = "";
  Color alertColor = Colors.transparent;
  double alertScale = 0.0;

  bool showUnoBtn = false;
  bool _unoPressed = false;
  Timer? _penaltyTimer;
  String? currentTurnName;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _penaltyTimer?.cancel();
    super.dispose();
  }

  void _initGame() async {
    topCard = _randomCard(noWild: true);
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < 7; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        myHand.add(_randomCard());
        botHand.add(_randomCard());
      });
      DataManager.vibrate();
    }
    setState(() {
      myHand.sort();
      isDealing = false;
      currentTurnName = "YOUR TURN";
    });
  }

  void _botTurn() async {
    if (botHand.isEmpty) {
      _win("DEFEAT", false);
      return;
    }
    setState(() => _isProcessingAction = true);

    // DIFFICULTY DELAY
    int delay = 2000;
    if (DataManager.fastMode)
      delay = 500;
    else if (widget.difficulty == BotDifficulty.hard)
      delay = 1000;
    else if (widget.difficulty == BotDifficulty.easy) delay = 3000;

    await Future.delayed(Duration(milliseconds: delay));
    if (!mounted) return;

    UnoCard? c;

    // DIFFICULTY LOGIC
    if (widget.difficulty == BotDifficulty.easy) {
      if (Random().nextDouble() < 0.3) {
        c = null;
      } else {
        try {
          c = botHand.firstWhere((x) => x.canPlayOn(topCard));
        } catch (e) {
          c = null;
        }
      }
    } else if (widget.difficulty == BotDifficulty.hard) {
      try {
        c = botHand.firstWhere(
            (x) =>
                x.canPlayOn(topCard) &&
                (x.value == CardValue.plusTwo ||
                    x.value == CardValue.wildFour ||
                    x.value == CardValue.skip),
            orElse: () => botHand.firstWhere((x) => x.canPlayOn(topCard)));
      } catch (e) {
        c = null;
      }
    } else {
      try {
        c = botHand.firstWhere((x) => x.canPlayOn(topCard));
      } catch (e) {
        c = null;
      }
    }

    if (c != null) {
      final cardToPlay = c;
      if (cardToPlay.isWild) {
        if (widget.difficulty == BotDifficulty.hard) {
          int r = 0, b = 0, g = 0, y = 0;
          for (var x in botHand) {
            if (x.color == CardColor.red)
              r++;
            else if (x.color == CardColor.blue)
              b++;
            else if (x.color == CardColor.green)
              g++;
            else if (x.color == CardColor.yellow) y++;
          }
          if (r >= b && r >= g && r >= y)
            cardToPlay.color = CardColor.red;
          else if (b >= r && b >= g && b >= y)
            cardToPlay.color = CardColor.blue;
          else if (g >= r && g >= b && g >= y)
            cardToPlay.color = CardColor.green;
          else
            cardToPlay.color = CardColor.yellow;
        } else {
          cardToPlay.color = CardColor.values[Random().nextInt(4)];
        }
      }

      setState(() => botHand.remove(cardToPlay));

      _flyCard(
          start: const Offset(200, -50),
          end: _getPos(_discardKey),
          card: cardToPlay,
          onComplete: () {
            setState(() {
              topCard = cardToPlay;
            });
            if (botHand.isEmpty) {
              _win("DEFEAT", false);
              return;
            }

            if (cardToPlay.value == CardValue.plusTwo) {
              _showAlert("TAKE +2!", Colors.red);
              _shakeKey.currentState?.shake();
              _addCards(true, 2);
              setState(() {
                isMyTurn = true;
                _isProcessingAction = false;
                currentTurnName = "YOUR TURN";
              });
            } else if (cardToPlay.value == CardValue.wildFour) {
              _showAlert("TAKE +4!", Colors.purple);
              _shakeKey.currentState?.shake();
              _addCards(true, 4);
              setState(() {
                isMyTurn = true;
                _isProcessingAction = false;
                currentTurnName = "YOUR TURN";
              });
            } else if (cardToPlay.value == CardValue.skip ||
                cardToPlay.value == CardValue.reverse) {
              _showAlert("BOT AGAIN!", Colors.orange);
              setState(() => _isProcessingAction = false);
              _botTurn();
            } else {
              setState(() {
                isMyTurn = true;
                _isProcessingAction = false;
                currentTurnName = "YOUR TURN";
              });
            }
          });
    } else {
      setState(() {
        botHand.add(_randomCard());
        _showAlert("BOT DRAW", Colors.grey);
        isMyTurn = true;
        _isProcessingAction = false;
        currentTurnName = "YOUR TURN";
      });
    }
  }

  UnoCard _randomCard({bool noWild = false}) {
    int r = Random().nextInt(100);
    return (r < 10 && !noWild)
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
    if (!isMyTurn || isDealing || _isProcessingAction) return;

    if (c.canPlayOn(topCard)) {
      DataManager.playCardSound();
      setState(() => _isProcessingAction = true);
      if (c.isWild) {
        CardColor? col = await showDialog(
            context: context, builder: (_) => const ColorPicker());
        if (col == null) {
          setState(() => _isProcessingAction = false);
          return;
        }
        c.color = col;
      }

      setState(() {
        myHand.remove(c);
      });

      _spawnParticles(_getPos(_discardKey), c.colorHex);

      _flyCard(
          start: const Offset(150, 600),
          end: _getPos(_discardKey),
          card: c,
          onComplete: () {
            setState(() {
              topCard = c;
            });
            HapticFeedback.mediumImpact();

            if (myHand.isEmpty) {
              _win("VICTORY", true);
              return;
            }

            if (myHand.length == 1) {
              setState(() {
                showUnoBtn = true;
                _unoPressed = false;
              });
              _showAlert("SAY UNO!", Colors.yellow);
              _penaltyTimer?.cancel();
              _penaltyTimer = Timer(const Duration(seconds: 3), () {
                if (!mounted) return;
                if (!_unoPressed && myHand.length == 1) {
                  _showAlert("CAUGHT! +2", Colors.red);
                  _shakeKey.currentState?.shake();
                  HapticFeedback.heavyImpact();
                  setState(() {
                    myHand.add(_randomCard());
                    myHand.add(_randomCard());
                    showUnoBtn = false;
                  });
                  myHand.sort();
                  _continueAfterPlay(c);
                } else {
                  setState(() => showUnoBtn = false);
                  _continueAfterPlay(c);
                }
              });
              return;
            }

            _continueAfterPlay(c);
          });
    } else {
      _showAlert("CAN'T PLAY", Colors.red);
    }
  }

  void _continueAfterPlay(UnoCard c) {
    if (c.value == CardValue.skip || c.value == CardValue.reverse) {
      _showAlert("PLAY AGAIN", Colors.orange);
      setState(() => _isProcessingAction = false);
    } else if (c.value == CardValue.plusTwo) {
      _showAlert("+2 TO BOT", Colors.red);
      _shakeKey.currentState?.shake();
      _addCards(false, 2);
      setState(() {
        showUnoBtn = false;
        _isProcessingAction = false;
        isMyTurn = false;
        currentTurnName = "BOT TURN";
      });
      _botTurn();
    } else if (c.value == CardValue.wildFour) {
      _showAlert("+4 TO BOT", Colors.purple);
      _shakeKey.currentState?.shake();
      _addCards(false, 4);
      setState(() {
        showUnoBtn = false;
        _isProcessingAction = false;
        isMyTurn = false;
        currentTurnName = "BOT TURN";
      });
      _botTurn();
    } else {
      setState(() {
        showUnoBtn = false;
        _isProcessingAction = false;
        isMyTurn = false;
        currentTurnName = "BOT TURN";
      });
      _botTurn();
    }
  }

  void _addCards(bool me, int n) {
    setState(() {
      for (int i = 0; i < n; i++) {
        if (me)
          myHand.add(_randomCard());
        else
          botHand.add(_randomCard());
      }
      if (me) myHand.sort();
    });
  }

  void _draw() {
    if (!isMyTurn || _isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    UnoCard c = _randomCard();
    DataManager.playDrawSound();
    _flyCard(
        start: _getPos(_deckKey),
        end: const Offset(150, 600),
        card: c,
        flip: true,
        onComplete: () {
          setState(() {
            myHand.add(c);
            myHand.sort();
            isMyTurn = false;
            _isProcessingAction = false;
            currentTurnName = "BOT TURN";
          });
          _botTurn();
        });
  }

  void _flyCard(
      {required Offset start,
      required Offset end,
      required UnoCard card,
      required VoidCallback onComplete,
      bool flip = false}) {
    final k = UniqueKey();
    setState(() => _flyingCards.add(TweenAnimationBuilder(
        key: k,
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
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
                ..rotateY(flip ? v * pi * 3 : 0)
                ..scale(0.5 + (0.5 * v)),
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
    if (isVictory) {
      DataManager.wins++;
    } else {
      DataManager.losses++;
    }
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => WinnerScreen(
                w: w,
                m: isVictory,
                isOnline: false,
                roomId: null,
                myId: null,
                myName: null,
                isHost: false)));
  }

  Offset _getPos(GlobalKey k) {
    RenderBox? b = k.currentContext?.findRenderObject() as RenderBox?;
    return b != null ? b.localToGlobal(Offset.zero) : Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ShakeWidget(
        key: _shakeKey,
        child: ModernBackground(
          child: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ExitButton(),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GlowAvatar(
                                    name: "SKYNET BOT",
                                    color: Colors.red,
                                    count: botHand.length),
                                const SizedBox(height: 5),
                                SizedBox(
                                    height: 50,
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                            min(6, botHand.length),
                                            (i) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                child: const AwesomeBack(
                                                    size: Size(30, 45))))))
                              ],
                            ),
                          ),
                          const SizedBox(width: 50),
                        ],
                      ),
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
                                    deck: DataManager.selectedDeck)),
                            const SizedBox(width: 30),
                            GestureDetector(
                                onTap: _draw,
                                child: Container(
                                    child: AwesomeBack(
                                        size: const Size(120, 170),
                                        deck: DataManager.selectedDeck))),
                          ],
                        ),
                      ),
                    ),
                    if (currentTurnName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          currentTurnName!,
                          style: GoogleFonts.blackOpsOne(
                              color: isMyTurn
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 32,
                              shadows: [
                                BoxShadow(
                                    color: isMyTurn ? Colors.green : Colors.red,
                                    blurRadius: 20)
                              ]),
                        ),
                      ),
                    SizedBox(
                      height: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 10),
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
                                  child: GestureDetector(
                                    onTap: () => _playCard(myHand[i]),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transform: Matrix4.identity()
                                        ..translate(0.0,
                                            (valid && isMyTurn) ? -30.0 : 0.0),
                                      child: AwesomeCard(
                                          card: myHand[i],
                                          size: const Size(90, 130),
                                          glow: valid && isMyTurn,
                                          deck: DataManager.selectedDeck),
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
                                border: Border.all(color: alertColor, width: 4),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(alertText,
                                style: GoogleFonts.blackOpsOne(
                                    fontSize: 40, color: Colors.white))))),
                if (showUnoBtn)
                  Positioned(
                      bottom: 260,
                      right: 20,
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
                                  color: Colors.white)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
