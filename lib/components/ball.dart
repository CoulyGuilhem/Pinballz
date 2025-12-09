import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../pinballz_game.dart';

class Ball extends SpriteComponent with HasGameRef<PinballzGame> {
  Ball({
    required Vector2 position,
    required double radius,
    Color color = Colors.white, // gardé au cas où, mais plus vraiment utile
  })  : radius = radius,
        super(
        position: position,
        size: Vector2.all(radius * 2), // diamètre = taille affichée
        anchor: Anchor.center,
      );

  /// Rayon logique pour la physique/collisions
  final double radius;

  Vector2 velocity = Vector2.zero();

  static const double gravity = 1500.0;
  static const double bounceDamping = 0.7;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ⚠️ adapte le chemin au nom réel dans ton pubspec.yaml
    // ex:
    // assets:
    //   - assets/images/ball.png
    sprite = await Sprite.load('ball.png');
  }

  @override
  void update(double dt) {
    super.update(dt);

    final g = gameRef;

    // --- Sub-stepping pour éviter le tunneling ---
    const int subSteps = 4;
    final double stepDt = dt / subSteps;

    for (int i = 0; i < subSteps; i++) {
      // Physique
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

      // --- Rotation du sprite pour l'effet "roulement" ---
      final speed = velocity.length;      // norme de la vitesse
      final omega = speed / r;            // ω = v / R (rad/s)
      final dir = velocity.x >= 0 ? 1.0 : -1.0; // sens de rotation selon la direction horizontale

      angle += dir * omega * stepDt;      // angle est en radians
    }

    // hors écran en bas => on supprime la balle
    if (position.y - radius > g.size.y + 200) {
      removeFromParent();
    }
  }
}
