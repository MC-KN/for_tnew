import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';

/// 숫자 셀 컴포넌트
class NumberCell extends PositionComponent {
  int number;
  final double cellSize;
  final Vector2 gridPos;
  bool isSelected = false;
  late Sprite sprite;

  NumberCell({
    required this.number,
    required this.cellSize,
    required this.gridPos,
    required Vector2 position,
  }) : super(position: position, size: Vector2.all(cellSize));

  @override
  Future<void> onLoad() async {
    final image = await Flame.images.load('sans_face.jpg');
    sprite = Sprite(image);
  }

  @override
  void render(Canvas canvas) {
    // 배경 (선택 여부에 따른 색상)
    final bgPaint = Paint()
      ..color = isSelected ? Colors.red.withOpacity(0.5) : Colors.transparent;
    canvas.drawRect(size.toRect(), bgPaint);

    // 이미지 그리기
    sprite.render(canvas, size: size);

    final baseStyle = TextStyle(
      fontSize: cellSize * 0.8,
      fontWeight: FontWeight.bold,
      fontFamily: 'Comic Sans',
    );

    // 테두리(검정) 스타일
    final strokeStyle = baseStyle.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, cellSize * 0.08)
        ..color = Colors.black,
    );

    // 채움(기존 색) 스타일
    final fillStyle = baseStyle.copyWith(
      color: isSelected ? Colors.cyanAccent : Colors.white,
    );

    final strokePainter = TextPainter(
      text: TextSpan(text: '$number', style: strokeStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final fillPainter = TextPainter(
      text: TextSpan(text: '$number', style: fillStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      (size.x - fillPainter.width) / 2,
      (size.y - fillPainter.height) / 2,
    );

    // 1) 테두리 먼저
    strokePainter.paint(canvas, offset);
    // 2) 채움 위에
    fillPainter.paint(canvas, offset);
  }
  // void render(Canvas canvas) {
  //   // 배경 (선택 여부에 따른 색상)
  //   final bgPaint = Paint()..color = isSelected ? Colors.red.withOpacity(0.5) : Colors.transparent;
  //   canvas.drawRect(size.toRect(), bgPaint);
  //
  //   // 이미지 그리기
  //   sprite.render(canvas, size: size);
  //
  //   // 숫자 텍스트 (샌즈 폰트 적용 가능 구역)
  //   final textPainter = TextPainter(
  //     text: TextSpan(
  //       text: '$number',
  //       style: TextStyle(
  //         color: isSelected ? Colors.cyanAccent : Colors.white,
  //         fontSize: cellSize * 0.8,
  //         fontWeight: FontWeight.bold,
  //         fontFamily: 'Comic Sans', // 준비된 폰트명
  //       ),
  //     ),
  //     textDirection: TextDirection.ltr,
  //   )..layout();
  //
  //   textPainter.paint(canvas, Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2));
  // }
}
