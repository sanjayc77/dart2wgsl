class ShaderStage {
  final String stage;
  const ShaderStage(this.stage);
}

/// Marks a function as a vertex shader entry point.
const vertex = ShaderStage('vertex');

/// Marks a function as a fragment shader entry point.
const fragment = ShaderStage('fragment');

/// Annotates a top-level uniform variable.
class Uniform {
  final int group;
  final int binding;
  const Uniform({required this.group, required this.binding});
}

/// Annotates a top-level 2D texture.
class Texture2D {
  final int group;
  final int binding;
  const Texture2D({required this.group, required this.binding});
}

/// Annotates a top-level sampler.
class Sampler {
  final int group;
  final int binding;
  const Sampler({required this.group, required this.binding});
}

/// Annotates a struct member location.
class Location {
  final int index;
  const Location(this.index);
}

/// Annotates a struct member representing a WebGPU builtin (e.g. 'position').
class Builtin {
  final String name;
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
