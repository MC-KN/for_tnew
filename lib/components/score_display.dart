import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';

class ScoreDisplayComponent extends PositionComponent {
  int score;
  late TextComponent scoreText;
  late SpriteComponent heartSprite;


  ScoreDisplayComponent({
    required Vector2 position,
    required this.score,
    double? size,
  }) : super(position: position, size: Vector2.all(size ?? 120));

  @override
  Future<void> onLoad() async {
    final heartImage = await Flame.images.load('hearts.jpg');
    heartSprite = SpriteComponent.fromImage(
      heartImage,
      size: Vector2.all(size.x * 0.35),
      anchor: Anchor.center,
    );
    heartSprite.position = Vector2(size.x * 0.25, size.y / 2);
    add(heartSprite);

    scoreText = TextComponent(
      text: '$score',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: size.x * 0.3,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Comic Sans',
        ),
      ),
      anchor: Anchor.centerLeft,
    );
    scoreText.position = Vector2(size.x * 0.5, size.y / 2);
    add(scoreText);
  }

  void updateScore(int newScore) {
    if (newScore > score) {
      // 점수가 올라갈 때 흔들림 효과
      add(SequenceEffect([
        MoveEffect.by(Vector2(5, 0), EffectController(duration: 0.05, alternate: true)),
        MoveEffect.by(Vector2(-5, 0), EffectController(duration: 0.05, alternate: true)),
        MoveEffect.by(Vector2(0, 5), EffectController(duration: 0.05, alternate: true)),
        MoveEffect.by(Vector2(0, -5), EffectController(duration: 0.05, alternate: true)),
        MoveEffect.by(Vector2(0, 0), EffectController(duration: 0.1)), // 원위치
      ]));
    }
    score = newScore;
    scoreText.text = '$score';
  }
}
