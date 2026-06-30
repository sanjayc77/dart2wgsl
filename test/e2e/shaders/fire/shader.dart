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

double rand(Vector2 n) {
  return fract(sin(cos(dot(n, Vector2(12.9898, 12.1414)))) * 83758.5453);
}

Vector2 floor2(Vector2 v) {
  return Vector2(floor(v.x), floor(v.y));
}

double noise(Vector2 n) {
  final d = Vector2(0.0, 1.0);
  var b = floor2(n);
  var fractN = fract2(n);
  var fx = smoothstep(0.0, 1.0, fractN.x);
  var fy = smoothstep(0.0, 1.0, fractN.y);
  
  var dYx = Vector2(d.y, d.x);
  var dXy = Vector2(d.x, d.y);
  var dYy = Vector2(d.y, d.y);

  return mix(
    mix(rand(b), rand(b + dYx), fx),
    mix(rand(b + dXy), rand(b + dYy), fx),
    fy
  );
}

double fbm(Vector2 n) {
  var total = 0.0;
  var amplitude = uResolution.x / uResolution.y * 0.5;
  var vn = n;
  for (var i = 0; i < 5; i++) {
    total += noise(vn) * amplitude;
    vn = vn + vn * 1.7;
    amplitude *= 0.47;
  }
  return total;
}

@fragment
Vector4 fsMain(VertexOutput input) {
  // c1 through c6 commented out since c is unused in the final color calculation
  // final c1 = Vector3(0.5, 0.0, 0.1);
  // final c2 = Vector3(0.9, 0.1, 0.0);
  // final c3 = Vector3(0.2, 0.1, 0.7);
  // final c4 = Vector3(1.0, 0.9, 0.1);
  // final c5 = Vector3(0.1, 0.1, 0.1);
  // final c6 = Vector3(0.9, 0.9, 0.9);

  var iTime = uTime;
  var fragCoord = Vector2(input.position.x, uResolution.y - input.position.y);
  var iResolution = uResolution;

  final speed = Vector2(0.1, 0.9);
  const alpha = 1.0;
    
  var dist = 3.5 - sin(iTime * 0.4) / 1.89;
    
  var p = fragCoord * dist * (1.0 / iResolution.x);
  p += sin2(Vector2(p.y, p.x) * 4.0 + Vector2(0.2, -0.3) * iTime) * 0.04;
  p += sin2(Vector2(p.y, p.x) * 8.0 + Vector2(0.6, 0.1) * iTime) * 0.01;
    
  p.x -= iTime / 1.1;

  var valQ = -iTime * 0.3 + 1.0 * sin(iTime + 0.5) / 2.0;
  var q = fbm(p + Vector2(valQ, valQ));

  var valQb = -iTime * 0.4 + 0.1 * cos(iTime) / 2.0;
  var qb = fbm(p + Vector2(valQb, valQb));

  var valQ2 = -iTime * 0.44 - 5.0 * cos(iTime) / 2.0;
  var q2 = fbm(p + Vector2(valQ2, valQ2)) - 6.0;

  var valQ3 = -iTime * 0.9 - 10.0 * cos(iTime) / 15.0;
  var q3 = fbm(p + Vector2(valQ3, valQ3)) - 4.0;

  var valQ4 = -iTime * 1.4 - 20.0 * sin(iTime) / 14.0;
  var q4 = fbm(p + Vector2(valQ4, valQ4)) + 2.0;

  q = (q + qb - 0.4 * q2 - 2.0 * q3 + 0.6 * q4) / 3.8;

  var valR1 = q / 2.0 + iTime * speed.x - p.x - p.y;
  var valR2 = q - iTime * speed.y;
  var r = Vector2(
    fbm(p + Vector2(valR1, valR1)),
    fbm(p + Vector2(valR2, valR2))
  );

  // var c = mix3(c1, c2, fbm(p + r)) + mix3(c3, c4, r.x) - mix3(c5, c6, r.y);
  
  var color = Vector3(1.0, 0.2, 0.05) * (1.0 / pow((r.y + r.y) * max(0.0, p.y) + 0.1, 4.0));
  
  color = Vector3(
    color.x / (1.0 + max(0.0, color.x)),
    color.y / (1.0 + max(0.0, color.y)),
    color.z / (1.0 + max(0.0, color.z))
  );

  return Vector4(color.x, color.y, color.z, alpha);
}
