import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/background.dart';
import 'ai_chat_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _aniSup(
                        0,
                        "Chat with Support",
                        "Instant AI help in any language (Auto-Detect)",
                        Icons.smart_toy_outlined,
                        Colors.cyanAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AIChatScreen()))),
                    _aniSup(1, "Email Us", "Get manual support via email",
                        Icons.email_outlined, Colors.orange,
                        onTap: () => _launchEmail(
                            "support@unogame.com",
                            "Support Request",
                            "Hello Team,\n\nI need help with...")),
                    _aniSup(
                        2,
                        "Report a Player",
                        "Is someone cheating? Let us know.",
                        Icons.report_gmailerrorred_outlined,
                        Colors.redAccent,
                        onTap: () => _launchEmail(
                            "report@unogame.com",
                            "Player Report",
                            "I want to report a player.\n\nPlayer Name: \nReason: ")),
                    const SizedBox(height: 35),
                    _animatedEntrance(
                      index: 3,
                      child: Text(
                        "FREQUENTLY ASKED QUESTIONS",
                        style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _aniFaq(4, "How to get more coins?",
                        "Win online matches and complete daily challenges."),
                    _aniFaq(5, "Is there multiplayer?",
                        "Yes! Use the 'Online Play' button to play with friends."),
                    _aniFaq(6, "Can I play offline?",
                        "Yes, the 'VS Computer' mode works without internet."),
                    const SizedBox(height: 50),
                    Center(
                        child: Text("App Version 1.0.0+1",
                            style: TextStyle(
                                color: Colors.white24, fontSize: 12))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aniSup(int i, String t, String s, IconData ic, Color c,
      {VoidCallback? onTap}) {
    return _animatedEntrance(
        index: i, child: _supportCard(t, s, ic, c, onTap: onTap));
  }

  Widget _aniFaq(int i, String q, String a) {
    return _animatedEntrance(index: i, child: _faqItem(q, a));
  }

  Widget _animatedEntrance({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 120)),
      curve: Curves.easeOutQuart,
      builder: (ctx, double val, w) {
        return Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - val)),
            child: w,
          ),
        );
      },
      child: child,
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          Text("HELP & SUPPORT",
              style: GoogleFonts.blackOpsOne(
                  color: Colors.white, fontSize: 28, letterSpacing: 1.5)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _supportCard(String title, String subtitle, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3))),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white24, size: 14),
            ],
          ),
        ));
  }

  Widget _faqItem(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(q,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          iconColor: Colors.blueAccent,
          collapsedIconColor: Colors.white38,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
              child: Text(a,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String toEmail, String subject, String body) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: toEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch title');
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
