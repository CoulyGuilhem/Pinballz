import 'package:flame/components.dart';

import '../physics/collision_utils.dart';
import 'ball.dart';

enum FlipperState {
  down,
  goingUp,
  up,
  goingDown,
}

class FlipperComponent extends SpriteComponent {
  final bool isLeft;
  final double flipperLength;
  final double flipperHeight;
  final double downAngle;
  final double upAngle;
  final double flipperSpeed;
  final String spriteName;

  double angularVelocity = 0.0;

  FlipperState state = FlipperState.down;
  bool inputPressed = false;
  bool releaseQueued = false;

  FlipperComponent({
    required Vector2 pivot,
    required this.isLeft,
    required this.flipperLength,
    required this.flipperHeight,
    required this.downAngle,
    required this.upAngle,
    required this.flipperSpeed,
    required this.spriteName,
  }) : super(
    position: pivot,
    size: Vector2(flipperLength, flipperHeight),
    anchor: isLeft ? Anchor.topLeft : Anchor.topRight,
    angle: downAngle,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(spriteName);
  }

  void setPressed(bool pressed) {
    if (pressed == inputPressed) return;
    inputPressed = pressed;

    if (pressed) {
      releaseQueued = false;
      if (state == FlipperState.down || state == FlipperState.goingDown) {
        state = FlipperState.goingUp;
      }
    } else {
      if (state == FlipperState.up) {
        state = FlipperState.goingDown;
      } else if (state == FlipperState.goingUp) {
        releaseQueued = true;
      }
    }
  }

  Vector2 get worldStart {
    final local = Vector2(0, flipperHeight / 2);
    return position + (local..rotate(angle));
  }

  Vector2 get worldEnd {
    final local = isLeft
        ? Vector2(flipperLength, flipperHeight / 2)
        : Vector2(-flipperLength, flipperHeight / 2);
    return position + (local..rotate(angle));
  }

  void collide(Ball ball) {
    final start = worldStart;
    final end = worldEnd;

    // vitesse de surface au point de contact (calculée dans l'utilitaire)
    // On approxime en prenant la vitesse au "closest point" via l'API segment.
    // Pour ça, on appelle collideBallWithSegment avec surfaceVelocity calculée au milieu.
    // (simple + très bon en pratique)
    final mid = (start + end) / 2;
    final surfaceV =
    CollisionUtils.surfaceVelocityFromAngular(position, mid, angularVelocity);

    CollisionUtils.collideBallWithSegment(
      ball,
      start,
      end,
      extraRadius: flipperHeight / 2,
      restitution: Ball.bounceDamping,
      surfaceVelocity: surfaceV,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (state) {
      case FlipperState.down:
        angularVelocity = 0.0;
        angle = downAngle;
        if (inputPressed) state = FlipperState.goingUp;
        break;

      case FlipperState.goingUp:
        _moveTowardsAngle(upAngle, dt);
        if ((upAngle - angle).abs() < 0.001) {
          angle = upAngle;
          angularVelocity = 0.0;
          if (releaseQueued || !inputPressed) {
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
        if (!inputPressed) state = FlipperState.goingDown;
        break;

      case FlipperState.goingDown:
        _moveTowardsAngle(downAngle, dt);
        if ((downAngle - angle).abs() < 0.001) {
          angle = downAngle;
          angularVelocity = 0.0;
          if (inputPressed) {
            state = FlipperState.goingUp;
          } else {
            state = FlipperState.down;
          }
        }
        break;
    }
  }

  void _moveTowardsAngle(double target, double dt) {
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
