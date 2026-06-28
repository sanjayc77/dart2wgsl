import 'dart:io';
import 'dart:typed_data';
import 'package:wgpu/wgpu.dart';
import 'shaders/toy.wgsl.dart';

void main() async {
  print('--- Dart2WGSL ShaderToy Standalone Render ---');

  const width = 80;
  const height = 40;

  print('Initializing WebGPU...');
  final instance = Wgpu.create();
  final adapter = await instance.requestAdapter();
  final device = await adapter.requestDevice();
  final queue = device.queue;

  print('Compiling WGSL shader...');
  // Import our statically compiled shader from toy.wgsl.dart!
  final shaderModule = device.createShaderModule(toyShader);

  // Define vertices for a full-screen quad (two triangles)
  // Vertex positions: X, Y, Z,  UV: U, V
  final vertices = Float32List.fromList([
    -1.0,  1.0, 0.0,  0.0, 0.0, // Top-Left
    -1.0, -1.0, 0.0,  0.0, 1.0, // Bottom-Left
     1.0, -1.0, 0.0,  1.0, 1.0, // Bottom-Right

    -1.0,  1.0, 0.0,  0.0, 0.0, // Top-Left
     1.0, -1.0, 0.0,  1.0, 1.0, // Bottom-Right
     1.0,  1.0, 0.0,  1.0, 0.0, // Top-Right
  ]);

  final vertexBuffer = device.createBuffer(
    size: vertices.lengthInBytes,
    usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
  );
  queue.writeBufferTyped(vertexBuffer, vertices);

  // Setup Uniforms: Time and Resolution as separate buffers
  // to avoid WebGPU's 256-byte offset alignment requirements.
  final timeData = Float32List.fromList([2.5, 0.0]); // 8 bytes
  final timeBuffer = device.createBuffer(
    size: timeData.lengthInBytes,
    usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
  );
  queue.writeBufferTyped(timeBuffer, timeData);

  final resolutionData = Float32List.fromList([width.toDouble(), height.toDouble()]); // 8 bytes
  final resolutionBuffer = device.createBuffer(
    size: resolutionData.lengthInBytes,
    usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
  );
  queue.writeBufferTyped(resolutionBuffer, resolutionData);

  // Create Bind Group for Uniforms
  final bindGroupLayout = device.createBindGroupLayout([
    const GpuBindGroupLayoutEntry.buffer(
      binding: 0,
      visibility: GpuShaderStage.fragment,
      type: GpuBufferBindingType.uniform,
    ),
    const GpuBindGroupLayoutEntry.buffer(
      binding: 1,
      visibility: GpuShaderStage.fragment,
      type: GpuBufferBindingType.uniform,
    ),
  ]);

  final bindGroup = device.createBindGroup(
    layout: bindGroupLayout,
    entries: [
      GpuBindGroupEntry.buffer(binding: 0, buffer: timeBuffer),
      GpuBindGroupEntry.buffer(binding: 1, buffer: resolutionBuffer),
    ],
  );

  final pipelineLayout = device.createPipelineLayout([bindGroupLayout]);

  // Setup Render Pipeline
  final pipeline = device.createRenderPipeline(
    GpuRenderPipelineDescriptor(
      layout: pipelineLayout,
      vertexModule: shaderModule,
      vertexEntryPoint: 'vsMain',
      vertexBuffers: [
        const GpuVertexBufferLayout(
          arrayStride: 20, // 5 floats * 4 bytes
          attributes: [
            GpuVertexAttribute(
              format: GpuVertexFormat.float32x3,
              offset: 0,
              shaderLocation: 0,
            ),
            GpuVertexAttribute(
              format: GpuVertexFormat.float32x2,
              offset: 12, // after 3 floats
              shaderLocation: 1,
            ),
          ],
        ),
      ],
      fragmentModule: shaderModule,
      fragmentEntryPoint: 'fsMain',
      colorTargets: [
        const GpuColorTargetState(format: GpuTextureFormat.rgba8Unorm),
      ],
    ),
  );

  // Create render target texture (RGBA8 format, 4 bytes per pixel)
  final texture = device.createTexture(
    width: width,
    height: height,
    format: GpuTextureFormat.rgba8Unorm,
    usage: GpuTextureUsage.renderAttachment | GpuTextureUsage.copySrc,
  );
  final textureView = texture.createView();

  // Create readback buffer
  final bytesPerRow = ((width * 4) + 255) & ~255; // Align row byte-stride to 256 bytes (WebGPU constraint)
  final bufferSize = bytesPerRow * height;

  final readBuffer = device.createBuffer(
    size: bufferSize,
    usage: GpuBufferUsage.mapRead | GpuBufferUsage.copyDst,
  );

  // Record command encoder commands
  final encoder = device.createCommandEncoder();

  final renderPass = encoder.beginRenderPass(
    colorAttachments: [
      GpuColorAttachment(
        view: textureView,
        loadOp: GpuLoadOp.clear,
        storeOp: GpuStoreOp.store,
        clearValue: const GpuColor(0, 0, 0, 1),
      ),
    ],
  );

  renderPass.setPipeline(pipeline);
  renderPass.setBindGroup(0, bindGroup);
  renderPass.setVertexBuffer(0, vertexBuffer);
  renderPass.draw(vertexCount: 6);
  renderPass.end();

  // Copy rendered image texture data back to readable buffer
  encoder.copyTextureToBuffer(
    source: texture,
    destination: readBuffer,
    bytesPerRow: bytesPerRow,
    width: width,
    height: height,
  );

  // Submit and execute
  queue.submit([encoder.finish()]);

  // Read back pixels
  print('Retrieving pixels from GPU...');
  final mapping = readBuffer.mapRead();
  var pollCount = 0;
  while (!mapping.isReady) {
    device.poll(wait: true);
    pollCount++;
    if (pollCount > 10000) {
      stderr.writeln('❌ Error: GPU mapRead timed out.');
      exit(1);
    }
  }

  final pixels = mapping.readTyped<Uint8List>();

  // ASCII Shader Rendering to Console
  print('\n--- Generated ShaderToy ASCII Art (Time = 2.5s) ---');
  for (var y = 0; y < height; y++) {
    final rowBuffer = StringBuffer();
    for (var x = 0; x < width; x++) {
      final index = (y * bytesPerRow) + (x * 4);
      final r = pixels[index];
      final g = pixels[index + 1];
      final b = pixels[index + 2];
      
      // Calculate simple brightness
      final brightness = (r + g + b) / 3.0;
      final char = _getAsciiChar(brightness);
      rowBuffer.write(char);
    }
    print(rowBuffer.toString());
  }

  // Cleanup
  mapping.dispose();
  readBuffer.dispose();
  textureView.dispose();
  texture.destroy();
  pipeline.dispose();
  bindGroup.dispose();
  bindGroupLayout.dispose();
  timeBuffer.dispose();
  resolutionBuffer.dispose();
  vertexBuffer.dispose();
  shaderModule.dispose();

  print('\nSuccess: Frame render complete.');
}

String _getAsciiChar(double brightness) {
  const chars = r' .:-=+*#%@';
  final idx = ((brightness / 255.0) * (chars.length - 1)).round();
  return chars[idx];
}
