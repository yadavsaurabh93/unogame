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
import '../widgets/modern_button.dart';
import 'winner_screen.dart';

class PassPlayGameScreen extends StatefulWidget {
  const PassPlayGameScreen({super.key});
  @override
  State<PassPlayGameScreen> createState() => _PassPlayGameScreenState();
}

class _PassPlayGameScreenState extends State<PassPlayGameScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey();
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _discardKey = GlobalKey();

  List<UnoCard> p1Hand = [];
  List<UnoCard> p2Hand = [];
  UnoCard topCard =
      UnoCard(id: "init", color: CardColor.red, value: CardValue.zero);
  bool isP1Turn = true;
  bool showShield = false;
  bool _isProcessingAction = false;

  List<Widget> _flyingCards = [];
  List<Widget> _particles = [];
  String alertText = "";
  Color alertColor = Colors.transparent;
  double alertScale = 0.0;

  bool showUnoBtn = false;
  bool _unoPressed = false;
  Timer? _penaltyTimer;

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
        p1Hand.add(_randomCard());
        p2Hand.add(_randomCard());
      });
    }
  }

  UnoCard _randomCard({bool noWild = false}) {
    int r = Random().nextInt(100);
    return (r < 10 && !noWild)
        ? UnoCard(
            id: _uid(),
            color: CardColor.black,
            value: Random().nextBool() ? CardValue.wildFour : CardValue.wild)
        : UnoCard(
            id: _uid(),
            color: CardColor.values[Random().nextInt(4)],
            value: CardValue.values[Random().nextInt(13)]);
  }

  String _uid() => Random().nextInt(999999).toString();

  void _playCard(UnoCard c) async {
    if (showShield || _isProcessingAction) return;

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
        if (isP1Turn)
          p1Hand.remove(c);
        else
          p2Hand.remove(c);
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

            if ((isP1Turn && p1Hand.isEmpty) || (!isP1Turn && p2Hand.isEmpty)) {
              _win(isP1Turn ? "PLAYER 1 WON" : "PLAYER 2 WON", true);
              return;
            }

            List<UnoCard> currentHand = isP1Turn ? p1Hand : p2Hand;

            if (currentHand.length == 1) {
              setState(() {
                showUnoBtn = true;
                _unoPressed = false;
              });
              _showAlert("SAY UNO!", Colors.yellow);
              _penaltyTimer?.cancel();
              _penaltyTimer = Timer(const Duration(seconds: 3), () {
                if (!mounted) return;
                List<UnoCard> nowHand = isP1Turn ? p1Hand : p2Hand;
                if (!_unoPressed && nowHand.length == 1) {
                  _showAlert("CAUGHT! +2", Colors.red);
                  HapticFeedback.heavyImpact();
                  _addCards(isP1Turn, 2);
                  setState(() => showUnoBtn = false);
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
      _showAlert("NOPE", Colors.red);
    }
  }

  void _onUnoPressed() {
    if (!showUnoBtn) return;
    setState(() {
      _unoPressed = true;
      showUnoBtn = false;
    });
    _showAlert("SAFE!", Colors.green);
    HapticFeedback.lightImpact();
    _continueAfterPlay(topCard);
  }

  void _continueAfterPlay(UnoCard c) {
    if (c.value == CardValue.skip || c.value == CardValue.reverse) {
      _showAlert("PLAY AGAIN!", Colors.orange);
      setState(() => _isProcessingAction = false);
    } else if (c.value == CardValue.plusTwo) {
      _showAlert("+2 DAMAGE", Colors.red);
      _shakeKey.currentState?.shake();
      _addCards(!isP1Turn, 2);
      setState(() {
        showShield = true;
        _isProcessingAction = false;
      });
    } else if (c.value == CardValue.wildFour) {
      _showAlert("+4 NUKE", Colors.purple);
      _shakeKey.currentState?.shake();
      _addCards(!isP1Turn, 4);
      setState(() {
        showShield = true;
        _isProcessingAction = false;
      });
    } else {
      setState(() {
        showShield = true;
        _isProcessingAction = false;
      });
    }
  }

  void _draw() {
    if (showShield || _isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    DataManager.playDrawSound();
    UnoCard c = _randomCard();
    _flyCard(
        start: _getPos(_deckKey),
        end: const Offset(150, 600),
        card: c,
        flip: true,
        onComplete: () {
          setState(() {
            if (isP1Turn)
              p1Hand.add(c);
            else
              p2Hand.add(c);
          });
          setState(() {
            showShield = true;
            _isProcessingAction = false;
          });
        });
  }

  void _addCards(bool p1, int n) {
    setState(() {
      for (int i = 0; i < n; i++) {
        if (p1)
          p1Hand.add(_randomCard());
        else
          p2Hand.add(_randomCard());
      }
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
          double arc = -150 * sin(v * pi);
          return Positioned(
              left: dx,
              top: dy + arc,
              child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateZ(v * 4 * pi)
                    ..rotateY(flip ? v * pi * 3 : 0)
                    ..scale(0.5 + (0.5 * v)),
                  child: AwesomeCard(
                      card: card,
                      size: const Size(50, 75),
                      deck: DataManager.selectedDeck)));
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
    setState(() {
      alertText = t;
      alertColor = c;
      alertScale = 1.0;
    });
    Future.delayed(
        const Duration(seconds: 2), () => setState(() => alertScale = 0.0));
  }

  void _win(String w, bool isVictory) => Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => WinnerScreen(
              w: w,
              m: true,
              isOnline: false,
              roomId: null,
              myId: null,
              myName: null,
              isHost: false)));

  Offset _getPos(GlobalKey k) {
    RenderBox? b = k.currentContext?.findRenderObject() as RenderBox?;
    return b != null ? b.localToGlobal(Offset.zero) : Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    List<UnoCard> currentHand = isP1Turn ? p1Hand : p2Hand;
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
                      height: 160,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ExitButton(),
                            const Spacer(),
                            GlowAvatar(
                                name: isP1Turn ? "P1" : "P2",
                                color: isP1Turn ? Colors.red : Colors.blue,
                                count: currentHand.length),
                            const SizedBox(width: 20),
                            Text(isP1Turn ? "PLAYER 1" : "PLAYER 2",
                                style: GoogleFonts.rajdhani(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(flex: 2),
                          ]),
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
                                    key: _deckKey,
                                    child: AwesomeBack(
                                        size: const Size(120, 170),
                                        deck: DataManager.selectedDeck))),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 20),
                          Expanded(
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              clipBehavior: Clip.none,
                              scrollDirection: Axis.horizontal,
                              cacheExtent: 1000,
                              padding: const EdgeInsets.only(
                                  left: 20, right: 100, top: 40, bottom: 20),
                              itemCount: currentHand.length,
                              itemBuilder: (ctx, i) {
                                bool valid = currentHand[i].canPlayOn(topCard);
                                return Align(
                                  widthFactor: 0.7,
                                  child: GestureDetector(
                                    onTap: () => _playCard(currentHand[i]),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transform: Matrix4.identity()
                                        ..translate(0.0, valid ? -30.0 : 0.0),
                                      child: AwesomeCard(
                                          card: currentHand[i],
                                          size: const Size(90, 130),
                                          glow: valid,
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
                if (showShield)
                  Positioned.fill(
                      child: Container(
                          color: Colors.black,
                          child: Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                Text("PASS DEVICE TO",
                                    style: GoogleFonts.rajdhani(
                                        color: Colors.white54, fontSize: 20)),
                                Text(isP1Turn ? "PLAYER 2" : "PLAYER 1",
                                    style: GoogleFonts.blackOpsOne(
                                        color: Colors.white, fontSize: 50)),
                                const SizedBox(height: 30),
                                const SizedBox(height: 30),
                                ModernButton(
                                    label: "START TURN",
                                    icon: Icons.touch_app,
                                    baseColor: Colors.green,
                                    onTap: () => setState(() {
                                          showShield = false;
                                          isP1Turn = !isP1Turn;
                                          _isProcessingAction = false;
                                        }))
                              ])))),
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
                          onPressed: _onUnoPressed,
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
