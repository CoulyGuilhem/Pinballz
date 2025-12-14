import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'ball.dart';

enum CurveDirection {
  inward,  // creusé vers le centre
  outward, // bombé vers l'extérieur
}

class SegmentCurve {
  /// 0 = segment droit
  /// >0 = courbe (bulge en pixels)
  final double bulgePx;

  /// inward/outward par rapport au centre de la forme
  final CurveDirection direction;

  /// qualité collision/rendu de la courbe (plus = plus lisse)
  final int samples;

  const SegmentCurve({
    this.bulgePx = 0,
    this.direction = CurveDirection.inward,
    this.samples = 10,
  });
}

class FilledShapeComponent extends PositionComponent {
  /// points: points en coordonnées MONDE (simple pour designer)
  /// curves: une config par segment [i -> i+1], et le dernier = [last -> 0]
  FilledShapeComponent({
    required this.points,
    required this.curves,
    required this.color,
    this.borderThickness = 6,
    this.restitution = 0.7,
    this.debugDrawPolyline = false,
  }) : assert(points.length >= 3, 'Il faut au moins 3 points pour une forme fermée'),
        assert(curves.length == points.length,
        'curves doit avoir la même taille que points (un segment par point)');

  final List<Vector2> points;
  final List<SegmentCurve> curves;

  final Color color;

  /// épaisseur utilisée pour la collision (bord)
  final double borderThickness;

  /// rebond (0.7 comme ta balle)
  final double restitution;

  /// debug visuel de la polyline de collision
  final bool debugDrawPolyline;

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _debugPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  late Path _path;
  late List<Vector2> _polyline; // points échantillonnés pour collision

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rebuild();
  }

  /// Appelle ça si tu modifies points/curves à runtime
  void rebuild() => _rebuild();

  void _rebuild() {
    _fillPaint.color = color;
    _debugPaint.color = Colors.redAccent.withOpacity(0.8);

    final c = _centroid(points);
    _path = _buildPath(points, curves, c);
    _polyline = _sampleToPolyline(points, curves, c);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawPath(_path, _fillPaint);

    if (debugDrawPolyline) {
      final p = Path()..moveTo(_polyline.first.x, _polyline.first.y);
      for (int i = 1; i < _polyline.length; i++) {
        p.lineTo(_polyline[i].x, _polyline[i].y);
      }
      p.close();
      canvas.drawPath(p, _debugPaint);
    }
  }

  /// Collision : rebond sur le bord de la forme
  void collide(Ball ball) {
    // 1) collision "bord épais" via segments polyline
    final extra = borderThickness / 2;

    // Si balle à l'intérieur, on la pousse vers l'extérieur (sinon elle peut rester coincée)
    final inside = _pointInPolygon(ball.position, _polyline);

    double bestDist2 = double.infinity;
    Vector2 bestN = Vector2.zero();
    Vector2 bestClosest = Vector2.zero();

    for (int i = 0; i < _polyline.length; i++) {
      final a = _polyline[i];
      final b = _polyline[(i + 1) % _polyline.length];

      // On cherche le point le plus proche pour gérer aussi le cas "inside"
      final closest = _closestPointOnSegment(ball.position, a, b);
      final delta = ball.position - closest;
      final dist2 = delta.length2;

      if (dist2 < bestDist2) {
        bestDist2 = dist2;
        bestClosest = closest;
        final dist = sqrt(max(dist2, 1e-9));
        bestN = delta / dist;
      }

      // collision standard "à l'extérieur"
      _collideBallWithSegment(ball, a, b, extraRadius: extra);
    }

    // 2) si la balle est dedans, on la ressort vers l’extérieur (nearest edge)
    if (inside) {
      final dist = sqrt(max(bestDist2, 1e-9));
      final r = ball.radius + extra;
      final overlap = r - dist;

      // bestN pointe du bord vers la balle ; à l’intérieur c’est l’inverse de ce qu’il faut parfois
      // donc on pousse dans la direction de bestN (qui sort du bord vers la balle)
      ball.position += bestN * max(overlap, r);

      // rebond pour la sortir
      final vn = ball.velocity.dot(bestN);
      if (vn < 0) {
        ball.velocity -= bestN * ((1 + restitution) * vn);
      } else {
        // si elle allait déjà "sortir", on ajoute juste un petit kick
        ball.velocity += bestN * 100;
      }
    }
  }

  // ----------------------------
  // Construction Path
  // ----------------------------

  Path _buildPath(List<Vector2> pts, List<SegmentCurve> cfg, Vector2 center) {
    final path = Path()..moveTo(pts[0].x, pts[0].y);

    for (int i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      final c = cfg[i];

      if (c.bulgePx <= 0) {
        path.lineTo(b.x, b.y);
        continue;
      }

      // Courbe quadratique : contrôle au milieu + offset normal
      final mid = (a + b) / 2;
      final dir = (b - a);
      if (dir.length2 == 0) {
        path.lineTo(b.x, b.y);
        continue;
      }
      final u = dir.normalized();
      final n1 = Vector2(-u.y, u.x); // normale 1
      final toCenter = center - mid;
      final signToCenter = n1.dot(toCenter);

      // inward => vers le centre, outward => opposé centre
      final wantTowardCenter = (c.direction == CurveDirection.inward);

      // Si n1 pointe déjà vers le centre (dot>0), on l'utilise pour inward, sinon on inverse
      Vector2 n = (signToCenter >= 0) ? n1 : -n1;
      if (!wantTowardCenter) {
        n = -n;
      }

      final control = mid + n * c.bulgePx;
      path.quadraticBezierTo(control.x, control.y, b.x, b.y);
    }

    path.close();
    return path;
  }

  List<Vector2> _sampleToPolyline(List<Vector2> pts, List<SegmentCurve> cfg, Vector2 center) {
    final out = <Vector2>[];

    for (int i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      final c = cfg[i];

      // on pousse le point a
      if (out.isEmpty) out.add(a.clone());

      if (c.bulgePx <= 0) {
        out.add(b.clone());
        continue;
      }

      // Bézier quadratique échantillonnée
      final mid = (a + b) / 2;
      final dir = (b - a);
      if (dir.length2 == 0) {
        out.add(b.clone());
        continue;
      }
      final u = dir.normalized();
      final n1 = Vector2(-u.y, u.x);
      final toCenter = center - mid;
      final signToCenter = n1.dot(toCenter);

      Vector2 n = (signToCenter >= 0) ? n1 : -n1;
      if (c.direction == CurveDirection.outward) {
        n = -n;
      }

      final control = mid + n * c.bulgePx;

      final samples = max(2, c.samples);
      for (int s = 1; s <= samples; s++) {
        final t = s / samples;
        final p = _quadBezier(a, control, b, t);
        out.add(p);
      }
    }

    // évite doublon du dernier = premier
    if (out.length > 1 && (out.first - out.last).length < 0.001) {
      out.removeLast();
    }
    return out;
  }

  Vector2 _quadBezier(Vector2 p0, Vector2 p1, Vector2 p2, double t) {
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }

  // ----------------------------
  // Collisions helpers
  // ----------------------------

  void _collideBallWithSegment(Ball ball, Vector2 a, Vector2 b, {required double extraRadius}) {
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

    // dépénétration
    ball.position += n * (r - dist);

    // rebond
    final vn = ball.velocity.dot(n);
    if (vn >= 0) return;

    ball.velocity -= n * ((1 + restitution) * vn);
  }

  Vector2 _closestPointOnSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final abLen2 = ab.length2;
    if (abLen2 == 0) return a.clone();

    final ap = p - a;
    double t = ap.dot(ab) / abLen2;
    t = t.clamp(0.0, 1.0);
    return a + ab * t;
  }

  // Winding / ray casting (polygon simple)
  bool _pointInPolygon(Vector2 p, List<Vector2> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].x, yi = poly[i].y;
      final xj = poly[j].x, yj = poly[j].y;

      final intersect = ((yi > p.y) != (yj > p.y)) &&
          (p.x < (xj - xi) * (p.y - yi) / ((yj - yi) == 0 ? 1e-9 : (yj - yi)) + xi);

      if (intersect) inside = !inside;
    }
    return inside;
  }

  Vector2 _centroid(List<Vector2> pts) {
    // centroid polygon (shoelace), fallback moyenne
    double a = 0;
    double cx = 0;
    double cy = 0;

    for (int i = 0; i < pts.length; i++) {
      final p0 = pts[i];
      final p1 = pts[(i + 1) % pts.length];
      final cross = p0.x * p1.y - p1.x * p0.y;
      a += cross;
      cx += (p0.x + p1.x) * cross;
      cy += (p0.y + p1.y) * cross;
    }

    a *= 0.5;
    if (a.abs() < 1e-9) {
      // fallback
      final sum = pts.fold<Vector2>(Vector2.zero(), (acc, p) => acc + p);
      return sum / pts.length.toDouble();
    }

    cx /= (6 * a);
    cy /= (6 * a);
    return Vector2(cx, cy);
  }
}
