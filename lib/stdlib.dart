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
Vector4 sin4(Vector4 v) =>
    Vector4(math.sin(v.x), math.sin(v.y), math.sin(v.z), math.sin(v.w));

Vector2 cos2(Vector2 v) => Vector2(math.cos(v.x), math.cos(v.y));
Vector3 cos3(Vector3 v) => Vector3(math.cos(v.x), math.cos(v.y), math.cos(v.z));
Vector4 cos4(Vector4 v) =>
    Vector4(math.cos(v.x), math.cos(v.y), math.cos(v.z), math.cos(v.w));

Vector2 tan2(Vector2 v) => Vector2(math.tan(v.x), math.tan(v.y));
Vector3 tan3(Vector3 v) => Vector3(math.tan(v.x), math.tan(v.y), math.tan(v.z));
Vector4 tan4(Vector4 v) =>
    Vector4(math.tan(v.x), math.tan(v.y), math.tan(v.z), math.tan(v.w));

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

Vector2 fract2(Vector2 v) =>
    Vector2(v.x - v.x.floorToDouble(), v.y - v.y.floorToDouble());
Vector3 fract3(Vector3 v) => Vector3(
  v.x - v.x.floorToDouble(),
  v.y - v.y.floorToDouble(),
  v.z - v.z.floorToDouble(),
);
Vector4 fract4(Vector4 v) => Vector4(
  v.x - v.x.floorToDouble(),
  v.y - v.y.floorToDouble(),
  v.z - v.z.floorToDouble(),
  v.w - v.w.floorToDouble(),
);

double min(double x, double y) => math.min(x, y);
double max(double x, double y) => math.max(x, y);
double clamp(double x, double minVal, double maxVal) =>
    math.max(minVal, math.min(x, maxVal));

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

// Hyperbolic trigonometric functions
double sinh(double x) => (math.exp(x) - math.exp(-x)) / 2.0;
double cosh(double x) => (math.exp(x) + math.exp(-x)) / 2.0;
double tanh(double x) => sinh(x) / cosh(x);
double asinh(double x) => math.log(x + math.sqrt(x * x + 1.0));
double acosh(double x) => math.log(x + math.sqrt(x * x - 1.0));
double atanh(double x) => 0.5 * math.log((1.0 + x) / (1.0 - x));

Vector2 sinh2(Vector2 v) => Vector2(sinh(v.x), sinh(v.y));
Vector3 sinh3(Vector3 v) => Vector3(sinh(v.x), sinh(v.y), sinh(v.z));
Vector4 sinh4(Vector4 v) => Vector4(sinh(v.x), sinh(v.y), sinh(v.z), sinh(v.w));

Vector2 cosh2(Vector2 v) => Vector2(cosh(v.x), cosh(v.y));
Vector3 cosh3(Vector3 v) => Vector3(cosh(v.x), cosh(v.y), cosh(v.z));
Vector4 cosh4(Vector4 v) => Vector4(cosh(v.x), cosh(v.y), cosh(v.z), cosh(v.w));

Vector2 tanh2(Vector2 v) => Vector2(tanh(v.x), tanh(v.y));
Vector3 tanh3(Vector3 v) => Vector3(tanh(v.x), tanh(v.y), tanh(v.z));
Vector4 tanh4(Vector4 v) => Vector4(tanh(v.x), tanh(v.y), tanh(v.z), tanh(v.w));

Vector2 asinh2(Vector2 v) => Vector2(asinh(v.x), asinh(v.y));
Vector3 asinh3(Vector3 v) => Vector3(asinh(v.x), asinh(v.y), asinh(v.z));
Vector4 asinh4(Vector4 v) => Vector4(asinh(v.x), asinh(v.y), asinh(v.z), asinh(v.w));

Vector2 acosh2(Vector2 v) => Vector2(acosh(v.x), acosh(v.y));
Vector3 acosh3(Vector3 v) => Vector3(acosh(v.x), acosh(v.y), acosh(v.z));
Vector4 acosh4(Vector4 v) => Vector4(acosh(v.x), acosh(v.y), acosh(v.z), acosh(v.w));

Vector2 atanh2(Vector2 v) => Vector2(atanh(v.x), atanh(v.y));
Vector3 atanh3(Vector3 v) => Vector3(atanh(v.x), atanh(v.y), atanh(v.z));
Vector4 atanh4(Vector4 v) => Vector4(atanh(v.x), atanh(v.y), atanh(v.z), atanh(v.w));

// Saturate
double saturate(double x) => clamp(x, 0.0, 1.0);
Vector2 saturate2(Vector2 v) => clamp2(v, 0.0, 1.0);
Vector3 saturate3(Vector3 v) => clamp3(v, 0.0, 1.0);
Vector4 saturate4(Vector4 v) => clamp4(v, 0.0, 1.0);

// Fused Multiply-Add
double fma(double x, double y, double z) => x * y + z;
Vector2 fma2(Vector2 x, Vector2 y, Vector2 z) => Vector2(x.x * y.x + z.x, x.y * y.y + z.y);
Vector3 fma3(Vector3 x, Vector3 y, Vector3 z) => Vector3(x.x * y.x + z.x, x.y * y.y + z.y, x.z * y.z + z.z);
Vector4 fma4(Vector4 x, Vector4 y, Vector4 z) => Vector4(x.x * y.x + z.x, x.y * y.y + z.y, x.z * y.z + z.z, x.w * y.w + z.w);

// Reflection & Refraction
Vector2 reflect2(Vector2 i, Vector2 n) => i - n * (2.0 * dot(i, n));
Vector3 reflect3(Vector3 i, Vector3 n) => i - n * (2.0 * dot(i, n));
Vector4 reflect4(Vector4 i, Vector4 n) => i - n * (2.0 * dot(i, n));

dynamic reflect(dynamic i, dynamic n) {
  if (i is Vector2) return reflect2(i, n as Vector2);
  if (i is Vector3) return reflect3(i, n as Vector3);
  if (i is Vector4) return reflect4(i, n as Vector4);
  return i;
}

Vector2 refract2(Vector2 i, Vector2 n, double eta) {
  final d = dot(i, n);
  final k = 1.0 - eta * eta * (1.0 - d * d);
  if (k < 0.0) return Vector2(0.0, 0.0);
  return i * eta - n * (eta * d + math.sqrt(k));
}

Vector3 refract3(Vector3 i, Vector3 n, double eta) {
  final d = dot(i, n);
  final k = 1.0 - eta * eta * (1.0 - d * d);
  if (k < 0.0) return Vector3(0.0, 0.0, 0.0);
  return i * eta - n * (eta * d + math.sqrt(k));
}

Vector4 refract4(Vector4 i, Vector4 n, double eta) {
  final d = dot(i, n);
  final k = 1.0 - eta * eta * (1.0 - d * d);
  if (k < 0.0) return Vector4(0.0, 0.0, 0.0, 0.0);
  return i * eta - n * (eta * d + math.sqrt(k));
}

dynamic refract(dynamic i, dynamic n, double eta) {
  if (i is Vector2) return refract2(i, n as Vector2, eta);
  if (i is Vector3) return refract3(i, n as Vector3, eta);
  if (i is Vector4) return refract4(i, n as Vector4, eta);
  return i;
}

// Derivatives
double dpdx(double x) => 0.0;
double dpdy(double x) => 0.0;
double fwidth(double x) => 0.0;

Vector2 dpdx2(Vector2 v) => Vector2(0.0, 0.0);
Vector2 dpdy2(Vector2 v) => Vector2(0.0, 0.0);
Vector2 fwidth2(Vector2 v) => Vector2(0.0, 0.0);

Vector3 dpdx3(Vector3 v) => Vector3(0.0, 0.0, 0.0);
Vector3 dpdy3(Vector3 v) => Vector3(0.0, 0.0, 0.0);
Vector3 fwidth3(Vector3 v) => Vector3(0.0, 0.0, 0.0);

Vector4 dpdx4(Vector4 v) => Vector4(0.0, 0.0, 0.0, 0.0);
Vector4 dpdy4(Vector4 v) => Vector4(0.0, 0.0, 0.0, 0.0);
Vector4 fwidth4(Vector4 v) => Vector4(0.0, 0.0, 0.0, 0.0);

// Type casting helpers
double toF32(num value) => value.toDouble();
int toI32(num value) => value.toInt();
int toU32(num value) => value.toInt();


