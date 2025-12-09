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
  static const double borderThicknessRatio = 0.015; // épaisseur des murs relative

  // Flippers
  late FlipperComponent leftFlipper;   // ROUGE (à gauche)
  late FlipperComponent rightFlipper;  // BLEU (à droite)

  // Géométrie du plateau
  late double playfieldLeft;
  late double playfieldRight;
  late double playfieldTop;
  late double playfieldBottom;
  late double wallThickness;

  // Murs inclinés (components)
  late WallSegmentComponent leftSlopeWall;
  late WallSegmentComponent rightSlopeWall;

  // Dimensions flippers
  late double flipperLength;
  late double flipperHeight;

  // amplitude d'angle (en radians)
  final double flipperDownAbs = 0.3; // inclinaison en bas
  final double flipperUpAbs = 0.3;   // inclinaison en haut
  final double flipperSpeed = 8.0;   // vitesse de rotation (rad/s)

  // Angles spécifiques pour chaque flip
  double get leftDownAngle => flipperDownAbs;   // gauche bas = angle positif
  double get leftUpAngle   => -flipperUpAbs;    // gauche haut = angle négatif

  double get rightDownAngle => -flipperDownAbs; // droite bas = angle négatif
  double get rightUpAngle   => flipperUpAbs;    // droite haut = angle positif

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

    // ---------- DEBUG ----------
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

    // ---------- PLATEAU ----------
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

    // ---------- MURS INCLINÉS ----------
    final slopeLength = playfieldWidth * 0.18;
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

    // ---------- FLIPPERS ----------
    _createFlippers(
      playfieldWidth: playfieldWidth,
      leftPivot: leftSlopeEnd,
      rightPivot: rightSlopeEnd,
      h: h,
    );
  }

  // ---------- BORDS PRINCIPAUX ----------
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

  // ---------- MURS INCLINÉS ----------
  void _createLowerAreaWalls({
    required Vector2 leftSlopeStart,
    required Vector2 leftSlopeEnd,
    required Vector2 rightSlopeStart,
    required Vector2 rightSlopeEnd,
  }) {
    // pente gauche : on garde l’ancien comportement
    leftSlopeWall = WallSegmentComponent(
      start: leftSlopeStart,
      end: leftSlopeEnd,
      thickness: wallThickness,
      color: Colors.white,
      anchor: Anchor.topLeft,   // comme avant
    );
    add(leftSlopeWall);

    // pente droite : on change uniquement l’anchor
    rightSlopeWall = WallSegmentComponent(
      start: rightSlopeStart,
      end: rightSlopeEnd,
      thickness: wallThickness,
      color: Colors.white,
      anchor: Anchor.bottomLeft, // <<< déplace le mur de l’autre côté du segment
    );
    add(rightSlopeWall);
  }


  // ---------- FLIPPERS ----------
  void _createFlippers({
    required double playfieldWidth,
    required Vector2 leftPivot,
    required Vector2 rightPivot,
    required double h,
  }) {
    flipperLength = playfieldWidth * 0.225;
    flipperHeight = h * 0.035;

    leftFlipper = FlipperComponent(
      pivot: leftPivot,
      isLeft: true,
      flipperLength: flipperLength,
      flipperHeight: flipperHeight,
      downAngle: leftDownAngle,
      upAngle: leftUpAngle,
      flipperSpeed: flipperSpeed,
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

  // ---------- SPAWN BALL À LA SOURIS ----------
  void _spawnBall(Vector2 worldPosition) {
    final double r = size.x * 0.045;
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
      color: Colors.white,
    );

    add(ball);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _spawnBall(event.localPosition);
  }

  // ---------- COLLISIONS SPÉCIALES (PENTES + FLIPS) ----------
  void handleBallExtraCollisions(Ball ball) {
    // barres inclinées (murs)
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

    // flippers : segment au milieu du rectangle, avec épaisseur et vitesse angulaire
    _collideBallWithFlipper(ball, leftFlipper, isLeft: true);
    _collideBallWithFlipper(ball, rightFlipper, isLeft: false);
  }

  void _collideBallWithFlipper(
      Ball ball,
      FlipperComponent flipper, {
        required bool isLeft,
      }) {
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

    // vitesse de la surface (flipper en rotation)
    Vector2 surfaceVelocity = Vector2.zero();
    if (angularVelocity != null && pivot != null) {
      final rVec = closest - pivot;
      // v = ω × r (2D : (-ω * r.y, ω * r.x))
      surfaceVelocity = Vector2(
        -angularVelocity * rVec.y,
        angularVelocity * rVec.x,
      );
    }

    // vitesse relative balle/surface
    final vRel = ball.velocity - surfaceVelocity;
    final vn = vRel.dot(n);

    if (vn >= 0) return;

    // correction de pénétration
    final overlap = r - dist;
    ball.position += n * overlap;

    const double e = Ball.bounceDamping;

    // réflexion de la vitesse relative
    final vRelAfter = vRel - n * ((1 + e) * vn);

    // vitesse finale
    ball.velocity = surfaceVelocity + vRelAfter;
  }

  // ---------- INPUT CLAVIER ----------
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event,
      Set<LogicalKeyboardKey> keysPressed,
      ) {
    // on regarde l'état ACTUEL des touches, pas le type d'event
    final isLeftDown =
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
            keysPressed.contains(LogicalKeyboardKey.keyA);

    final isRightDown =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
            keysPressed.contains(LogicalKeyboardKey.keyD);

    // on envoie l'état courant aux flippers
    leftFlipper.setPressed(isLeftDown);
    rightFlipper.setPressed(isRightDown);

    // si l'event concerne une de ces touches, on le "consomme"
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA ||
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
