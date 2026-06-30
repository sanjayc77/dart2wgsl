/// Represents a WebGPU shader stage (e.g., vertex, fragment).
class ShaderStage {
  /// The name of the shader stage.
  final String stage;

  /// Creates a new [ShaderStage] with the given stage name.
  const ShaderStage(this.stage);
}

/// Marks a function as a vertex shader entry point.
const vertex = ShaderStage('vertex');

/// Marks a function as a fragment shader entry point.
const fragment = ShaderStage('fragment');

/// Annotates a top-level uniform variable with its resource binding indices.
class Uniform {
  /// The resource bind group index.
  final int group;

  /// The binding index within the bind group.
  final int binding;

  /// Creates a [Uniform] annotation with the specified [group] and [binding] indices.
  const Uniform({required this.group, required this.binding});
}

/// Annotates a top-level 2D texture resource with its resource binding indices.
class Texture2D {
  /// The resource bind group index.
  final int group;

  /// The binding index within the bind group.
  final int binding;

  /// Creates a [Texture2D] annotation with the specified [group] and [binding] indices.
  const Texture2D({required this.group, required this.binding});
}

/// Annotates a top-level sampler resource with its resource binding indices.
class Sampler {
  /// The resource bind group index.
  final int group;

  /// The binding index within the bind group.
  final int binding;

  /// Creates a [Sampler] annotation with the specified [group] and [binding] indices.
  const Sampler({required this.group, required this.binding});
}

/// Annotates a struct member location.
class Location {
  /// The location index.
  final int index;

  /// Creates a [Location] annotation with the specified location [index].
  const Location(this.index);
}

/// Annotates a struct member representing a WebGPU builtin (e.g. 'position').
class Builtin {
  /// The name of the WebGPU builtin variable.
  final String name;

  /// Creates a [Builtin] annotation with the specified builtin [name].
  const Builtin(this.name);
}

/// Placeholder for a 2D texture resource in the Dart shader code.
class Texture2d {
  const Texture2d._();
}

/// Placeholder for a sampler resource in the Dart shader code.
class SamplerState {
  const SamplerState._();
}
