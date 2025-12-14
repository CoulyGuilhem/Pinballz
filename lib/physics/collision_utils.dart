import 'dart:math';

import 'package:flame/components.dart';

import '../components/ball.dart';

class CollisionUtils {
  /// Collision balle <-> segment (capsule), avec option de vitesse de surface (ex: flipper).
  static void collideBallWithSegment(
      Ball ball,
      Vector2 a,
      Vector2 b, {
        double extraRadius = 0,
        double restitution = Ball.bounceDamping,
        Vector2? surfaceVelocity, // ✅ null par défaut
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
    if (dist2 >= r * r) return;

    final dist = sqrt(max(dist2, 1e-9));
    final n = delta / dist;

    // Dépénétration
    ball.position += n * (r - dist);

    // vitesse de surface (si null => 0)
    final sv = surfaceVelocity ?? Vector2.zero();

    // Rebond en vitesse relative
    final vRel = ball.velocity - sv;
    final vn = vRel.dot(n);
    if (vn >= 0) return;

    final vRelAfter = vRel - n * ((1 + restitution) * vn);
    ball.velocity = sv + vRelAfter;
  }

  /// Collision balle <-> balle (masses égales)
  static void collideBallWithBall(
      Ball a,
      Ball b, {
        double restitution = Ball.bounceDamping,
      }) {
    final delta = b.position - a.position;
    final dist2 = delta.length2;

    final r = a.radius + b.radius;
    if (dist2 >= r * r || dist2 == 0) return;

    final dist = sqrt(dist2);
    final n = delta / dist;

    // correction de pénétration
    final overlap = r - dist;
    final correction = n * (overlap / 2);
    a.position -= correction;
    b.position += correction;

    // impulsion (vitesses relatives)
    final rv = b.velocity - a.velocity;
    final vn = rv.dot(n);
    if (vn > 0) return;

    final j = -(1 + restitution) * vn / 2; // masses égales
    final impulse = n * j;

    a.velocity -= impulse;
    b.velocity += impulse;
  }

  /// Vitesse tangentielle d'un point sur un corps en rotation autour d'un pivot.
  /// ω en rad/s.
  static Vector2 surfaceVelocityFromAngular(
      Vector2 pivot,
      Vector2 point,
      double angularVelocity,
      ) {
    final rVec = point - pivot;
    return Vector2(
      -angularVelocity * rVec.y,
      angularVelocity * rVec.x,
    );
  }
}
