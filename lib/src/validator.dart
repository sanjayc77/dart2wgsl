import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

class ValidationError {
  final String filePath;
  final int line;
  final int column;
  final String message;

  ValidationError({
    required this.filePath,
    required this.line,
    required this.column,
    required this.message,
  });

  @override
  String toString() => '$filePath:$line:$column: $message';
}

/// Visitor that validates a Dart AST unit for WGSL compatibility.
/// Visitor that validates a Dart AST unit for WGSL compatibility.
class ShaderValidationVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<ValidationError> errors = [];
  final Set<String> allowedTypes;
  final Set<String> allowedFunctions;

  static const _builtInMathFunctions = {
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'atan2',
    'sin2',
    'sin3',
    'sin4',
    'cos2',
    'cos3',
    'cos4',
    'tan2',
    'tan3',
    'tan4',
    'fract',
    'fract2',
    'fract3',
    'fract4',
    'clamp',
    'clamp2',
    'clamp3',
    'clamp4',
    'mix',
    'mix2',
    'mix3',
    'mix4',
    'dot',
    'cross',
    'normalized',
    'length',
    'distance',
    'pow',
    'exp',
    'log',
    'sqrt',
    'abs',
    'min',
    'max',
  };

  ShaderValidationVisitor(
    this.filePath,
    this.allowedTypes,
    this.allowedFunctions,
  );

  void _addError(AstNode node, String message) {
    final lineInfo = node.root is CompilationUnit
        ? (node.root as CompilationUnit).lineInfo
        : null;
    int line = 0;
    int column = 0;
    if (lineInfo != null) {
      final loc = lineInfo.getLocation(node.offset);
      line = loc.lineNumber;
      column = loc.columnNumber;
    }
    errors.add(
      ValidationError(
        filePath: filePath,
        line: line,
        column: column,
        message: message,
      ),
    );
  }

  bool _isTypeAllowed(DartType? type, [String? typeName]) {
    if (type != null) {
      final name = type.getDisplayString(withNullability: false);
      if (allowedTypes.contains(name)) return true;
      final clean = name.split('.').last;
      if (allowedTypes.contains(clean)) return true;
    }
    if (typeName != null) {
      final name = typeName.replaceAll('?', '').split('.').last;
      if (allowedTypes.contains(name)) return true;
    }
    return false;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;

    if (node.extendsClause != null) {
      _addError(
        node,
        'Class "$className" cannot extend other classes. Shaders only support flat structs.',
      );
    }
    if (node.withClause != null) {
      _addError(node, 'Class "$className" cannot use mixins.');
    }
    if (node.implementsClause != null) {
      _addError(node, 'Class "$className" cannot implement interfaces.');
    }

    // Traverse class members to ensure they are only fields or a simple constructor
    for (final member in node.members) {
      if (member is MethodDeclaration) {
        _addError(
          member,
          'Methods are not supported in struct class "$className". Only fields are allowed.',
        );
      } else if (member is FieldDeclaration) {
        if (!member.fields.isFinal) {
          _addError(
            member,
            'Fields in struct class "$className" must be final.',
          );
        }
      } else if (member is ConstructorDeclaration) {
        // Constructors should be simple initializers. We check that they have no body statements.
        if (member.body is BlockFunctionBody &&
            (member.body as BlockFunctionBody).block.statements.isNotEmpty) {
          _addError(
            member,
            'Struct constructor cannot contain statements/logic.',
          );
        }
      } else {
        _addError(
          member,
          'Unsupported member type in struct class "$className".',
        );
      }
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addError(
      node,
      'Methods are not supported in shader files. Use top-level functions.',
    );
  }

  @override
  void visitTryStatement(TryStatement node) {
    _addError(
      node,
      'Try/catch exception handling is not supported on the GPU.',
    );
    super.visitTryStatement(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _addError(node, 'Throwing exceptions is not supported on the GPU.');
    super.visitThrowExpression(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _addError(
      node,
      'While loops are not supported. Use standard for-loops with bounded limits.',
    );
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _addError(
      node,
      'Do-while loops are not supported. Use standard for-loops with bounded limits.',
    );
    super.visitDoStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.forLoopParts is ForEachParts) {
      _addError(
        node,
        'For-in/for-each loops are not supported. Use standard index-based for-loops.',
      );
    }
    super.visitForStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Flag anonymous functions / closures inside shader bodies
    if (node.parent is! FunctionDeclaration) {
      _addError(node, 'Anonymous closures/lambdas are not supported.');
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    final typeName =
        type?.getDisplayString(withNullability: false) ??
        node.constructorName.type.name2.lexeme;

    if (!_isTypeAllowed(type, typeName)) {
      _addError(
        node,
        'Cannot instantiate "$typeName". Only math types (Vector2, Vector3, Vector4, Matrix4) and defined structs are allowed.',
      );
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    final type = node.type?.type;
    final typeName = node.type?.toString();
    if (node.type != null && !_isTypeAllowed(type, typeName)) {
      _addError(node, 'Type "$typeName" is not supported/imported.');
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final returnType = node.returnType?.type;
    final returnTypeName = node.returnType?.toString();
    if (node.returnType != null &&
        !_isTypeAllowed(returnType, returnTypeName)) {
      _addError(node, 'Return type "$returnTypeName" is not supported.');
    }

    // Check parameter types
    final params = node.functionExpression.parameters;
    if (params != null) {
      for (final param in params.parameters) {
        final paramType = param.declaredElement?.type;
        final paramTypeName = (param is SimpleFormalParameter)
            ? param.type?.toString()
            : null;
        if (!_isTypeAllowed(paramType, paramTypeName)) {
          final display =
              paramTypeName ??
              param.declaredElement?.type.toString() ??
              'unknown';
          _addError(
            param,
            'Parameter type "$display" is not supported/imported.',
          );
        }
      }
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;

    // Vector Math / Stdlib built-in check
    if (_builtInMathFunctions.contains(name) ||
        ['Vector2', 'Vector3', 'Vector4', 'Matrix4'].contains(name)) {
      if (!allowedTypes.contains('Vector2')) {
        _addError(
          node,
          'Math function or type "$name" requires importing "package:vector_math/vector_math.dart" or "package:dart2wgsl/stdlib.dart".',
        );
      }
    } else if (allowedTypes.contains(name)) {
      // Allowed as a constructor call to a custom struct type (e.g. CommonStruct(1.0))
    } else if (node.target == null) {
      // Top-level custom function call (e.g. addVectors(a, b))
      if (!allowedFunctions.contains(name)) {
        _addError(node, 'Function "$name" is not defined/imported.');
      }
    }

    super.visitMethodInvocation(node);
  }
}

/// Helper class to coordinate validation across multiple units.
class ShaderValidator {
  static List<ValidationError> validate(
    List<CompilationUnit> units, {
    Map<CompilationUnit, String>? unitUris,
    Map<CompilationUnit, Set<String>>? unitAllowedTypes,
    Map<CompilationUnit, Set<String>>? unitAllowedFunctions,
  }) {
    final errors = <ValidationError>[];

    // Compute URIs if not provided
    final uris = <CompilationUnit, String>{};
    final uriToUnit = <String, CompilationUnit>{};
    for (final unit in units) {
      final uri =
          unitUris?[unit] ??
          unit.declaredElement?.source.uri.toString() ??
          unit.declaredElement?.source.fullName ??
          'unknown_${unit.hashCode}';
      uris[unit] = uri;
      uriToUnit[uri] = unit;
    }

    // First pass: collect declared structs and functions in each unit
    final unitDeclaredStructs = <String, Set<String>>{};
    final unitDeclaredFunctions = <String, Set<String>>{};

    for (final entry in uriToUnit.entries) {
      final uri = entry.key;
      final unit = entry.value;
      final structs = <String>{};
      final functions = <String>{};

      for (final decl in unit.declarations) {
        if (decl is ClassDeclaration) {
          structs.add(decl.name.lexeme);
        } else if (decl is FunctionDeclaration) {
          functions.add(decl.name.lexeme);
        }
      }
      unitDeclaredStructs[uri] = structs;
      unitDeclaredFunctions[uri] = functions;
    }

    // Second pass: run validation on each unit
    for (final unit in units) {
      final uri = uris[unit]!;

      // Determine allowed types and functions for this unit
      Set<String> allowedTypes;
      Set<String> allowedFunctions;

      if (unitAllowedTypes != null && unitAllowedTypes.containsKey(unit)) {
        allowedTypes = unitAllowedTypes[unit]!;
      } else {
        allowedTypes = {'double', 'int', 'bool', 'void'};
        bool hasVectorMath = false;

        // Traverse imports to resolve allowed types
        for (final directive in unit.directives) {
          if (directive is ImportDirective) {
            final importUri = directive.uri.stringValue;
            if (importUri == null) continue;

            if (importUri.contains('vector_math') ||
                importUri.contains('dart2wgsl/stdlib.dart') ||
                importUri.contains('dart2wgsl/annotations.dart')) {
              hasVectorMath = true;
            }

            // Resolve import relative to current unit's URI
            final resolvedUri = Uri.parse(uri).resolve(importUri).toString();
            final importedStructs = unitDeclaredStructs[resolvedUri];
            if (importedStructs != null) {
              allowedTypes.addAll(importedStructs);
            }
          }
        }

        if (hasVectorMath) {
          allowedTypes.addAll([
            'Vector2',
            'Vector3',
            'Vector4',
            'Matrix4',
            'Texture2d',
            'SamplerState',
          ]);
        }

        // Add locally declared structs
        final localStructs = unitDeclaredStructs[uri];
        if (localStructs != null) {
          allowedTypes.addAll(localStructs);
        }
      }

      if (unitAllowedFunctions != null &&
          unitAllowedFunctions.containsKey(unit)) {
        allowedFunctions = unitAllowedFunctions[unit]!;
      } else {
        allowedFunctions = <String>{};

        // Traverse imports to resolve allowed functions
        for (final directive in unit.directives) {
          if (directive is ImportDirective) {
            final importUri = directive.uri.stringValue;
            if (importUri == null) continue;

            // Resolve import relative to current unit's URI
            final resolvedUri = Uri.parse(uri).resolve(importUri).toString();
            final importedFunctions = unitDeclaredFunctions[resolvedUri];
            if (importedFunctions != null) {
              allowedFunctions.addAll(importedFunctions);
            }
          }
        }

        // Add locally declared functions
        final localFunctions = unitDeclaredFunctions[uri];
        if (localFunctions != null) {
          allowedFunctions.addAll(localFunctions);
        }
      }

      final visitor = ShaderValidationVisitor(
        uri,
        allowedTypes,
        allowedFunctions,
      );
      unit.accept(visitor);
      errors.addAll(visitor.errors);
    }

    return errors;
  }
}
