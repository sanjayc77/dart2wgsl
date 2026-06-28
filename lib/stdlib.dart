import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'annotations.dart';

// Single component trigonometric functions
double sin(double x) => math.sin(x);
double cos(double x) => math.cos(x);
double tan(double x) => math.tan(x);
double asin(double x) => math.asin(x);
double acos(double x) => math.acos(x);
double atan(double x) => math.atan(x);
double atan2(double y, double x) => math.atan2(y, x);

// Vector trigonometric functions
Vector2 sin2(Vector2 v) => Vector2(math.sin(v.x), math.sin(v.y));
Vector3 sin3(Vector3 v) => Vector3(math.sin(v.x), math.sin(v.y), math.sin(v.z));
Vector4 sin4(Vector4 v) => Vector4(math.sin(v.x), math.sin(v.y), math.sin(v.z), math.sin(v.w));

Vector2 cos2(Vector2 v) => Vector2(math.cos(v.x), math.cos(v.y));
Vector3 cos3(Vector3 v) => Vector3(math.cos(v.x), math.cos(v.y), math.cos(v.z));
Vector4 cos4(Vector4 v) => Vector4(math.cos(v.x), math.cos(v.y), math.cos(v.z), math.cos(v.w));

Vector2 tan2(Vector2 v) => Vector2(math.tan(v.x), math.tan(v.y));
Vector3 tan3(Vector3 v) => Vector3(math.tan(v.x), math.tan(v.y), math.tan(v.z));
Vector4 tan4(Vector4 v) => Vector4(math.tan(v.x), math.tan(v.y), math.tan(v.z), math.tan(v.w));

// Math helpers
double pow(double x, double y) => math.pow(x, y).toDouble();
double exp(double x) => math.exp(x);
double log(double x) => math.log(x);
double exp2(double x) => math.pow(2.0, x).toDouble();
double log2(double x) => math.log(x) / math.ln2;

double sqrt(double x) => math.sqrt(x);
double inverseSqrt(double x) => 1.0 / math.sqrt(x);

double abs(double x) => x.abs();
double sign(double x) => x > 0 ? 1.0 : (x < 0 ? -1.0 : 0.0);
double floor(double x) => x.floorToDouble();
double ceil(double x) => x.ceilToDouble();
double round(double x) => x.roundToDouble();
double trunc(double x) => x.truncateToDouble();
double fract(double x) => x - x.floorToDouble();

Vector2 fract2(Vector2 v) => Vector2(v.x - v.x.floorToDouble(), v.y - v.y.floorToDouble());
Vector3 fract3(Vector3 v) => Vector3(v.x - v.x.floorToDouble(), v.y - v.y.floorToDouble(), v.z - v.z.floorToDouble());
Vector4 fract4(Vector4 v) => Vector4(v.x - v.x.floorToDouble(), v.y - v.y.floorToDouble(), v.z - v.z.floorToDouble(), v.w - v.w.floorToDouble());

double min(double x, double y) => math.min(x, y);
double max(double x, double y) => math.max(x, y);
double clamp(double x, double minVal, double maxVal) => math.max(minVal, math.min(x, maxVal));

Vector2 clamp2(Vector2 v, double minVal, double maxVal) => Vector2(
  math.max(minVal, math.min(v.x, maxVal)),
  math.max(minVal, math.min(v.y, maxVal)),
);
Vector3 clamp3(Vector3 v, double minVal, double maxVal) => Vector3(
  math.max(minVal, math.min(v.x, maxVal)),
  math.max(minVal, math.min(v.y, maxVal)),
  math.max(minVal, math.min(v.z, maxVal)),
);
Vector4 clamp4(Vector4 v, double minVal, double maxVal) => Vector4(
  math.max(minVal, math.min(v.x, maxVal)),
  math.max(minVal, math.min(v.y, maxVal)),
  math.max(minVal, math.min(v.z, maxVal)),
  math.max(minVal, math.min(v.w, maxVal)),
);

double mix(double x, double y, double a) => x + (y - x) * a;
Vector2 mix2(Vector2 x, Vector2 y, double a) => x + (y - x) * a;
Vector3 mix3(Vector3 x, Vector3 y, double a) => x + (y - x) * a;
Vector4 mix4(Vector4 x, Vector4 y, double a) => x + (y - x) * a;

double step(double edge, double x) => x < edge ? 0.0 : 1.0;
double smoothstep(double edge0, double edge1, double x) {
  final t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

// Vector math
double length(dynamic v) {
  if (v is double) return v.abs();
  return (v as dynamic).length as double;
}

double distance(dynamic p0, dynamic p1) {
  if (p0 is double && p1 is double) return (p0 - p1).abs();
  return (p0 as dynamic).distanceTo(p1 as dynamic) as double;
}

double dot(dynamic x, dynamic y) {
  return (x as dynamic).dot(y as dynamic) as double;
}

Vector3 cross(Vector3 x, Vector3 y) {
  return x.cross(y);
}

dynamic normalize(dynamic x) {
  if (x is double) return x > 0 ? 1.0 : -1.0;
  return (x as dynamic).normalized();
}

/// Samples a texture using a sampler and coordinates.
Vector4 textureSample(Texture2d texture, SamplerState sampler, Vector2 coords) {
  return Vector4.zero();
}
