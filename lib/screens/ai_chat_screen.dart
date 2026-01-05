import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/data_manager.dart';
import '../widgets/background.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Replace with your API Key or let the user provide one.
  // For demo, we use a simulation if key is empty.
  final String _apiKey = "";

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMsg = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMsg, isMe: true));
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    // AI Logic
    String response = "";
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1200));
      response = _getSimulatedResponse(userMsg);
    } else {
      try {
        final model =
            GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
        final prompt = "You are a professional UNO Game Support Assistant. "
            "Please respond in the SAME LANGUAGE as the user's message. "
            "If they ask in Hindi, reply in Hindi. If in Gujarati, reply in Gujarati. "
            "User message: $userMsg";
        final content = [Content.text(prompt)];
        final aiResponse = await model.generateContent(content);
        response = aiResponse.text ?? "I'm sorry, I couldn't understand that.";
      } catch (e) {
        response = "System Error: Please check your connection.";
      }
    }

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: response, isMe: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _getSimulatedResponse(String input) {
    input = input.toLowerCase();

    // Language detection (Elite Multi-Lingual)
    bool isHindi = input.contains('kaise') ||
        input.contains('kya') ||
        input.contains('hai') ||
        input.contains('bhai');
    bool isGujarati = input.contains('kem') ||
        input.contains('cho') ||
        input.contains('su') ||
        input.contains('che') ||
        input.contains('maja');
    bool isMarwari = input.contains('khama') ||
        input.contains('ghani') ||
        input.contains('kai') ||
        input.contains('kani') ||
        input.contains('re');
    bool isMarathi = input.contains('kasa') ||
        input.contains('kay') ||
        input.contains('aahe') ||
        input.contains('bhava');
    bool isPunjabi = input.contains('kidda') ||
        input.contains('ki') ||
        input.contains('veere') ||
        input.contains('paji');

    // Response Map Logic
    String pName = DataManager.playerName;

    // 1. Name & Casual Greetings
    if (input.contains('tera naam') ||
        input.contains('your name') ||
        input.contains('tamarun naam') ||
        input.contains('tharo naam')) {
      if (isMarwari)
        return "Sa, mharo naam toh UNO AI Support hai, par main thane $pName re naam su jaanu hu!";
      if (isMarathi)
        return "Majha naav UNO AI Support aahe bhava, ani me tula $pName mhanun olakhto!";
      if (isPunjabi)
        return "Mera naam UNO AI Support hai veere, te main tainu $pName de naam naal janda haan!";
      if (isGujarati)
        return "Maru naam UNO AI Support che, ane hu tamne $pName tarike olkhu chu!";
      if (isHindi)
        return "Mera naam UNO AI Support hai, aur main jaanta hu ki aap $pName ho!";
      return "My name is UNO AI Support, and I know you are $pName!";
    }

    if (input.contains('kaise ho') ||
        input.contains('kasa aahe') ||
        input.contains('kem cho') ||
        input.contains('how are you') ||
        input.contains('ki haal') ||
        input.contains('kai haal')) {
      if (isMarwari)
        return "Main ekdam maze mein hu Sa! The batao $pName, thare kai haal chaal hai?";
      if (isMarathi)
        return "Me ekdam majaait aahe! Tu kasa aahes $pName? Game madhe kai madat pahije?";
      if (isPunjabi)
        return "Main vadiya haan paji! Tusi daso $pName, ki haal chaal ne?";
      if (isGujarati)
        return "Hu ekdam maja ma chu! Tame kem cho $pName? Game ma kai help joie che?";
      if (isHindi) return "Main ekdam badhiya hu bhai! Aap kaise ho $pName?";
      return "I am doing great! How are you doing today, $pName?";
    }

    if (input.contains('kya chal') ||
        input.contains('kay challay') ||
        input.contains('su chale') ||
        input.contains('kai chale') ||
        input.contains('what is going on')) {
      if (isMarwari)
        return "Kai koni Sa, bas thari sahayta karba ne taiyar hu! UNO khelba ko man hai kai?";
      if (isMarathi)
        return "Kai nahi bhava, bas tula madat kartoy. UNO khelaycha ka?";
      if (isPunjabi)
        return "Kujh khaas nahi veere, tuhadi seva vich hazir haan! UNO khedni hai fer?";
      if (isGujarati)
        return "Kai nahi, bas tamari help karva bettho chu. UNO khelvu che?";
      if (isHindi)
        return "Kuch nahi bhai, bas aapki help karne ke liye taiyar hu. UNO khelna hai?";
      return "Nothing much, just here to help you! Want to play some UNO?";
    }

    if (input.contains('+2') || input.contains('draw 2')) {
      if (isMarwari)
        return "Sa, +2 card ramva su agla bande ne 2 card uthana padsi aur binu palo skip ho jasi.";
      if (isMarathi)
        return "Bhava, +2 card khellavar pudhchya player la 2 cards ghyave laptil ani tyacha turn skip hoil.";
      if (isPunjabi)
        return "Veere, +2 card nall agle bande nu 2 card chakkne painage te ohdi turn skip ho jayegi.";
      if (isGujarati)
        return "Tame jyare +2 card ramo cho, tyare agal na khiladi ne 2 cards leva pade che ane teno varo skip thai jay che.";
      if (isHindi)
        return "Bhai, jab aap +2 card chalte ho, toh agle player ko 2 cards uthane padte hain aur uski turn skip ho jati hai.";
      return "When you play a +2 card, the next player must draw 2 cards and their turn is skipped.";
    }

    if (input.contains('+4') || input.contains('draw 4')) {
      if (isMarwari)
        return "+4 ghano tagdo card hai! Isu rang badal sako ho aur agla ne 4 card uthana padsi.";
      if (isMarathi)
        return "+4 khupach powerful card aahe! Tyane tumhi color badlu shakta ani pudhchya player la 4 cards ghyave laktat.";
      if (isPunjabi)
        return "+4 bahut powerful card hai! Is naal tusi color badal sakde ho te agle bande nu 4 card chakkne painage.";
      if (isGujarati)
        return "+4 sauthi powerful card che! Aa ramva thi tame color badli sako cho ane agal na khiladi ne 4 cards leva pade che.";
      if (isHindi)
        return "+4 sabse powerful card hai! Isse aap color badal sakte ho aur agle player ko 4 cards pick karne padte hain.";
      return "The +4 Wild card is the most powerful! You can change the color, and the next player must draw 4 cards.";
    }

    if (input.contains('wild') || input.contains('color')) {
      if (isMarwari)
        return "Wild card su the thari pasand ko rang (Lal, Peelo, Haro) chun sako ho.";
      if (isMarathi)
        return "Wild card ne tumhi tumchya aavadicha color nivdu shakta.";
      if (isPunjabi)
        return "Wild card naal tusi apni pasand da rang chun sakde ho.";
      if (isGujarati)
        return "Wild card thi tame tamari pasand no color (Lal, Vadli, Lilo, ya Pilo) pasand kari sako cho.";
      if (isHindi)
        return "Wild card se aap apni pasand ka color (Red, Blue, Green, ya Yellow) chun sakte ho.";
      return "Wild cards allow you to change the current color to Red, Blue, Green, or Yellow.";
    }

    if (input.contains('coin') ||
        input.contains('paisa') ||
        input.contains('gold')) {
      if (isMarwari)
        return "The online match jeet'r ya Daily Spin su ghana saara coins kama sako ho.";
      if (isMarathi)
        return "Tumhi online matches jinkun kinva Daily Spin vaprun coins kamao shakta.";
      if (isPunjabi)
        return "Tusi online matches jitt ke ya Daily Spin naal coins kama sakde ho.";
      if (isGujarati)
        return "Tame online matches jiti ne ya 'Daily Spin' mathi coins kamai sako cho.";
      if (isHindi)
        return "Aap online matches jeet kar ya 'Daily Spin' use karke coins kama sakte ho.";
      return "You can earn coins by winning online matches or using the 'Daily Spin'.";
    }

    if (input.contains('hello') ||
        input.contains('hi') ||
        input.contains('hey') ||
        input.contains('namaste') ||
        input.contains('khama') ||
        input.contains('ghani') ||
        input.contains('cho')) {
      if (isMarwari || input.contains('khama'))
        return "Khama Ghani Sa! Hukum, batao main thari kai sahayta kar saku?";
      if (isMarathi)
        return "Namshkar bhava! Me tula UNO game madhe kashi madat karu shakto?";
      if (isPunjabi)
        return "Sat Sri Akal veere! Ki haal chaal? Main tuhadi kive madat kar sakda haan?";
      if (isGujarati || input.contains('cho'))
        return "Namaste! Kem cho? Hu tamari UNO game ma kai rite help kari saku?";
      if (isHindi)
        return "Namaste bhai! Kaise help kar sakta hu aapki UNO game mein?";
      return "Hello! I am your High-Level Multi-Lingual Assistant. How can I help you today?";
    }

    // Default responses
    if (isMarwari)
      return "Main thari UNO game mein sahayta kar saku hu. The niyam, cards ya coins re baare mein puch sako ho.";
    if (isMarathi)
      return "Mi tumhala UNO game madhe madat karu shakto. Tumhi niyam, cards kinva coins baddal vicharu shakta.";
    if (isPunjabi)
      return "Main tuhadi UNO game vich madad kar sakda haan. Tusi rules, cards ya coins bare puch sakde ho.";
    if (isGujarati)
      return "Hu tamari UNO game ma help kari saku chu. Tame niyam, cards (+2, +4), level ya coins vishe puchi sako cho.";
    if (isHindi)
      return "Main aapki UNO game mein help kar sakta hu. Aap rules, cards (+2, +4), level ya coins ke baare mein puch sakte ho.";
    return "I am your High-Level UNO Assistant. You can ask me about rules, special cards, or coins in many Indian languages!";
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI SUPPORT",
                style:
                    GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 20)),
            Text("Always Online • Auto-Language",
                style: GoogleFonts.poppins(
                    color: Colors.cyanAccent, fontSize: 10)),
          ],
        ),
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _chatBubble(msg);
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                ),
              _inputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatBubble(ChatMessage msg) {
    bool isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.cyanAccent,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.black87),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])
                    : LinearGradient(colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05)
                      ]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
                boxShadow: [
                  if (isMe)
                    BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isMe ? FontWeight.w500 : FontWeight.w400),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe)
            const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 14, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black26,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ask anything...",
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Colors.cyanAccent, Colors.blueAccent]),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  ChatMessage({required this.text, required this.isMe});
}
