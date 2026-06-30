export 'annotations.dart';
export 'stdlib.dart';
export 'src/transpiler.dart';
export 'src/validator.dart';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'src/transpiler.dart';
import 'src/validator.dart';

/// The result of transpiling a Dart shader to WGSL.
class TranspileResult {
  /// The generated WGSL code if the transpilation was successful, otherwise `null`.
  final String? wgsl;

  /// A list of validation errors encountered during validation or transpilation.
  final List<ValidationError> errors;

  /// Creates a new [TranspileResult] with the given [wgsl] and [errors].
  TranspileResult({this.wgsl, required this.errors});

  /// Whether the transpilation process encountered any errors.
  bool get hasErrors => errors.isNotEmpty;
}

/// Transpiles a Dart shader and its transitive custom imports from [registry] to WGSL.
///
/// - [rootUri]: The URI of the main shader entry point (e.g. `package:my_app/shader.dart`).
/// - [registry]: A map of absolute URIs to Dart source code strings.
TranspileResult transpileShader(String rootUri, Map<String, String> registry) {
  final parsedUnits = <String, CompilationUnit>{};
  final errors = <ValidationError>[];

  void parseRecursive(String uri) {
    if (parsedUnits.containsKey(uri)) return;

    final source = registry[uri];
    if (source == null) {
      errors.add(
        ValidationError(
          filePath: uri,
          line: 0,
          column: 0,
          message: 'Failed to resolve import: $uri',
        ),
      );
      return;
    }

    try {
      final result = parseString(content: source);
      final unit = result.unit;
      parsedUnits[uri] = unit;

      // Discover imports
      for (final directive in unit.directives) {
        if (directive is ImportDirective) {
          final importUri = directive.uri.stringValue;
          if (importUri == null) continue;

          // Skip system libraries
          if (importUri.contains('vector_math') ||
              importUri.contains('dart2wgsl/stdlib.dart') ||
              importUri.contains('dart2wgsl/annotations.dart')) {
            continue;
          }

          // Resolve relative URI relative to current unit's URI
          final resolvedUri = Uri.parse(uri).resolve(importUri).toString();
          parseRecursive(resolvedUri);
        }
      }
    } catch (e) {
      errors.add(
        ValidationError(
          filePath: uri,
          line: 0,
          column: 0,
          message: 'Syntax error during parsing: $e',
        ),
      );
    }
  }

  // Parse root and dependencies recursively
  parseRecursive(rootUri);

  if (errors.isNotEmpty) {
    return TranspileResult(wgsl: null, errors: errors);
  }

  // Set up unit to URI mapping for validator
  final unitUris = <CompilationUnit, String>{};
  final unitsList = <CompilationUnit>[];
  for (final entry in parsedUnits.entries) {
    unitUris[entry.value] = entry.key;
    unitsList.add(entry.value);
  }

  // Validate the parsed units
  final validationErrors = ShaderValidator.validate(
    unitsList,
    unitUris: unitUris,
  );
  if (validationErrors.isNotEmpty) {
    return TranspileResult(wgsl: null, errors: validationErrors);
  }

  // Transpile if validation passes
  try {
    final wgsl = ShaderTranspiler.transpile(unitsList);
    return TranspileResult(wgsl: wgsl, errors: []);
  } catch (e) {
    return TranspileResult(
      wgsl: null,
      errors: [
        ValidationError(
          filePath: rootUri,
          line: 0,
          column: 0,
          message: 'Transpilation failed: $e',
        ),
      ],
    );
  }
}
