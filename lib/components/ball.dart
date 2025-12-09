import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../pinballz_game.dart';

class Ball extends SpriteComponent with HasGameRef<PinballzGame> {
  Ball({
    required Vector2 position,
    required double radius,
    Color color = Colors.white, // param laissé pour compat éventuelle
  })  : radius = radius,
        super(
        position: position,
        size: Vector2.all(radius * 2), // diamètre logique de la bille
        anchor: Anchor.center,
      );

  /// Rayon logique pour les collisions
  final double radius;

  Vector2 velocity = Vector2.zero();

  static const double gravity = 1500.0;
  static const double bounceDamping = 0.7;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // ⚠️ adapte le chemin selon ton pubspec.yaml
    // ex: assets/images/ball.png
    sprite = await Sprite.load('ball.png');
  }

  @override
  void update(double dt) {
    super.update(dt);

    final g = gameRef;

    // Sub-stepping pour réduire le tunneling
    const int subSteps = 4;
    final double stepDt = dt / subSteps;

    for (int i = 0; i < subSteps; i++) {
      // Gravité + mouvement
      velocity.y += gravity * stepDt;
      position += velocity * stepDt;

      final r = radius;

      // murs verticaux
      if (position.x - r < g.playfieldLeft + g.wallThickness) {
        position.x = g.playfieldLeft + g.wallThickness + r;
        velocity.x = -velocity.x * bounceDamping;
      }

      if (position.x + r > g.playfieldRight - g.wallThickness) {
        position.x = g.playfieldRight - g.wallThickness - r;
        velocity.x = -velocity.x * bounceDamping;
      }

      // mur du haut
      if (position.y - r < g.playfieldTop + g.wallThickness) {
        position.y = g.playfieldTop + g.wallThickness + r;
        velocity.y = -velocity.y * bounceDamping;
      }

      // collisions pentes + flippers
      g.handleBallExtraCollisions(this);

      // Rotation du sprite pour l'effet "roulement"
      final speed = velocity.length;
      if (speed > 0.01) {
        final omega = speed / r; // ω = v/R
        final dir = velocity.x >= 0 ? 1.0 : -1.0;
        angle += dir * omega * stepDt;
      }
    }

    // suppression si la balle est trop bas
    if (position.y - radius > g.size.y + 200) {
      removeFromParent();
    }
  }
}
