import 'package:dart2wgsl/annotations.dart';
import 'package:dart2wgsl/stdlib.dart';
import 'package:vector_math/vector_math.dart' hide mix;

class VertexInput {
  @Location(0)
  final Vector3 position;
  @Location(1)
  final Vector2 uv;

  VertexInput(this.position, this.uv);
}

class VertexOutput {
  @Builtin('position')
  final Vector4 position;
  @Location(0)
  final Vector2 uv;

  VertexOutput(this.position, this.uv);
}

@Uniform(group: 0, binding: 0)
late final double uTime;

@Uniform(group: 0, binding: 1)
late final Vector2 uResolution;

@vertex
VertexOutput vsMain(VertexInput input) {
  var out = VertexOutput(
    Vector4(input.position.x, input.position.y, input.position.z, 1.0),
    input.uv,
  );
  return out;
}

Vector3 mul3(Vector3 v1, Vector3 v2) {
  return Vector3(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z);
}

Vector3 palette(double t) {
  final a = Vector3(0.5, 0.5, 0.5);
  final b = Vector3(0.5, 0.5, 0.5);
  final c = Vector3(1.0, 1.0, 1.0);
  final d = Vector3(0.263, 0.416, 0.557);
  var cosVal = cos3((c * t + d) * 6.28318);
  return a + mul3(b, cosVal);
}

@fragment
Vector4 fsMain(VertexOutput input) {
  var uv =
      (Vector2(input.position.x, input.position.y) * 2.0 - uResolution) *
      (1.0 / uResolution.y);
  final uv0 = uv;
  var finalColor = Vector3(0.0, 0.0, 0.0);

  for (var i = 0; i < 4; i++) {
    uv = fract2(uv * 1.5) - Vector2(0.5, 0.5);

    var d = length(uv) * exp(-length(uv0));

    var col = palette(length(uv0) + toF32(i) * 0.4 + uTime * 0.4);

    d = sin(d * 8.0 + uTime) / 8.0;
    d = abs(d);

    d = pow(0.01 / d, 1.2);

    finalColor += col * d;
  }

  return Vector4(finalColor.x, finalColor.y, finalColor.z, 1.0);
}
