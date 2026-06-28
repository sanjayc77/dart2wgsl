# Restricted Dart for WGSL Specification

`dart2wgsl` compiles a subset of Dart into WebGPU Shading Language (WGSL). This document specifies the supported types, annotations, syntax, and restrictions of this dialect.

---

## 1. Supported Types

The transpiler maps Dart types to WGSL types:

| Dart Type | WGSL Type | Notes |
|---|---|---|
| `double` | `f32` | 32-bit floating point |
| `int` | `i32` | 32-bit signed integer |
| `bool` | `bool` | Boolean |
| `void` | `void` | Used for function returns |
| `Vector2` | `vec2<f32>` | From `package:vector_math/vector_math.dart` |
| `Vector3` | `vec3<f32>` | From `package:vector_math/vector_math.dart` |
| `Vector4` | `vec4<f32>` | From `package:vector_math/vector_math.dart` |
| `Matrix4` | `mat4x4<f32>` | From `package:vector_math/vector_math.dart` |
| *Custom Class* | *WGSL struct* | Class containing only fields (see below) |

---

## 2. Annotations

Annotations are used to specify WGSL-specific binding and location layouts.

### `@Uniform(group: int, binding: int)`
Annotates top-level `late final` variables. Maps to a global uniform buffer in WGSL.
```dart
@Uniform(group: 0, binding: 0)
late final double uTime;
```
Transpiles to:
```wgsl
@group(0) @binding(0) var<uniform> uTime: f32;
```

### `@Texture2D(group: int, binding: int)`
Annotates top-level `late final Texture2d` variables. Maps to `texture_2d<f32>` in WGSL.
```dart
@Texture2D(group: 0, binding: 1)
late final Texture2d uTexture;
```
Transpiles to:
```wgsl
@group(0) @binding(1) var uTexture: texture_2d<f32>;
```

### `@Sampler(group: int, binding: int)`
Annotates top-level `late final SamplerState` variables. Maps to `sampler` in WGSL.
```dart
@Sampler(group: 0, binding: 2)
late final SamplerState uSampler;
```
Transpiles to:
```wgsl
@group(0) @binding(2) var uSampler: sampler;
```

### `@Location(index: int)`
Annotates fields inside struct classes to set their shader location attributes.
```dart
class VertexInput {
  @Location(0)
  final Vector3 position;
}
```
Transpiles to:
```wgsl
struct VertexInput {
  @location(0) position: vec3<f32>,
}
```

### `@Builtin(name: String)`
Annotates fields inside struct classes representing WGSL built-in attributes (like `position` or `vertex_index`).
```dart
class VertexOutput {
  @Builtin('position')
  final Vector4 position;
}
```
Transpiles to:
```wgsl
struct VertexOutput {
  @builtin(position) position: vec4<f32>,
}
```

### `@vertex` and `@fragment`
Annotates top-level entry-point functions.
```dart
@vertex
VertexOutput vsMain(VertexInput input) { ... }
```
Transpiles to:
```wgsl
@vertex
fn vs_main(input: VertexInput) -> VertexOutput { ... }
```

---

## 3. Class Restrictions (Structs)

To represent WGSL structures, Dart classes are allowed but strictly limited:
- Must **not** define any methods.
- Must **not** extend other classes or use mixins.
- All fields must be `final` and belong to the supported type set.
- A simple constructor that maps arguments to fields is allowed.

---

## 4. Syntax & Code Restrictions

Inside shader functions, the following rules are enforced:
- **No Heap Allocation**: Banned `List`, `Map`, `Set`, `Queue`, or custom class instantiations (except structs and vector/matrix constructors).
- **No Recursion**: A function cannot call itself directly or indirectly.
- **Loop Restrictions**: Only standard `for` loops with compile-time constant bounds are allowed to prevent infinite loops on the GPU.
- **No Exceptions**: Banned `try`, `catch`, `finally`, `throw`.
- **Math built-ins**: Call built-ins through `package:dart2wgsl/stdlib.dart` which translates directly to WGSL equivalents.
- **Swizzling**: Field access on vectors (`v.xy`, `v.xyz`, `v.x`, `v.y`, etc.) is fully supported and transpiles directly.
