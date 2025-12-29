import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _navigating = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    if (_navigating) return;
    _navigating = true;

    try {
      await _player.play(AssetSource('audio/a.mp3')); // 1회 재생(시작)
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/game',
      arguments: true, // BGM 자동 시작
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: _startGame,
          child: Image.asset(
            'assets/images/fight_button.jpg',
            fit: BoxFit.contain,
            width: 534 * 0.35,
            height: 190 * 0.35,
          ),
        ),
      ),
    );
  }
}
