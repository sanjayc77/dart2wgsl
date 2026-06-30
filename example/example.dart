import 'package:dart2wgsl/dart2wgsl.dart';

void main() {
  // A simple Dart shader representation
  const shaderSource = r'''
import 'package:vector_math/vector_math.dart';
import 'package:dart2wgsl/annotations.dart';

struct VertexOutput {
  @Builtin("position")
  Vector4 position;
}

@vertex
VertexOutput vsMain() {
  var out = VertexOutput();
  out.position = Vector4(0.0, 0.0, 0.0, 1.0);
  return out;
}
''';

  final registry = {'package:my_shader/shader.dart': shaderSource};

  final result = transpileShader('package:my_shader/shader.dart', registry);

  if (result.hasErrors) {
    print('Validation / Transpilation failed:');
    for (final error in result.errors) {
      print('  $error');
    }
  } else {
    print('Dart Shader:');
    print(shaderSource);

    print('WGSL Output:');
    print(result.wgsl);
  }
}
