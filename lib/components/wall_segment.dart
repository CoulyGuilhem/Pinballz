import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WallSegmentComponent extends PositionComponent {
  final Vector2 start;
  final Vector2 end;
  final double thickness;
  final Paint paint;
  final Anchor anchorPoint;

  WallSegmentComponent({
    required this.start,
    required this.end,
    required this.thickness,
    required Color color,
    required this.anchorPoint,
  }) : paint = Paint()..color = color;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final delta = end - start;
    final length = delta.length;
    final angle = atan2(delta.y, delta.x);

    add(
      RectangleComponent(
        position: start,
        size: Vector2(length, thickness),
        anchor: anchorPoint,
        angle: angle,
        paint: paint,
      ),
    );
  }
}
