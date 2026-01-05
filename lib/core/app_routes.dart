import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/lobby_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/shop_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String mainMenu = '/main_menu';
  static const String lobby = '/lobby';
  static const String profile = '/profile';
  static const String shop = '/shop';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        mainMenu: (context) => const MainMenuScreen(),
        lobby: (context) => const LobbyScreen(),
        profile: (context) => const UserProfileScreen(),
        shop: (context) => const ShopScreen(),
      };
}
