import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:sans/game/apple_game.dart';
import 'package:flutter/material.dart';
import 'package:sans/screens/start_screen.dart';
import 'package:sans/screens/game_screen.dart';
import 'package:sans/screens/game_over_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '샌즈 사과 게임',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const StartScreen());
          case '/game':
            return MaterialPageRoute(builder: (_) => const GameScreen());
          case '/gameover':
            final score = (settings.arguments as int?) ?? 0;
            return MaterialPageRoute(builder: (_) => GameOverScreen(score: score));
          default:
            return MaterialPageRoute(builder: (_) => const StartScreen());
        }
      },
      initialRoute: '/',
    );
  }
}
