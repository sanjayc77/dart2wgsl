import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

int? getAnnotationIntArg(
  Annotation annotation,
  String name,
  int positionalIndex,
) {
  final args = annotation.arguments?.arguments;
  if (args == null) return null;
  for (final arg in args) {
    if (arg is NamedExpression && arg.name.label.name == name) {
      final expr = arg.expression;
      if (expr is IntegerLiteral) return expr.value;
    }
  }
  if (positionalIndex < args.length) {
    var arg = args[positionalIndex];
    if (arg is NamedExpression) {
      arg = arg.expression;
    }
    if (arg is IntegerLiteral) return arg.value;
  }
  return null;
}

String? getAnnotationStringArg(Annotation annotation, int positionalIndex) {
  final args = annotation.arguments?.arguments;
  if (args == null || positionalIndex >= args.length) return null;
  var arg = args[positionalIndex];
  if (arg is NamedExpression) {
    arg = arg.expression;
  }
  if (arg is SimpleStringLiteral) return arg.value;
  if (arg is StringLiteral) return arg.stringValue;
  return null;
}

class WgslTranspilerVisitor extends GeneralizingAstVisitor<String> {
  String _mapType(String dartType) {
    final clean = dartType.replaceAll('?', '').split('.').last;
    switch (clean) {
      case 'double':
        return 'f32';
      case 'int':
        return 'i32';
      case 'bool':
        return 'bool';
      case 'void':
        return 'void';
      case 'Vector2':
        return 'vec2<f32>';
      case 'Vector3':
        return 'vec3<f32>';
      case 'Vector4':
        return 'vec4<f32>';
      case 'Matrix4':
        return 'mat4x4<f32>';
      case 'Texture2d':
        return 'texture_2d<f32>';
      case 'SamplerState':
        return 'sampler';
      default:
        return clean;
    }
  }

  String _handlePropertyAccess(String target, String property) {
    if (property == 'length') {
      return 'length($target)';
    }
    return '$target.$property';
  }

  @override
  String visitClassDeclaration(ClassDeclaration node) {
    final structName = node.name.lexeme;
    final buffer = StringBuffer();
    buffer.writeln('struct $structName {');
    for (final member in node.members) {
      if (member is FieldDeclaration) {
        final typeStr = _mapType(member.fields.type?.toString() ?? 'f32');
        String attribs = '';
        for (final annotation in member.metadata) {
          final annName = annotation.name.name;
          if (annName == 'Location') {
            final loc = getAnnotationIntArg(annotation, 'index', 0);
            if (loc != null) {
              attribs += '@location($loc) ';
            }
          } else if (annName == 'Builtin') {
            final name = getAnnotationStringArg(annotation, 0);
            if (name != null) {
              attribs += '@builtin($name) ';
            }
          }
        }
        for (final variable in member.fields.variables) {
          buffer.writeln('  $attribs${variable.name.lexeme}: $typeStr,');
        }
      }
    }
    buffer.write('};');
    return buffer.toString();
  }

  @override
  String visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    final buffer = StringBuffer();
    for (final variable in node.variables.variables) {
      final varName = variable.name.lexeme;
      final rawType = node.variables.type?.toString() ?? '';
      final typeStr = _mapType(rawType);

      for (final annotation in node.metadata) {
        final annName = annotation.name.name;
        if (annName == 'Uniform') {
          final group = getAnnotationIntArg(annotation, 'group', 0) ?? 0;
          final binding = getAnnotationIntArg(annotation, 'binding', 1) ?? 0;
          buffer.write(
            '@group($group) @binding($binding) var<uniform> $varName: $typeStr;',
          );
          return buffer.toString();
        } else if (annName == 'Texture2D') {
          final group = getAnnotationIntArg(annotation, 'group', 0) ?? 0;
          final binding = getAnnotationIntArg(annotation, 'binding', 1) ?? 0;
          buffer.write(
            '@group($group) @binding($binding) var $varName: texture_2d<f32>;',
          );
          return buffer.toString();
        } else if (annName == 'Sampler') {
          final group = getAnnotationIntArg(annotation, 'group', 0) ?? 0;
          final binding = getAnnotationIntArg(annotation, 'binding', 1) ?? 0;
          buffer.write(
            '@group($group) @binding($binding) var $varName: sampler;',
          );
          return buffer.toString();
        }
      }
    }
    return '';
  }

  @override
  String visitFunctionDeclaration(FunctionDeclaration node) {
    final funcName = node.name.lexeme;
    String stageAttrib = '';
    bool isFragment = false;

    for (final annotation in node.metadata) {
      final name = annotation.name.name;
      if (name == 'vertex') {
        stageAttrib = '@vertex\n';
      } else if (name == 'fragment') {
        stageAttrib = '@fragment\n';
        isFragment = true;
      }
    }

    final paramsStr =
        node.functionExpression.parameters?.parameters
            .map((p) {
              String rawType = 'f32';
              if (p.declaredElement?.type != null) {
                rawType = p.declaredElement!.type.getDisplayString(
                  withNullability: false,
                );
              } else if (p is SimpleFormalParameter && p.type != null) {
                rawType = p.type!.toString();
              }
              final paramType = _mapType(rawType);
              final paramName = p.name?.lexeme ?? '';
              return '$paramName: $paramType';
            })
            .join(', ') ??
        '';

    final returnTypeRaw =
        node.returnType?.type?.getDisplayString(withNullability: false) ??
        node.returnType?.toString() ??
        'void';
    String returnTypeStr = _mapType(returnTypeRaw);

    if (isFragment && returnTypeStr != 'void' && returnTypeRaw == 'Vector4') {
      returnTypeStr = '-> @location(0) vec4<f32>';
    } else if (returnTypeStr != 'void') {
      returnTypeStr = '-> $returnTypeStr';
    } else {
      returnTypeStr = '';
    }

    final bodyStr = node.functionExpression.body.accept(this) ?? '{}';
    return '$stageAttrib\nfn $funcName($paramsStr) $returnTypeStr $bodyStr\n';
  }

  @override
  String visitBlockFunctionBody(BlockFunctionBody node) {
    return node.block.accept(this) ?? '{}';
  }

  @override
  String visitBlock(Block node) {
    final buffer = StringBuffer('{\n');
    for (final stmt in node.statements) {
      final val = stmt.accept(this);
      if (val != null) {
        buffer.writeln(val.split('\n').map((line) => '  $line').join('\n'));
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  @override
  String visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    final buffer = StringBuffer();
    for (final variable in node.variables.variables) {
      final name = variable.name.lexeme;
      final type = variable.declaredElement?.type;
      String? typeStr;
      if (type != null) {
        typeStr = _mapType(type.getDisplayString(withNullability: false));
      } else if (node.variables.type != null) {
        typeStr = _mapType(node.variables.type!.toString());
      }
      final typeAnnotation = typeStr != null ? ': $typeStr' : '';
      final init = variable.initializer != null
          ? ' = ${variable.initializer!.accept(this)}'
          : '';
      buffer.write('var $name$typeAnnotation$init;');
    }
    return buffer.toString();
  }

  @override
  String visitExpressionStatement(ExpressionStatement node) {
    return '${node.expression.accept(this)};';
  }

  @override
  String visitIfStatement(IfStatement node) {
    final cond = node.expression.accept(this);
    final thenBranch = node.thenStatement.accept(this);
    final elseBranch = node.elseStatement != null
        ? ' else ${node.elseStatement!.accept(this)}'
        : '';
    return 'if ($cond) $thenBranch$elseBranch';
  }

  @override
  String visitForStatement(ForStatement node) {
    final parts = node.forLoopParts;
    if (parts is ForParts) {
      String initStr = '';
      if (parts is ForPartsWithDeclarations) {
        initStr = parts.variables.accept(this) ?? '';
      } else if (parts is ForPartsWithExpression) {
        initStr = parts.initialization?.accept(this) ?? '';
      }
      final cleanInit = initStr.endsWith(';')
          ? initStr.substring(0, initStr.length - 1)
          : initStr;
      final condStr = parts.condition?.accept(this) ?? 'true';
      final updatersStr = parts.updaters.map((u) => u.accept(this)).join(', ');
      final body = node.body.accept(this) ?? '{}';
      return 'for ($cleanInit; $condStr; $updatersStr) $body';
    }
    return '// Unsupported for-in loop';
  }

  @override
  String visitReturnStatement(ReturnStatement node) {
    final expr = node.expression != null
        ? ' ${node.expression!.accept(this)}'
        : '';
    return 'return$expr;';
  }

  @override
  String visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide.accept(this);
    final right = node.rightHandSide.accept(this);
    final op = node.operator.lexeme;
    return '$left $op $right';
  }

  @override
  String visitBinaryExpression(BinaryExpression node) {
    final left = node.leftOperand.accept(this);
    final right = node.rightOperand.accept(this);
    final op = node.operator.lexeme;
    return '($left $op $right)';
  }

  @override
  String visitPrefixExpression(PrefixExpression node) {
    final operand = node.operand.accept(this);
    final op = node.operator.lexeme;
    return '$op$operand';
  }

  @override
  String visitPostfixExpression(PostfixExpression node) {
    final operand = node.operand.accept(this);
    final op = node.operator.lexeme;
    return '$operand$op';
  }

  @override
  String visitParenthesizedExpression(ParenthesizedExpression node) {
    return '(${node.expression.accept(this)})';
  }

  @override
  String visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final args = node.argumentList.arguments
        .map((e) => e.accept(this))
        .join(', ');

    // Fallback if vector constructors are parsed as method calls
    if (['Vector2', 'Vector3', 'Vector4', 'Matrix4'].contains(name)) {
      return '${_mapType(name)}($args)';
    }

    String mappedName = name;

    if (['sin2', 'sin3', 'sin4'].contains(name))
      mappedName = 'sin';
    else if (['cos2', 'cos3', 'cos4'].contains(name))
      mappedName = 'cos';
    else if (['tan2', 'tan3', 'tan4'].contains(name))
      mappedName = 'tan';
    else if (['fract2', 'fract3', 'fract4'].contains(name))
      mappedName = 'fract';
    else if (['clamp2', 'clamp3', 'clamp4'].contains(name))
      mappedName = 'clamp';
    else if (['mix2', 'mix3', 'mix4'].contains(name))
      mappedName = 'mix';

    if (node.target != null) {
      final targetStr = node.target!.accept(this);
      if (name == 'dot') {
        return 'dot($targetStr, $args)';
      } else if (name == 'cross') {
        return 'cross($targetStr, $args)';
      } else if (name == 'normalized') {
        return 'normalize($targetStr)';
      }
      return '$targetStr.$mappedName($args)';
    }

    return '$mappedName($args)';
  }

  @override
  String visitPropertyAccess(PropertyAccess node) {
    final target = node.target?.accept(this) ?? '';
    final property = node.propertyName.name;
    return _handlePropertyAccess(target, property);
  }

  @override
  String visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefix = node.prefix.name;
    final property = node.identifier.name;
    return _handlePropertyAccess(prefix, property);
  }

  @override
  String visitSimpleIdentifier(SimpleIdentifier node) {
    return node.name;
  }

  @override
  String visitInstanceCreationExpression(InstanceCreationExpression node) {
    final className = node.constructorName.type.name2.lexeme;
    final glslType = _mapType(className);
    final args = node.argumentList.arguments
        .map((e) => e.accept(this))
        .join(', ');
    return '$glslType($args)';
  }

  @override
  String visitConditionalExpression(ConditionalExpression node) {
    final cond = node.condition.accept(this);
    final thenExpr = node.thenExpression.accept(this);
    final elseExpr = node.elseExpression.accept(this);
    return 'select($elseExpr, $thenExpr, $cond)';
  }

  @override
  String visitIntegerLiteral(IntegerLiteral node) {
    return node.value.toString();
  }

  @override
  String visitDoubleLiteral(DoubleLiteral node) {
    final val = node.value.toString();
    return val.contains('.') ? val : '$val.0';
  }

  @override
  String visitBooleanLiteral(BooleanLiteral node) {
    return node.value.toString();
  }

  @override
  String visitNode(AstNode node) {
    return node.toSource();
  }
}

class ShaderTranspiler {
  static String transpile(List<CompilationUnit> units) {
    final structs = <String>[];
    final uniforms = <String>[];
    final functions = <String>[];

    final visitor = WgslTranspilerVisitor();

    for (final unit in units) {
      for (final decl in unit.declarations) {
        if (decl is ClassDeclaration) {
          structs.add(decl.accept(visitor)!);
        } else if (decl is TopLevelVariableDeclaration) {
          final res = decl.accept(visitor);
          if (res != null && res.isNotEmpty) {
            uniforms.add(res);
          }
        } else if (decl is FunctionDeclaration) {
          functions.add(decl.accept(visitor)!);
        }
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('// Generated by dart2wgsl. Do not modify.\n');

    if (structs.isNotEmpty) {
      buffer.writeln('// Structs');
      buffer.writeln(structs.join('\n\n'));
      buffer.writeln();
    }

    if (uniforms.isNotEmpty) {
      buffer.writeln('// Uniforms & Resources');
      buffer.writeln(uniforms.join('\n'));
      buffer.writeln();
    }

    if (functions.isNotEmpty) {
      buffer.writeln('// Functions');
      buffer.writeln(functions.join('\n'));
    }

    return buffer.toString();
  }
}
