import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum FlipperState {
  down,
  goingUp,
  up,
  goingDown,
}

class FlipperComponent extends RectangleComponent {
  final bool isLeft;
  final double flipperLength;
  final double flipperHeight;
  final double downAngle;
  final double upAngle;
  final double flipperSpeed; // rad/s

  double angularVelocity = 0.0; // rad/s

  // 🔽 nouvel état interne
  FlipperState state = FlipperState.down;
  bool inputPressed = false;
  bool releaseQueued = false; // relâchement pendant la montée

  FlipperComponent({
    required Vector2 pivot,
    required this.isLeft,
    required this.flipperLength,
    required this.flipperHeight,
    required this.downAngle,
    required this.upAngle,
    required this.flipperSpeed,
    required Color color,
  }) : super(
    position: pivot,
    size: Vector2(flipperLength, flipperHeight),
    anchor: isLeft ? Anchor.topLeft : Anchor.topRight,
    angle: downAngle,
    paint: Paint()..color = color,
  );

  /// Appelé par le clavier
  void setPressed(bool pressed) {
    if (pressed == inputPressed) return;
    inputPressed = pressed;

    if (pressed) {
      // keyDown : on veut monter
      releaseQueued = false;
      if (state == FlipperState.down || state == FlipperState.goingDown) {
        state = FlipperState.goingUp;
      }
    } else {
      // keyUp : on ne redescendra que quand on sera en haut
      if (state == FlipperState.up) {
        state = FlipperState.goingDown;
      } else if (state == FlipperState.goingUp) {
        // on note qu'il faudra redescendre une fois arrivé en haut
        releaseQueued = true;
      }
    }
  }

  /// Point de départ du segment de collision du flipper (dans le monde)
  Vector2 get worldStart {
    final pivot = position;
    final startLocal = Vector2(0, flipperHeight / 2);
    final rotated = startLocal.clone()..rotate(angle);
    return pivot + rotated;
  }

  /// Point de fin du segment de collision du flipper (dans le monde)
  Vector2 get worldEnd {
    final pivot = position;
    final endLocal = isLeft
        ? Vector2(flipperLength, flipperHeight / 2)
        : Vector2(-flipperLength, flipperHeight / 2);
    final rotated = endLocal.clone()..rotate(angle);
    return pivot + rotated;
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (state) {
      case FlipperState.down:
        angularVelocity = 0.0;
        angle = downAngle;
        if (inputPressed) {
          state = FlipperState.goingUp;
        }
        break;

      case FlipperState.goingUp:
        _moveTowardsAngle(target: upAngle, dt: dt);
        // arrivé en haut ?
        if ((upAngle - angle).abs() < 0.001) {
          angle = upAngle;
          angularVelocity = 0.0;

          if (releaseQueued || !inputPressed) {
            // si on a relâché pendant la montée → on enchaîne vers la descente
            state = FlipperState.goingDown;
            releaseQueued = false;
          } else {
            state = FlipperState.up;
          }
        }
        break;

      case FlipperState.up:
        angularVelocity = 0.0;
        angle = upAngle;
        if (!inputPressed) {
          state = FlipperState.goingDown;
        }
        break;

      case FlipperState.goingDown:
        _moveTowardsAngle(target: downAngle, dt: dt);
        if ((downAngle - angle).abs() < 0.001) {
          angle = downAngle;
          angularVelocity = 0.0;
          // si on a ré-appuyé pendant la descente → on remonte direct
          if (inputPressed) {
            state = FlipperState.goingUp;
          } else {
            state = FlipperState.down;
          }
        }
        break;
    }
  }

  void _moveTowardsAngle({required double target, required double dt}) {
    final diff = target - angle;
    if (diff.abs() < 0.001) {
      angularVelocity = 0.0;
      return;
    }

    final maxStep = flipperSpeed * dt;
    final step = diff.clamp(-maxStep, maxStep);

    angularVelocity = step / dt;
    angle += step;
  }
}
