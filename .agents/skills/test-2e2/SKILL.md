---
name: test-2e2
description: Seeding a new WGSL shader for E2E testing and running it with the example app.
---

# E2E Shader Seeding and Running Skill

This skill handles:
1. Seeding a WGSL shader using `/test-2e2 <nameofshader>` followed by the WGSL code.
2. Swapping the active shader in `example/shadertoy` with `/run-shadertoy <nameofshader>` and rebuilding it.

## Seeding Workflow (`/test-2e2 <nameofshader>`)

When the user runs `/test-2e2 <nameofshader>` along with a WGSL block:
1. **Save Original WGSL**: Write the provided WGSL code block to `test/e2e/shaders/<nameofshader>/original.wgsl`.
2. **Translate to Dart**:
   - Translate the WGSL code to Dart. Use the annotations and types from `package:dart2wgsl/annotations.dart`, `package:dart2wgsl/stdlib.dart`, and `package:vector_math/vector_math.dart`.
   - Ensure all functions, structs, variables, and math operations comply with the restricted language dialect (no class methods, proper constructors, correct imports).
   - Write this Dart shader code to `test/e2e/shaders/<nameofshader>/shader.dart`.
3. **Notify**: Report back to the user that both `original.wgsl` and `shader.dart` have been created.

## Run in Shadertoy Workflow (`/run-shadertoy <nameofshader>`)

When the user asks to run a shader in the shadertoy example (e.g. using `/run-shadertoy <nameofshader>` or "run <nameofshader> in shadertoy"):
1. **Copy to Example App**:
   - Copy `test/e2e/shaders/<nameofshader>/shader.dart` to `example/shadertoy/lib/shaders/toy.shader.dart` (overwrite it).
2. **Compile Shader**:
   - Run `dart run build_runner build` inside `/Users/sanjay/work/dart-projects/dart2wgsl/example/shadertoy/` to compile the new shader.
3. **Notify**: Report that `toy.shader.dart` has been updated and compiled.
