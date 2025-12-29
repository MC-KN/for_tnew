import 'dart:async'; // Timer 때문에 반드시 필요
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sans/game/apple_game.dart';
import 'package:audioplayers/audioplayers.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SansAppleGame _game;

  bool _endingSequenceStarted = false;
  bool _showOverGif = false;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  Timer? _megaTimer; // 1초 뒤 MEGALOVANIA 재생 예약
  final AudioPlayer _musicPlayer = AudioPlayer(); // MEGALOVANIA 전용(권장)


  Timer? _goGameOverTimer; // 전환 예약(1회)
  Timer? _swapGifTimer; // GIF 변경 예약(1회)

  // GIF 박스 크기(이 값이 apple_game의 overlayGifHeight로 들어감)
  double _gifBox = 300.0;

  // StartScreen에서 전달된 BGM 자동 시작
  bool _bgmAutoStartChecked = false;

  @override
  void initState() {
    super.initState();
    _game = SansAppleGame();

    // game_over.png 프리캐시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage('assets/images/game_over.png'), context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_bgmAutoStartChecked) return;
    _bgmAutoStartChecked = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final bool autoStartBgm = args is bool ? args : false;

    if (autoStartBgm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _game.startBackgroundMusic();
      });
    }
  }

  @override
  void dispose() {
    _goGameOverTimer?.cancel();
    _swapGifTimer?.cancel();
    _sfxPlayer.dispose();
    _game.onDispose();
    _megaTimer?.cancel();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    super.dispose();
  }

  void _scheduleGifBoxUpdate(double newBox) {
    if ((newBox - _gifBox).abs() < 0.5) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _gifBox = newBox);

      // apple_game.dart에 setOverlayGifHeight(double) 메서드가 있어야 합니다.
      _game.setOverlayGifHeight(newBox);
    });
  }

  void _startEndingSequenceOnce() {
    if (_endingSequenceStarted) return;
    _endingSequenceStarted = true;

    _swapGifTimer?.cancel();
    _megaTimer?.cancel();
    _goGameOverTimer?.cancel();

    // 0.5초 뒤: GIF 변경 + over.mp3 1회 재생
    _swapGifTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      setState(() => _showOverGif = true);

      try {
        await _sfxPlayer.play(AssetSource('audio/over.mp3'));
      } catch (_) {}
    });

    // 1초 뒤: MEGALOVANIA.mp3 재생
    _megaTimer = Timer(const Duration(seconds: 1), () async {
      if (!mounted) return;

      try {
        // 필요하면 반복 여부 설정 (원하시면 loop로 바꿀 수 있습니다)
        await _musicPlayer.setReleaseMode(ReleaseMode.stop);
        await _musicPlayer.setVolume(0.9);
        await _musicPlayer.play(AssetSource('audio/MEGALOVANIA.mp3'));
      } catch (_) {}
    });

    // 2초 뒤: 게임오버 화면으로 전환
    _goGameOverTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      _musicPlayer.stop(); // 전환 직전 MEGALOVANIA 정지
      

      Navigator.of(context).pushReplacementNamed(
        '/gameover',
        arguments: _game.score,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 이전 하드코딩(대략 300)과 유사: 큰 화면은 300, 작은 화면은 축소
          final double desiredBox =
              (constraints.maxWidth * 0.85).clamp(250.0, 300.0);

          // build 중 setState 방지: postFrame에서 갱신
          _scheduleGifBoxUpdate(desiredBox);

          // 초기 프레임에서도 레이아웃이 빠르게 잡히도록 현재 값 주입
          // (setOverlayGifHeight 내부에서 변화가 거의 없으면 무시되도록 구현되어 있어야 가장 안정적입니다.)
          _game.setOverlayGifHeight(_gifBox);

          return Stack(
            children: [
              GameWidget(game: _game),

              ValueListenableBuilder<double>(
                valueListenable: _game.imageYNotifier,
                builder: (context, imageY, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _game.gameOverNotifier,
                    builder: (context, isGameOver, __) {
                      if (isGameOver) {
                        _startEndingSequenceOnce();
                      }

                      return Positioned(
                        top: imageY,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SizedBox(
                            width: _gifBox,
                            height: _gifBox,
                            child: Image.asset(
                              _showOverGif
                                  ? 'assets/images/sans-over.gif'
                                  : 'assets/images/sans-stand.gif',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
