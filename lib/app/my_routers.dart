import 'package:flutter/material.dart';
import 'package:google_map/screens/map_screen.dart';

class MyRouters {
  static const String mapScreen = '/map_screen';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case mapScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: mapScreen),
          builder: (context) {
            return const MapScreen();
          },
        );

      default:
        return MaterialPageRoute(
            settings: RouteSettings(name: mapScreen),
            builder: (context) {
              return const MapScreen();
            });
    }
  }
}
