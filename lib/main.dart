import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_constants.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
    }
  } catch (e) {
    debugPrint("Firebase Error: $e");
  }

  // Initialize Mast Notifications
  await LocalNotificationService.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const UltimateUnoGame());
}

class UltimateUnoGame extends StatefulWidget {
  const UltimateUnoGame({super.key});

  @override
  State<UltimateUnoGame> createState() => _UltimateUnoGameState();
}

class _UltimateUnoGameState extends State<UltimateUnoGame>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FirestoreService.updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      FirestoreService.updateOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UNO GOD PULSE',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
