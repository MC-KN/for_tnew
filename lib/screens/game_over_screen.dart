import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  const GameOverScreen({super.key, required this.score});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _restarting = false;

  @override
  void initState() {
    super.initState();
    _playLoop();
  }

  Future<void> _playLoop() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/game_over.mp3'));
    } catch (_) {}
  }

  Future<void> _restart() async {
    if (_restarting) return;
    _restarting = true;

    try {
      await _player.stop(); // 게임오버 음악 정지
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/game'); // 즉시 재시작
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Transform.translate(
          offset: const Offset(0, -40), // “중앙에서 약간 위쪽”
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/game_over.png',
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'SCORE: ${widget.score}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Comic Sans',
                ),
              ),
              const SizedBox(height: 18),

              // 다시 시작 버튼(점수 아래)
              GestureDetector(
                onTap: _restart,
                child: Image.asset(
                  'assets/images/fight_button.jpg',
                  width: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
