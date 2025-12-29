import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:sans/components/number_cell.dart';
import 'package:sans/components/score_display.dart';

class SansAppleGame extends FlameGame with PanDetector {
  // --- 상태 관리 및 알림 ---
  final ValueNotifier<bool> gameOverNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> imageYNotifier = ValueNotifier<double>(0.0);

  // 전체 제한 시간(초)
  final double gameTimerPeriod = 120.0;

  // UI에 시간을 전달할 스트림
  final StreamController<double> _timerController =
      StreamController<double>.broadcast();
  Stream<double> get timerStream => _timerController.stream;

  Timer? _timer;

  // --- 오디오 플레이어 ---
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  bool _backgroundMusicStarted = false;

  // --- 게임 설정 ---
  int score = 0;

  // 레이아웃/그리드 관련
  double cellSize = 0.0;
  double gridOffsetX = 0.0;
  double totalGameAreaWidth = 0.0;
  double totalGameAreaHeight = 0.0;
  double gridStartY = 0.0;

  final int rows = 10;
  final int cols = 17;

  Rect? selectionRect;

  // 점수판 (onLoad 이후 생성)
  ScoreDisplayComponent? scoreDisplay;

  // 타이머
  double _remainingTime = 0.0;

  // --- 이미지(Flutter Overlay) 크기 기반 레이아웃 ---
  double _overlayGifHeight = 200.0; // Flutter Overlay에서 측정된 GIF 실제 높이
  double _timerTopY = 0.0; // 타이머 바의 top Y

  // 레이아웃 상수
  // static const double _gridScaleFactor = 0.95; // 게임 영역 가로 폭 비율
  // static const double _cellScaleFactor = 0.8; // 셀 크기 보정 비율
  static const double _boardWidthRatio = 0.50; // 전체화면(16:9) 기준 목표: 화면 폭의 50%
  static const double _fallbackBoardWidthRatio = 0.80; // 너무 작은 화면에서의 안전장치(비율)

  static const double _cellSpacing = 4.0;
  static const double _borderPadding = 10.0;

  static const double _gapImageToTimer = 20.0;
  static const double _timerBarHeight = 15.0;
  static const double _gapTimerToGrid = 40.0;

  /// Flutter Overlay(GIF)에서 실제 렌더링 높이를 전달받아 레이아웃 갱신
  void setOverlayGifHeight(double height) {
    if (height <= 0) return;
    if ((height - _overlayGifHeight).abs() < 0.5) return; // 잦은 갱신 방지
    _overlayGifHeight = height;
    _updatePositions();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _remainingTime = gameTimerPeriod;

    // --- 셀 및 그리드 크기 계산 ---
    // final double availableWidth = size.x * _gridScaleFactor;
    double desiredBoardWidth = size.x * _boardWidthRatio;
    double rawCellSize = (desiredBoardWidth -
        (2 * _borderPadding) -
        (cols - 1) * _cellSpacing) /
    cols;

    // 화면이 너무 작아 rawCellSize가 비정상(<=0)일 경우 비율만 키워서 안전하게 처리
    if (rawCellSize <= 0) {
      desiredBoardWidth = size.x * _fallbackBoardWidthRatio;
      rawCellSize = (desiredBoardWidth -
              (2 * _borderPadding) -
              (cols - 1) * _cellSpacing) /
          cols;
    }

    // 최종 cellSize
    cellSize = rawCellSize;

    // cellSize = (availableWidth -
    //         (2 * _borderPadding) -
    //         (cols - 1) * _cellSpacing) /
    //     cols *
    //     _cellScaleFactor;

    totalGameAreaWidth = (cols * cellSize) +
        ((cols - 1) * _cellSpacing) +
        (2 * _borderPadding);

    totalGameAreaHeight = (rows * cellSize) +
        ((rows - 1) * _cellSpacing) +
        (2 * _borderPadding);

    // 숫자 셀 추가: 최초 위치는 임시(0,0)로 두고,
    // overlay gif 높이가 들어오면 _updatePositions()에서 정렬됩니다.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        add(NumberCell(
          number: Random().nextInt(9) + 1,
          cellSize: cellSize,
          gridPos: Vector2(j.toDouble(), i.toDouble()),
          position: Vector2.zero(),
        ));
      }
    }

    // 점수판
    scoreDisplay = ScoreDisplayComponent(
      position: Vector2(0, 0),
      score: score,
    );
    add(scoreDisplay!);

    _startTimer();

    // 오디오 설정
    await _effectPlayer.setVolume(1.0);

    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundMusicPlayer.setVolume(0.8);

    // overlay gif height가 아직 안 들어온 상태면,
    // 첫 프레임에서는 위치 계산이 보류되고, GameScreen에서 height 전달되면 자동 정렬됩니다.
    _updatePositions();
  }

  // 사용자 상호작용 후 배경 음악 재생 (웹 자동 재생 정책 대응)
  Future<void> startBackgroundMusic() async {
    if (gameOverNotifier.value) return;
    if (_backgroundMusicStarted) return;

    _backgroundMusicStarted = true;
    try {
      await _backgroundMusicPlayer.play(AssetSource('audio/Sans_theme.mp3'));
    } catch (_) {
      _backgroundMusicStarted = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (gameOverNotifier.value) return;

      if (_remainingTime > 0) {
        _remainingTime -= 0.1;
        _timerController.add(_remainingTime);
      } else {
        _onGameOver();
      }
    });
  }

  void _onGameOver() async {
    _timer?.cancel();

    try {
      await _backgroundMusicPlayer.stop(); // 배경 음악 정지
    } catch (_) {}

    _backgroundMusicStarted = false; // 재시작 시 다시 재생 가능하도록 초기화
    gameOverNotifier.value = true;
  }

  // 합이 10인지 체크하고 제거 + 점수 갱신
  Future<void> _checkSumAndClear() async {
    if (gameOverNotifier.value) return;

    final selectedCells = children
        .whereType<NumberCell>()
        .where((c) => c.isSelected)
        .toList();
    if (selectedCells.isEmpty) return;

    final int sum =
        selectedCells.fold(0, (prev, element) => prev + element.number);

    if (sum == 10) {
      // (선택) 첫 상호작용 시 배경음이 아직 시작 안 됐다면 시작
      if (!_backgroundMusicStarted) {
        await startBackgroundMusic();
      }

      // 숫자 제거 효과음
      await _effectPlayer.play(AssetSource('audio/voice.mp3'));

      for (final cell in selectedCells) {
        cell.removeFromParent();
      }

      score += selectedCells.length;
      scoreDisplay?.updateScore(score);
    } else {
      for (final cell in selectedCells) {
        cell.isSelected = false;
      }
    }
  }

  // --- 드래그 이벤트 로직 ---
  @override
  void onPanStart(DragStartInfo info) {
    if (gameOverNotifier.value) return;

    // 사용자 상호작용 시 배경 음악 시작
    startBackgroundMusic();

    selectionRect = Rect.fromLTWH(
      info.eventPosition.global.x,
      info.eventPosition.global.y,
      0,
      0,
    );
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameOverNotifier.value) return;
    if (selectionRect == null) return;

    selectionRect = Rect.fromPoints(
      selectionRect!.topLeft,
      Offset(info.eventPosition.global.x, info.eventPosition.global.y),
    );
    _updateSelection();
  }

  @override
  void onPanEnd(DragEndInfo info) async {
    if (gameOverNotifier.value) return;

    await _checkSumAndClear();
    selectionRect = null;
  }

  void _updateSelection() {
    if (gameOverNotifier.value) return;
    if (selectionRect == null) return;

    for (final child in children.whereType<NumberCell>()) {
      final Rect globalCellRect = Rect.fromLTWH(
        child.absolutePosition.x,
        child.absolutePosition.y,
        child.size.x,
        child.size.y,
      );
      child.isSelected = selectionRect!.overlaps(globalCellRect);
    }
  }

  // 반응형 위치 업데이트 메서드
  void _updatePositions() {
    if (cellSize <= 0 || totalGameAreaWidth <= 0 || totalGameAreaHeight <= 0) {
      return;
    }

    // GIF 높이를 아직 못 받았으면, 이미지/타이머/그리드 세로 배치는 보류
    if (_overlayGifHeight <= 0) {
      // 가로 중앙 정렬만이라도 유지
      gridOffsetX = (size.x - totalGameAreaWidth) / 2;
      return;
    }

    // 가로 중앙
    gridOffsetX = (size.x - totalGameAreaWidth) / 2;

    // 전체 레이아웃(이미지 + 타이머 + 그리드)을 화면 중앙에 배치
    final double totalLayoutHeight = _overlayGifHeight +
        _gapImageToTimer +
        _timerBarHeight +
        _gapTimerToGrid +
        totalGameAreaHeight;

    final double startY = (size.y - totalLayoutHeight) / 2;

    final double imageStartY = startY < 0 ? 0.0 : startY;
    imageYNotifier.value = imageStartY;

    _timerTopY = imageStartY + _overlayGifHeight + _gapImageToTimer;
    gridStartY = _timerTopY + _timerBarHeight + _gapTimerToGrid;

    // NumberCell 위치 업데이트
    final double numberCellStartX = gridOffsetX + _borderPadding;
    final double numberCellStartY = gridStartY + _borderPadding;

    for (final child in children.whereType<NumberCell>()) {
      final gridPos = child.gridPos;
      child.position = Vector2(
        numberCellStartX + gridPos.x * (cellSize + _cellSpacing),
        numberCellStartY + gridPos.y * (cellSize + _cellSpacing),
      );
    }

    // 점수판 위치 업데이트
    final sd = scoreDisplay;
    if (sd != null && sd.isMounted) {
      const rightMargin = 12.0;
      const aboveTimerMargin = 10.0;

      sd.position = Vector2(
        gridOffsetX + totalGameAreaWidth - sd.size.x - rightMargin,
        _timerTopY - sd.size.y - aboveTimerMargin,
      );
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updatePositions();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // overlay gif 높이가 없으면(아직 측정 전) 그리드/타이머 렌더를 보류
    if (_overlayGifHeight <= 0) return;

    if (cellSize <= 0 || totalGameAreaWidth <= 0 || totalGameAreaHeight <= 0) {
      return;
    }

    _updatePositions();

    // 게임 영역 테두리
    final borderRect =
        Rect.fromLTWH(gridOffsetX, gridStartY, totalGameAreaWidth, totalGameAreaHeight);

    final gameBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    canvas.drawRect(borderRect, gameBorderPaint);

    // 타이머 렌더링
    final double timerWidth = totalGameAreaWidth;
    final double timerHeight = _timerBarHeight;
    final double timerY = _timerTopY;

    canvas.drawRect(
      Rect.fromLTWH(gridOffsetX, timerY, timerWidth, timerHeight),
      Paint()..color = Colors.grey.withOpacity(0.5),
    );

    final double progress =
        (_remainingTime <= 0) ? 0 : (_remainingTime / gameTimerPeriod);

    canvas.drawRect(
      Rect.fromLTWH(gridOffsetX, timerY, timerWidth * progress, timerHeight),
      Paint()..color = Colors.red,
    );

    // 드래그 박스
    if (selectionRect != null && !gameOverNotifier.value) {
      final paint = Paint()
        ..color = Colors.yellow.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(selectionRect!, paint);
      canvas.drawRect(selectionRect!, borderPaint);
    }
  }

  @override
  void onDispose() {
    _timer?.cancel();

    // 스트림 닫기
    if (!_timerController.isClosed) {
      _timerController.close();
    }

    // 오디오 정리
    try {
      _backgroundMusicPlayer.stop();
      _backgroundMusicPlayer.dispose();
    } catch (_) {}

    try {
      _effectPlayer.stop();
      _effectPlayer.dispose();
    } catch (_) {}

    // Notifier 정리
    gameOverNotifier.dispose();
    imageYNotifier.dispose();

    super.onDispose();
  }
}
