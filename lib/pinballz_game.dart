import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/ball.dart';
import 'components/bumper.dart';
import 'components/filled_shape.dart';
import 'components/flipper.dart';
import 'components/wall_segment.dart';
import 'physics/collision_utils.dart';

class PinballzGame extends FlameGame with KeyboardEvents, TapCallbacks {
  static const double borderThicknessRatio = 0.015;

  late FlipperComponent leftFlipper;
  late FlipperComponent rightFlipper;

  late double playfieldLeft;
  late double playfieldRight;
  late double playfieldTop;
  late double playfieldBottom;
  late double wallThickness;

  late WallSegmentComponent leftSlopeWall;
  late WallSegmentComponent rightSlopeWall;

  final List<BumperComponent> bumpers = [];
  final List<FilledShapeComponent> filledShapes = [];

  late double flipperLength;
  late double flipperHeight;

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

    add(
      TextComponent(
        text: 'DEBUG: zone Flame = ${w.toStringAsFixed(0)} x ${h.toStringAsFixed(0)}',
        position: Vector2(10, 10),
        priority: 10,
        textRenderer: TextPaint(
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );

    playfieldTop = 0.0;
    playfieldBottom = h * 0.82;

    final playfieldWidth = w * 1.0;
    playfieldLeft = 0.0;
    playfieldRight = playfieldLeft + playfieldWidth;

    wallThickness = playfieldWidth * borderThicknessRatio;

    _createPlayfieldBorders(playfieldLeft, playfieldRight, playfieldTop, playfieldBottom, wallThickness);

    // Pentes
    final slopeLength = playfieldWidth * 0.2;
    const slopeAngle = 0.4;
    final slopeY = playfieldBottom;

    final leftSlopeStart = Vector2(playfieldLeft + wallThickness, slopeY);
    final rightSlopeStart = Vector2(playfieldRight - wallThickness, slopeY);

    final leftSlopeEnd = leftSlopeStart + Vector2(
      slopeLength * cos(slopeAngle),
      slopeLength * sin(slopeAngle),
    );

    final rightSlopeEnd = rightSlopeStart + Vector2(
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

    _createBumpers();
    _createFilledShapes();
  }

  void _createPlayfieldBorders(double leftX, double rightX, double topY, double bottomY, double wallThickness) {
    final wallPaint = Paint()..color = Colors.blueGrey;

    add(RectangleComponent(
      position: Vector2(leftX, topY),
      size: Vector2(rightX - leftX, wallThickness),
      paint: wallPaint,
    ));

    add(RectangleComponent(
      position: Vector2(leftX, topY),
      size: Vector2(wallThickness, bottomY - topY),
      paint: wallPaint,
    ));

    add(RectangleComponent(
      position: Vector2(rightX - wallThickness, topY),
      size: Vector2(wallThickness, bottomY - topY),
      paint: wallPaint,
    ));

    add(RectangleComponent(
      position: Vector2(leftX, bottomY),
      size: Vector2(rightX - leftX, 1),
      paint: Paint()..color = Colors.greenAccent.withOpacity(0.5),
    ));
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
      anchorPoint: Anchor.topLeft,
    );
    add(leftSlopeWall);

    rightSlopeWall = WallSegmentComponent(
      start: rightSlopeStart,
      end: rightSlopeEnd,
      thickness: wallThickness,
      color: Colors.white,
      anchorPoint: Anchor.bottomLeft,
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
      spriteName: 'left_flip.png',
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
      spriteName: 'right_flip.png',
    );
    add(rightFlipper);
  }

  void _createBumpers() {
    final b1 = BumperComponent(
      position: Vector2(size.x * 0.50, size.y * 0.25),
      radius: size.x * 0.08,
      kickStrength: 2400,
      cooldown: 0.06,
    );
    add(b1);
    bumpers.add(b1);

    final b2 = BumperComponent(
      position: Vector2(size.x * 0.35, size.y * 0.35),
      radius: size.x * 0.08,
      kickStrength: 2200,
      cooldown: 0.06,
    );
    add(b2);
    bumpers.add(b2);
  }

  void _createFilledShapes() {
    final border = size.x * 0.02;

    final leftPts = <Vector2>[
      Vector2(size.x * 0.0, size.y * 0.0),
      Vector2(size.x * 0.25, size.y * 0.0),
      Vector2(size.x * 0.0, size.y * 0.25),
    ];

    final leftCurves = <SegmentCurve>[
      const SegmentCurve(bulgePx: 0),
      SegmentCurve(bulgePx: size.x * 0.15, direction: CurveDirection.inward, samples: 18),
      const SegmentCurve(bulgePx: 0),
    ];

    final leftTriangle = FilledShapeComponent(
      points: leftPts,
      curves: leftCurves,
      color: const Color(0xFF2EE6A6),
      borderThickness: border,
      restitution: Ball.bounceDamping,
      debugDrawPolyline: false,
    );
    add(leftTriangle);
    filledShapes.add(leftTriangle);

    final rightPts = <Vector2>[
      Vector2(size.x * 1.0, size.y * 0.0),
      Vector2(size.x * 0.75, size.y * 0.0),
      Vector2(size.x * 1.0, size.y * 0.25),
    ];

    final rightCurves = <SegmentCurve>[
      const SegmentCurve(bulgePx: 0),
      SegmentCurve(bulgePx: size.x * 0.15, direction: CurveDirection.inward, samples: 18),
      const SegmentCurve(bulgePx: 0),
    ];

    final rightTriangle = FilledShapeComponent(
      points: rightPts,
      curves: rightCurves,
      color: const Color(0xFF2EE6A6),
      borderThickness: border,
      restitution: Ball.bounceDamping,
      debugDrawPolyline: false,
    );
    add(rightTriangle);
    filledShapes.add(rightTriangle);
  }

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

    add(Ball(position: clamped, radius: r));
  }

  @override
  void onTapDown(TapDownEvent event) => _spawnBall(event.localPosition);

  /// Le Game ne fait plus les maths : il délègue aux composants.
  void handleBallExtraCollisions(Ball ball) {
    leftSlopeWall.collide(ball);
    rightSlopeWall.collide(ball);

    leftFlipper.collide(ball);
    rightFlipper.collide(ball);

    for (final bumper in bumpers) {
      bumper.collide(ball);
    }
    for (final shape in filledShapes) {
      shape.collide(ball);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Collisions bille-bille déplacées dans l'utilitaire
    final balls = children.whereType<Ball>().toList();
    for (int i = 0; i < balls.length; i++) {
      for (int j = i + 1; j < balls.length; j++) {
        CollisionUtils.collideBallWithBall(balls[i], balls[j]);
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isLeftDown =
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA);

    final isRightDown =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD);

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
