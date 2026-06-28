import 'package:dart2wgsl/annotations.dart';
import 'package:dart2wgsl/stdlib.dart';
import 'package:vector_math/vector_math.dart';

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

@fragment
Vector4 fsMain(VertexOutput input) {
  // ShaderToy-style plasma effect
  var uv = input.uv;
  var color = Vector4(
    0.5 + 0.5 * sin(uTime + uv.x * 10.0),
    0.5 + 0.5 * cos(uTime + uv.y * 10.0),
    0.5 + 0.5 * sin(uTime + (uv.x + uv.y) * 5.0),
    1.0,
  );
  return color;
}
