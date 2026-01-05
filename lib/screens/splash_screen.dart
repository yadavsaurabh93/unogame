import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../widgets/background.dart';
import 'main_menu_screen.dart';
import 'package:uno_game/services/data_manager.dart';
import 'package:uno_game/screens/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uno_game/services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await DataManager.init();

    // Check Real Auth Status
    User? user = FirebaseAuth.instance.currentUser;

    Timer(const Duration(seconds: 3), () async {
      if (user != null) {
        // Sync DataManager from Firestore
        await FirestoreService.syncUser(user);

        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const MainMenuScreen()));
        }
      } else {
        // Not logged in
        DataManager.isGuest = true;
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AuthScreen()));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "UNO",
                style: GoogleFonts.poppins(
                  fontSize: 100,
                  color: Colors.white,
                  shadows: [const Shadow(color: Colors.blue, blurRadius: 50)],
                ),
              ),
              Text(
                "GOD PULSE",
                style: GoogleFonts.rajdhani(
                  fontSize: 25,
                  color: Colors.yellowAccent,
                  letterSpacing: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
