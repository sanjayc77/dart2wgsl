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
class ShaderValidationVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<ValidationError> errors = [];
  final Set<String> declaredStructs;

  static const _allowedPrimitives = {'double', 'int', 'bool', 'void', 'Texture2d', 'SamplerState'};
  static const _allowedMathTypes = {'Vector2', 'Vector3', 'Vector4', 'Matrix4'};

  ShaderValidationVisitor(this.filePath, this.declaredStructs);

  void _addError(AstNode node, String message) {
    final lineInfo = node.root is CompilationUnit ? (node.root as CompilationUnit).lineInfo : null;
    int line = 0;
    int column = 0;
    if (lineInfo != null) {
      final loc = lineInfo.getLocation(node.offset);
      line = loc.lineNumber;
      column = loc.columnNumber;
    }
    errors.add(ValidationError(
      filePath: filePath,
      line: line,
      column: column,
      message: message,
    ));
  }

  bool _isTypeAllowed(DartType? type) {
    if (type == null) return false;
    final name = type.getDisplayString(withNullability: false);
    if (_allowedPrimitives.contains(name) || _allowedMathTypes.contains(name) || declaredStructs.contains(name)) {
      return true;
    }
    // Also handle vector/matrix types from vector_math package if they have full path
    if (name.contains('Vector') || name.contains('Matrix') || name.contains('Matrix4')) {
      return true;
    }
    return false;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;

    if (node.extendsClause != null) {
      _addError(node, 'Class "$className" cannot extend other classes. Shaders only support flat structs.');
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
        _addError(member, 'Methods are not supported in struct class "$className". Only fields are allowed.');
      } else if (member is FieldDeclaration) {
        if (!member.fields.isFinal) {
          _addError(member, 'Fields in struct class "$className" must be final.');
        }
      } else if (member is ConstructorDeclaration) {
        // Constructors should be simple initializers. We check that they have no body statements.
        if (member.body is BlockFunctionBody && (member.body as BlockFunctionBody).block.statements.isNotEmpty) {
          _addError(member, 'Struct constructor cannot contain statements/logic.');
        }
      } else {
        _addError(member, 'Unsupported member type in struct class "$className".');
      }
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addError(node, 'Methods are not supported in shader files. Use top-level functions.');
  }

  @override
  void visitTryStatement(TryStatement node) {
    _addError(node, 'Try/catch exception handling is not supported on the GPU.');
    super.visitTryStatement(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _addError(node, 'Throwing exceptions is not supported on the GPU.');
    super.visitThrowExpression(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _addError(node, 'While loops are not supported. Use standard for-loops with bounded limits.');
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _addError(node, 'Do-while loops are not supported. Use standard for-loops with bounded limits.');
    super.visitDoStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.forLoopParts is ForEachParts) {
      _addError(node, 'For-in/for-each loops are not supported. Use standard index-based for-loops.');
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
    final typeName = type?.getDisplayString(withNullability: false) ?? '';
    
    if (!_isTypeAllowed(type)) {
      _addError(node, 'Cannot instantiate "$typeName". Only math types (Vector2, Vector3, Vector4, Matrix4) and defined structs are allowed.');
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    final type = node.type?.type;
    if (node.type != null && !_isTypeAllowed(type)) {
      final typeName = node.type.toString();
      _addError(node, 'Type "$typeName" is not supported in shaders.');
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final returnType = node.returnType?.type;
    if (node.returnType != null && !_isTypeAllowed(returnType)) {
      _addError(node, 'Return type "${node.returnType}" is not supported.');
    }

    // Check parameter types
    final params = node.functionExpression.parameters;
    if (params != null) {
      for (final param in params.parameters) {
        final paramType = param.declaredElement?.type;
        if (!_isTypeAllowed(paramType)) {
          _addError(param, 'Parameter type "${param.declaredElement?.type}" is not supported.');
        }
      }
    }

    super.visitFunctionDeclaration(node);
  }
}

/// Helper class to coordinate validation across multiple units.
class ShaderValidator {
  static List<ValidationError> validate(List<CompilationUnit> units) {
    final declaredStructs = <String>{};

    // First pass: collect all struct names
    for (final unit in units) {
      for (final declaration in unit.declarations) {
        if (declaration is ClassDeclaration) {
          declaredStructs.add(declaration.name.lexeme);
        }
      }
    }

    final errors = <ValidationError>[];
    // Second pass: validate each AST
    for (final unit in units) {
      final filePath = unit.declaredElement?.source.fullName ?? 'unknown';
      final visitor = ShaderValidationVisitor(filePath, declaredStructs);
      unit.accept(visitor);
      errors.addAll(visitor.errors);
    }

    return errors;
  }
}
