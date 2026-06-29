import 'package:test/test.dart';
import 'package:dart2wgsl/dart2wgsl.dart';

void main() {
  group('Dynamic Transpilation API Tests', () {
    test('transpiles stitched files successfully', () {
      final registry = {
        'package:my_project/shader.dart': '''
import 'package:vector_math/vector_math.dart';
import 'math.dart';

@Uniform(group: 0, binding: 0)
late final Vector2 uResolution;

@fragment
Vector4 fsMain() {
  var x = Vector2(1.0, 2.0);
  var y = addVectors(x, x);
  return Vector4(y.x, y.y, 0.0, 1.0);
}
''',
        'package:my_project/math.dart': '''
import 'package:vector_math/vector_math.dart';
Vector2 addVectors(Vector2 a, Vector2 b) {
  return a + b;
}
''',
      };

      final result = transpileShader(
        'package:my_project/shader.dart',
        registry,
      );

      expect(result.hasErrors, isFalse);
      expect(result.wgsl, isNotNull);

      // Verify that local variable type inference generated code without type annotations:
      // i.e., "var x = vec2<f32>(1.0, 2.0);" instead of "var x: vec2<f32> = ...;"
      expect(result.wgsl, contains('var x = vec2<f32>'));
      expect(result.wgsl, contains('var y = addVectors'));
      expect(result.wgsl, contains('fn addVectors'));
      expect(result.wgsl, contains('fn fsMain'));
    });

    test('fails when custom imports are missing from registry', () {
      final registry = {
        'package:my_project/shader.dart': '''
import 'package:vector_math/vector_math.dart';
import 'missing_math.dart';

@fragment
Vector4 fsMain() {
  return Vector4(0.0, 0.0, 0.0, 1.0);
}
''',
      };

      final result = transpileShader(
        'package:my_project/shader.dart',
        registry,
      );

      expect(result.hasErrors, isTrue);
      expect(
        result.errors.any(
          (e) => e.message.contains('Failed to resolve import'),
        ),
        isTrue,
      );
    });

    test('fails when using unregistered/unsupported types', () {
      final registry = {
        'package:my_project/shader.dart': '''
import 'package:vector_math/vector_math.dart';

@fragment
Vector4 fsMain() {
  final BadType x = BadType();
  return Vector4(0.0, 0.0, 0.0, 1.0);
}
''',
      };

      final result = transpileShader(
        'package:my_project/shader.dart',
        registry,
      );

      expect(result.hasErrors, isTrue);
      expect(
        result.errors.any(
          (e) => e.message.contains('Type "BadType" is not supported/imported'),
        ),
        isTrue,
      );
    });

    test(
      'fails when using math types or functions without importing vector_math/stdlib',
      () {
        final registry = {
          'package:my_project/shader.dart': '''
@fragment
Vector4 fsMain() {
  var val = sin(1.0);
  return Vector4(0.0, 0.0, 0.0, 1.0);
}
''',
        };

        final result = transpileShader(
          'package:my_project/shader.dart',
          registry,
        );

        expect(result.hasErrors, isTrue);
        expect(
          result.errors.any(
            (e) => e.message.contains(
              'Math function or type "sin" requires importing',
            ),
          ),
          isTrue,
        );
        expect(
          result.errors.any(
            (e) => e.message.contains('Return type "Vector4" is not supported'),
          ),
          isTrue,
        );
      },
    );

    test('safely handles circular imports without infinite loops', () {
      final registry = {
        'package:my_project/shader.dart': '''
import 'package:vector_math/vector_math.dart';
import 'common.dart';

@fragment
Vector4 fsMain() {
  final CommonStruct c = CommonStruct(1.0);
  return Vector4(c.value, 0.0, 0.0, 1.0);
}
''',
        'package:my_project/common.dart': '''
import 'package:vector_math/vector_math.dart';
import 'shader.dart';

class CommonStruct {
  final double value;
  CommonStruct(this.value);
}
''',
      };

      final result = transpileShader(
        'package:my_project/shader.dart',
        registry,
      );

      expect(result.hasErrors, isFalse);
      expect(result.wgsl, contains('struct CommonStruct'));
      expect(result.wgsl, contains('fn fsMain'));
    });

    test('correctly resolves relative URIs', () {
      final registry = {
        'package:my_project/shaders/shader.dart': '''
import 'package:vector_math/vector_math.dart';
import '../utils/math.dart';

@fragment
Vector4 fsMain() {
  var x = add(1.0, 2.0);
  return Vector4(x, 0.0, 0.0, 1.0);
}
''',
        'package:my_project/utils/math.dart': '''
double add(double a, double b) {
  return a + b;
}
''',
      };

      final result = transpileShader(
        'package:my_project/shaders/shader.dart',
        registry,
      );

      expect(result.hasErrors, isFalse);
      expect(result.wgsl, contains('fn add'));
      expect(result.wgsl, contains('fn fsMain'));
    });
  });
}
