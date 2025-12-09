import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../pinballz_game.dart';

class Ball extends CircleComponent with HasGameRef<PinballzGame> {
  Ball({
    required Vector2 position,
    required double radius,
    Color color = Colors.white,
  }) : super(
    position: position,
    radius: radius,
    anchor: Anchor.center,
    paint: Paint()..color = color,
  );

  Vector2 velocity = Vector2.zero();

  static const double gravity = 1500.0;
  static const double bounceDamping = 0.7;

  @override
  void update(double dt) {
    super.update(dt);

    final g = gameRef;

    // Sub-stepping pour éviter le "tunneling"
    const int subSteps = 4;
    final double stepDt = dt / subSteps;

    for (int i = 0; i < subSteps; i++) {
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
    }

    // hors écran en bas => on supprime la balle
    if (position.y - radius > g.size.y + 200) {
      removeFromParent();
    }
  }
}
