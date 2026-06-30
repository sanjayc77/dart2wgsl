import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:dart2wgsl/src/parser.dart';
import 'package:dart2wgsl/src/validator.dart';
import 'package:dart2wgsl/src/transpiler.dart';

void main() {
  String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  group('Golden Tests', () {
    test('transpiles simple.dart to simple.wgsl', () async {
      final inputPath = p.join('test', 'goldens', 'simple.dart');
      final goldenPath = p.join('test', 'goldens', 'simple.wgsl');

      final rootLibrary = await resolveFile(inputPath);
      final units = await crawlLibraryAsts(rootLibrary);

      // Verify no validation errors
      final errors = ShaderValidator.validate(units);
      expect(errors, isEmpty);

      // Transpile and compare
      final transpiled = ShaderTranspiler.transpile(units);
      final expected = await File(goldenPath).readAsString();

      expect(
        normalizeWhitespace(transpiled),
        equals(normalizeWhitespace(expected)),
      );
    });
  });

  group('Validator Tests', () {
    test('catches methods inside classes', () async {
      final path = p.join('test', 'invalid', 'class_method.dart');
      final rootLibrary = await resolveFile(path);
      final units = await crawlLibraryAsts(rootLibrary);

      final errors = ShaderValidator.validate(units);
      expect(errors, isNotEmpty);
      expect(
        errors.any(
          (e) =>
              e.message.contains('Methods are not supported in struct class'),
        ),
        isTrue,
      );
    });

    test('catches try-catch statements', () async {
      final path = p.join('test', 'invalid', 'try_catch.dart');
      final rootLibrary = await resolveFile(path);
      final units = await crawlLibraryAsts(rootLibrary);

      final errors = ShaderValidator.validate(units);
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.message.contains('exception handling')),
        isTrue,
      );
    });

    test('catches unsupported types (List)', () async {
      final path = p.join('test', 'invalid', 'invalid_type.dart');
      final rootLibrary = await resolveFile(path);
      final units = await crawlLibraryAsts(rootLibrary);

      final errors = ShaderValidator.validate(units);
      expect(errors, isNotEmpty);
      expect(
        errors.any(
          (e) =>
              e.message.contains('List') || e.message.contains('not supported'),
        ),
        isTrue,
      );
    });
  });
}
