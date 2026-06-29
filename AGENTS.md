# Antigravity Developer Instructions: `dart2wgsl`

This document serves as the orientation guide, behavioral rules, and architectural memory for any agent session working on `dart2wgsl`.

## Project Description

`dart2wgsl` is a compiler/transpiler written in Dart that compiles a highly restricted, strongly typed subset of Dart code into WebGPU Shading Language (WGSL). This allows developers to write WebGPU shaders (vertex and fragment) directly in Dart, achieving type-safety, standard import/dependency stitching, and IDE autocomplete, without losing the ability to hot-reload shaders during GPU application development.

### Core Architecture

```
[Shader .shader.dart Files]
       │
       ▼ (Deterministic crawling using analyzer)
[Dart Analyzer AST Resolver]
       │
       ▼ (Validates constraints: no OO, no lists, correct types)
[ShaderValidationVisitor]
       │
       ▼ (Translates functions, vars, structs, swizzles, math)
[WgslTranspilerVisitor]
       │
       ▼ (build_runner / CLI)
[.wgsl.dart File with String Constant]
```

## DOs and DONTs

### DOs
- **Maintain Determinism**: Always use pure AST transformation for compilation. Avoid utilizing LLMs for the build-time compilation path. LLMs are only acceptable for generating offline assets (like goldens) or testing support.
- **Strict AST Validation**: Fail early with clear, line-numbered compile errors when a banned Dart construct is used (e.g. classes with methods, try/catch, dynamic types, lists).
- **Format Output Nicely**: Generate clean, readable WGSL code with proper indentation, standard headers, and clear struct layouts.
- **Keep Math Shared**: Ensure that the signatures in `lib/stdlib.dart` compile and execute correctly on the CPU so that CPU-side logic can import the same files.
- **Reference Goldens**: Add tests in `test/goldens/` for new language features to ensure no regressions in transpilation output.

### DONTs
- **No Class Methods**: Do not allow classes to have methods or logic. Classes must only represent plain data structures (structs).
- **No Heap Allocations**: Ban `List`, `Map`, `Set`, and standard constructors except vector/matrix constructors (`Vector2`, `Vector3`, `Vector4`, `Matrix4`) inside shader bodies.
- **No Recursion**: Enforce a strict ban on recursive calls.
- **No Unused Imports in Generated Output**: Ensure that imports like `package:dart2wgsl/annotations.dart` or `package:vector_math/vector_math.dart` are stripped from the transpiled output.

## Work in Progress (WIP)
- Implementing Step 4: `test/goldens/` testing harness.

## Completed Work
- **Step 1**: Base project setup, annotations, stdlib, and specifications.
- **Step 2**: Validation and transpiler visitors.
- **Step 3**: CLI and Custom `build_runner` Builder.
- **Step 4 (Part 2)**: Fully functional `example/shadertoy` WebGPU Flutter Web application.

## Planned Work
- Finish Step 4: Implement the `test/goldens/` testing harness to protect the compiler against code generation regressions.
