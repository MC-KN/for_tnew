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
    final bgPaint = Paint()..color = isSelected ? Colors.red.withOpacity(0.5) : Colors.transparent;
    canvas.drawRect(size.toRect(), bgPaint);

    // 이미지 그리기
    sprite.render(canvas, size: size);

    // 숫자 텍스트 (샌즈 폰트 적용 가능 구역)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: isSelected ? Colors.cyanAccent : Colors.white,
          fontSize: cellSize * 0.8,
          fontWeight: FontWeight.bold,
          fontFamily: 'Comic Sans', // 준비된 폰트명
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2));
  }
}
