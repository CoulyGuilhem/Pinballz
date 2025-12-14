import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import 'ball.dart';

class BumperComponent extends SpriteComponent {
  BumperComponent({
    required Vector2 position,
    required double radius,
    this.kickStrength = 2200.0,
    this.cooldown = 0.06,
  })  : _baseRadius = radius,
        super(
        position: position,
        size: Vector2.all(radius * 2),
        anchor: Anchor.center,
      );

  /// Rayon de base (avant animation)
  final double _baseRadius;

  /// Force d’éjection
  final double kickStrength;

  /// Cooldown pour éviter les collisions répétées
  final double cooldown;

  double _cooldownTimer = 0.0;

  /// Rayon réel utilisé pour la collision (prend en compte le scale)
  double get visualRadius => _baseRadius * scale.x;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Sprite obligatoire
    sprite = await Sprite.load('bumper.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_cooldownTimer > 0) {
      _cooldownTimer -= dt;
    }
  }

  /// Collision bumper <-> balle
  void collide(Ball ball) {
    if (_cooldownTimer > 0) return;

    final delta = ball.position - position;
    final r = visualRadius + ball.radius;
    final dist2 = delta.length2;

    if (dist2 >= r * r) return;

    // Normale
    final dist = sqrt(max(dist2, 0.000001));
    final n = delta / dist;

    // Dépénétration
    final overlap = r - dist;
    ball.position += n * overlap;

    // Éjection
    ball.velocity += n * kickStrength;

    // Animation
    _playHitEffect();

    _cooldownTimer = cooldown;
  }

  void _playHitEffect() {
    // Pulse (grossissement puis retour)
    add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(
          duration: 0.06,
          curve: Curves.easeOut,
        ),
      ),
    );

    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.10,
          curve: Curves.easeIn,
          startDelay: 0.06,
        ),
      ),
    );

    // Vibration
    add(
      MoveEffect.by(
        Vector2(3, 0),
        EffectController(
          duration: 0.03,
          alternate: true,
          repeatCount: 6,
        ),
      ),
    );

    add(
      MoveEffect.by(
        Vector2(0, 2),
        EffectController(
          duration: 0.02,
          alternate: true,
          repeatCount: 8,
        ),
      ),
    );
  }
}
