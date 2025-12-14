import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/ball.dart';
import 'components/flipper.dart';
import 'components/wall_segment.dart';

class PinballzGame extends FlameGame with KeyboardEvents, TapCallbacks {
  static const double borderThicknessRatio = 0.015;

  // Flippers
  late FlipperComponent leftFlipper;
  late FlipperComponent rightFlipper;

  // Géométrie du plateau
  late double playfieldLeft;
  late double playfieldRight;
  late double playfieldTop;
  late double playfieldBottom;
  late double wallThickness;

  // Pentes
  late WallSegmentComponent leftSlopeWall;
  late WallSegmentComponent rightSlopeWall;

  // Dimensions flippers
  late double flipperLength;
  late double flipperHeight;

  // Angles flippers
  final double flipperDownAbs = 0.3;
  final double flipperUpAbs = 0.3;
  final double flipperSpeed = 8.0;

  double get leftDownAngle => flipperDownAbs;
  double get leftUpAngle => -flipperUpAbs;

  double get rightDownAngle => -flipperDownAbs;
  double get rightUpAngle => flipperUpAbs;

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildWorld();
  }

  void _buildWorld() {
    final w = size.x;
    final h = size.y;

    // DEBUG dimensions
    add(
      TextComponent(
        text: 'DEBUG: zone Flame = ${w.toStringAsFixed(0)} x ${h.toStringAsFixed(0)}',
        position: Vector2(10, 10),
        priority: 10,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );

    // Plateau
    playfieldTop = 0.0;
    playfieldBottom = h * 0.82;

    final playfieldWidth = w * 1.0;
    playfieldLeft = 0.0;
    playfieldRight = playfieldLeft + playfieldWidth;

    wallThickness = playfieldWidth * borderThicknessRatio;

    add(
      TextComponent(
        text: 'CENTER',
        position: Vector2(
          (playfieldLeft + playfieldRight) / 2,
          (playfieldTop + playfieldBottom) / 2,
        ),
        anchor: Anchor.center,
        priority: 10,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.pinkAccent,
            fontSize: 10,
          ),
        ),
      ),
    );

    _createPlayfieldBorders(
      playfieldLeft,
      playfieldRight,
      playfieldTop,
      playfieldBottom,
      wallThickness,
    );

    // Pentes
    final slopeLength = playfieldWidth * 0.2;
    const slopeAngle = 0.4;
    const slopeYOffset = 0.0;

    final slopeY = playfieldBottom - slopeYOffset;

    final leftSlopeStart = Vector2(playfieldLeft + wallThickness, slopeY);
    final rightSlopeStart = Vector2(playfieldRight - wallThickness, slopeY);

    final leftSlopeEnd = leftSlopeStart +
        Vector2(
          slopeLength * cos(slopeAngle),
          slopeLength * sin(slopeAngle),
        );

    final rightSlopeEnd = rightSlopeStart +
        Vector2(
          slopeLength * cos(pi - slopeAngle),
          slopeLength * sin(pi - slopeAngle),
        );

    _createLowerAreaWalls(
      leftSlopeStart: leftSlopeStart,
      leftSlopeEnd: leftSlopeEnd,
      rightSlopeStart: rightSlopeStart,
      rightSlopeEnd: rightSlopeEnd,
    );

    // Flippers
    _createFlippers(
      playfieldWidth: playfieldWidth,
      leftPivot: leftSlopeEnd,
      rightPivot: rightSlopeEnd,
      h: h,
    );
  }

  void _createPlayfieldBorders(
      double leftX,
      double rightX,
      double topY,
      double bottomY,
      double wallThickness,
      ) {
    final wallPaint = Paint()..color = Colors.blueGrey;

    // haut
    add(
      RectangleComponent(
        position: Vector2(leftX, topY),
        size: Vector2(rightX - leftX, wallThickness),
        paint: wallPaint,
      ),
    );

    // gauche
    add(
      RectangleComponent(
        position: Vector2(leftX, topY),
        size: Vector2(wallThickness, bottomY - topY),
        paint: wallPaint,
      ),
    );

    // droite
    add(
      RectangleComponent(
        position: Vector2(rightX - wallThickness, topY),
        size: Vector2(wallThickness, bottomY - topY),
        paint: wallPaint,
      ),
    );

    // ligne de debug bas plateau
    add(
      RectangleComponent(
        position: Vector2(leftX, bottomY),
        size: Vector2(rightX - leftX, 1),
        paint: Paint()..color = Colors.greenAccent.withOpacity(0.5),
      ),
    );

    add(
      TextComponent(
        text:
        'DEBUG: plateau ${(rightX - leftX).toStringAsFixed(0)} x ${(bottomY - topY).toStringAsFixed(0)}',
        position: Vector2(leftX + 8, topY + 20),
        priority: 10,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  void _createLowerAreaWalls({
    required Vector2 leftSlopeStart,
    required Vector2 leftSlopeEnd,
    required Vector2 rightSlopeStart,
    required Vector2 rightSlopeEnd,
  }) {
    leftSlopeWall = WallSegmentComponent(
      start: leftSlopeStart,
      end: leftSlopeEnd,
      thickness: wallThickness,
      color: Colors.white,
      anchorPoint: Anchor.topLeft
    );
    add(leftSlopeWall);

    rightSlopeWall = WallSegmentComponent(
      start: rightSlopeStart,
      end: rightSlopeEnd,
      thickness: wallThickness,
      color: Colors.white,
      anchorPoint: Anchor.bottomLeft
    );
    add(rightSlopeWall);
  }

  void _createFlippers({
    required double playfieldWidth,
    required Vector2 leftPivot,
    required Vector2 rightPivot,
    required double h,
  }) {
    flipperLength = playfieldWidth * 0.25;
    flipperHeight = h * 0.035;

    leftFlipper = FlipperComponent(
      pivot: leftPivot,
      isLeft: true,
      flipperLength: flipperLength,
      flipperHeight: flipperHeight,
      downAngle: leftDownAngle,
      upAngle: leftUpAngle,
      flipperSpeed: flipperSpeed,
      spriteName: 'left_flip.png'
    );
    add(leftFlipper);

    rightFlipper = FlipperComponent(
      pivot: rightPivot,
      isLeft: false,
      flipperLength: flipperLength,
      flipperHeight: flipperHeight,
      downAngle: rightDownAngle,
      upAngle: rightUpAngle,
      flipperSpeed: flipperSpeed,
      spriteName: 'right_flip.png'
    );
    add(rightFlipper);

    final centerX = (leftPivot.x + rightPivot.x) / 2;
    add(
      TextComponent(
        text: 'DEBUG: flippers rectangles alignés',
        position: Vector2(centerX, h - 20),
        anchor: Anchor.center,
        priority: 10,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // SPAWN BALL à la souris
  void _spawnBall(Vector2 worldPosition) {
    final double r = size.x * 0.035;
    final double minX = playfieldLeft + wallThickness + r;
    final double maxX = playfieldRight - wallThickness - r;
    final double minY = playfieldTop + wallThickness + r;
    final double maxY = playfieldBottom - r;

    final clamped = Vector2(
      worldPosition.x.clamp(minX, maxX),
      worldPosition.y.clamp(minY, maxY),
    );

    final ball = Ball(
      position: clamped,
      radius: r,
    );

    add(ball);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _spawnBall(event.localPosition);
  }

  // COLLISIONS spéciales (pentes + flippers)
  void handleBallExtraCollisions(Ball ball) {
    // pentes
    _collideBallWithSegment(
      ball,
      leftSlopeWall.start,
      leftSlopeWall.end,
    );
    _collideBallWithSegment(
      ball,
      rightSlopeWall.start,
      rightSlopeWall.end,
    );

    // flippers
    _collideBallWithFlipper(ball, leftFlipper);
    _collideBallWithFlipper(ball, rightFlipper);
  }

  void _collideBallWithFlipper(Ball ball, FlipperComponent flipper) {
    final start = flipper.worldStart;
    final end = flipper.worldEnd;
    final pivot = flipper.position;

    _collideBallWithSegment(
      ball,
      start,
      end,
      extraRadius: flipper.flipperHeight / 2,
      angularVelocity: flipper.angularVelocity,
      pivot: pivot,
    );
  }

  void _collideBallWithSegment(
      Ball ball,
      Vector2 a,
      Vector2 b, {
        double extraRadius = 0,
        double? angularVelocity,
        Vector2? pivot,
      }) {
    final ab = b - a;
    final abLen2 = ab.length2;
    if (abLen2 == 0) return;

    final ap = ball.position - a;
    double t = ap.dot(ab) / abLen2;
    t = t.clamp(0.0, 1.0);

    final closest = a + ab * t;
    final delta = ball.position - closest;
    final dist2 = delta.length2;

    final r = ball.radius + extraRadius;
    final r2 = r * r;

    if (dist2 >= r2) return;

    double dist = sqrt(dist2);
    Vector2 n;

    if (dist == 0) {
      n = Vector2(-ab.y, ab.x).normalized();
      dist = r;
    } else {
      n = delta / dist;
    }

    // vitesse de la surface (flipper)
    Vector2 surfaceVelocity = Vector2.zero();
    if (angularVelocity != null && pivot != null) {
      final rVec = closest - pivot;
      surfaceVelocity = Vector2(
        -angularVelocity * rVec.y,
        angularVelocity * rVec.x,
      );
    }

    final vRel = ball.velocity - surfaceVelocity;
    final vn = vRel.dot(n);

    if (vn >= 0) return;

    final overlap = r - dist;
    ball.position += n * overlap;

    const e = Ball.bounceDamping;

    final vRelAfter = vRel - n * ((1 + e) * vn);

    ball.velocity = surfaceVelocity + vRelAfter;
  }

  // 🔄 UPDATE global : on ajoute les collisions bille–bille
  @override
  void update(double dt) {
    super.update(dt);
    _handleBallBallCollisions();
  }

  void _handleBallBallCollisions() {
    final balls = children.whereType<Ball>().toList();
    final int n = balls.length;
    if (n < 2) return;

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        _resolveBallCollision(balls[i], balls[j]);
      }
    }
  }

  void _resolveBallCollision(Ball a, Ball b) {
    final delta = b.position - a.position;
    final dist2 = delta.length2;

    final double r = a.radius + b.radius;
    final double r2 = r * r;

    if (dist2 >= r2 || dist2 == 0) {
      return;
    }

    final dist = sqrt(dist2);
    final n = delta / dist;

    // correction de pénétration
    final overlap = r - dist;
    final correction = n * (overlap / 2);
    a.position -= correction;
    b.position += correction;

    // vitesses relatives
    final rv = b.velocity - a.velocity;
    final vn = rv.dot(n);

    if (vn > 0) {
      return;
    }

    const e = Ball.bounceDamping;

    // masses égales => impulse simplifié
    final j = -(1 + e) * vn / 2;
    final impulse = n * j;

    a.velocity -= impulse;
    b.velocity += impulse;
  }

  // INPUT clavier
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event,
      Set<LogicalKeyboardKey> keysPressed,
      ) {
    // on lit l'état courant des touches (robuste vs KeyRepeat)
    final isLeftDown =
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
            keysPressed.contains(LogicalKeyboardKey.keyA);

    final isRightDown =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
            keysPressed.contains(LogicalKeyboardKey.keyD);

    leftFlipper.setPressed(isLeftDown);
    rightFlipper.setPressed(isRightDown);

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA ||
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
