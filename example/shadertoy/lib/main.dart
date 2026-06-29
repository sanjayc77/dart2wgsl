import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gpux/flutter_gpux.dart';
import 'shaders/toy.wgsl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShaderToyApp());
}

class ShaderToyApp extends StatelessWidget {
  const ShaderToyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart2WGSL ShaderToy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E1E24),
        ),
      ),
      home: const ShaderToyScreen(),
    );
  }
}

class ShaderToyScreen extends StatefulWidget {
  const ShaderToyScreen({super.key});

  @override
  State<ShaderToyScreen> createState() => _ShaderToyScreenState();
}

class _ShaderToyScreenState extends State<ShaderToyScreen>
    with SingleTickerProviderStateMixin {
  late final ContinuousTicker _ticker;
  late final ToyRenderer _renderer;
  bool _showCode = false;
  String _activeTab = 'dart'; // 'dart' or 'wgsl'
  String _dartShaderCode = 'Loading Dart Shader Source...';

  @override
  void initState() {
    super.initState();
    _ticker = ContinuousTicker(this);
    _renderer = ToyRenderer(repaint: _ticker);
    _loadShaderSource();
  }

  Future<void> _loadShaderSource() async {
    try {
      final code = await rootBundle.loadString('lib/shaders/toy.shader.dart');
      setState(() {
        _dartShaderCode = code;
      });
    } catch (e) {
      setState(() {
        _dartShaderCode = 'Error loading Dart shader source: $e';
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _renderer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _ticker.toggle();
      if (_ticker.isActive) {
        _renderer.resume();
      } else {
        _renderer.pause();
      }
    });
  }

  void _resetShader() {
    setState(() {
      _renderer.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultGpu(
        child: Stack(
          children: [
            // Full Screen Shader View
            Positioned.fill(child: GpuView(renderer: _renderer)),

            // Top Header Panel
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title / Branding
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'dart2wgsl',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          ' • ShaderToy',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      _buildHeaderButton(
                        icon: _ticker.isActive ? Icons.pause : Icons.play_arrow,
                        label: _ticker.isActive ? 'Pause' : 'Play',
                        onPressed: _togglePlayPause,
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderButton(
                        icon: Icons.replay,
                        label: 'Reset',
                        onPressed: _resetShader,
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderButton(
                        icon: Icons.code,
                        label: _showCode ? 'Hide Code' : 'Show Code',
                        onPressed: () {
                          setState(() {
                            _showCode = !_showCode;
                          });
                        },
                        highlight: _showCode,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Left Side Info Overlay
            Positioned(
              bottom: 24,
              left: 24,
              child: ListenableBuilder(
                listenable: _renderer,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    width: 240,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'STATUS & METRICS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6366F1),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricRow('Renderer', 'Flutter WebGPU'),
                        _buildMetricRow('FPS', '60.0 fps (VSync)'),
                        _buildMetricRow(
                          'Time',
                          '${_renderer.elapsedSeconds.toStringAsFixed(2)}s',
                        ),
                        _buildMetricRow(
                          'Resolution',
                          '${_renderer.lastWidth.toInt()} × ${_renderer.lastHeight.toInt()}',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Code View Panel (Right aligned drawer)
            if (_showCode)
              Positioned(
                top: 96,
                bottom: 24,
                right: 24,
                width: 480,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Code Tabs Header
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            _buildTabButton('Dart Shader Source', 'dart'),
                            const SizedBox(width: 8),
                            _buildTabButton('Transpiled WGSL', 'wgsl'),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      // Code Editor Area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _activeTab == 'dart' ? _dartShaderCode : toyShader,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              color: Color(0xFFE2E8F0),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool highlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF6366F1)
            : const Color(0xFF1E1E24).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final active = _activeTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tabKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? const Color(0xFF6366F1) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class ContinuousTicker extends ChangeNotifier {
  Ticker? _ticker;
  bool _isActive = true;

  ContinuousTicker(TickerProvider vsync) {
    _ticker = vsync.createTicker((_) {
      if (_isActive) {
        notifyListeners();
      }
    });
    _ticker!.start();
  }

  bool get isActive => _isActive;

  void toggle() {
    _isActive = !_isActive;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

class ToyRenderer extends GpuRenderer {
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool isPaused = false;
  double _pausedTime = 0.0;

  double lastWidth = 800.0;
  double lastHeight = 600.0;

  GpuShaderModule? _shaderModule;
  GpuBuffer? _vertexBuffer;
  GpuBuffer? _timeBuffer;
  GpuBuffer? _resolutionBuffer;
  GpuBindGroupLayout? _bindGroupLayout;
  GpuBindGroup? _bindGroup;
  GpuPipelineLayout? _pipelineLayout;
  GpuRenderPipeline? _pipeline;

  final Float32List _timeData = Float32List(2); // 8 bytes (1 float + padding)
  final Float32List _resolutionData = Float32List(2); // 8 bytes (2 floats)

  ToyRenderer({super.repaint});

  double get elapsedSeconds {
    if (isPaused) return _pausedTime;
    return _stopwatch.elapsedMilliseconds / 1000.0;
  }

  void pause() {
    if (!isPaused) {
      isPaused = true;
      _pausedTime = _stopwatch.elapsedMilliseconds / 1000.0;
      _stopwatch.stop();
    }
  }

  void resume() {
    if (isPaused) {
      isPaused = false;
      _stopwatch.start();
    }
  }

  void reset() {
    _stopwatch.reset();
    _pausedTime = 0.0;
    if (!isPaused) {
      _stopwatch.start();
    }
  }

  void _initResources(GpuDevice device, GpuTextureFormat format) {
    _shaderModule = device.createShaderModule(toyShader);

    // Define vertices for a full-screen quad (two triangles)
    // Vertex positions: X, Y, Z,  UV: U, V
    final vertices = Float32List.fromList([
      -1.0, 1.0, 0.0, 0.0, 0.0, // Top-Left
      -1.0, -1.0, 0.0, 0.0, 1.0, // Bottom-Left
      1.0, -1.0, 0.0, 1.0, 1.0, // Bottom-Right

      -1.0, 1.0, 0.0, 0.0, 0.0, // Top-Left
      1.0, -1.0, 0.0, 1.0, 1.0, // Bottom-Right
      1.0, 1.0, 0.0, 1.0, 0.0, // Top-Right
    ]);

    _vertexBuffer = device.createBuffer(
      size: vertices.lengthInBytes,
      usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
    );
    device.queue.writeBuffer(
      _vertexBuffer!,
      vertices.buffer.asUint8List(
        vertices.offsetInBytes,
        vertices.lengthInBytes,
      ),
    );

    // Setup Uniforms: Time and Resolution as separate buffers
    _timeBuffer = device.createBuffer(
      size: _timeData.lengthInBytes,
      usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
    );

    _resolutionBuffer = device.createBuffer(
      size: _resolutionData.lengthInBytes,
      usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
    );

    // Create Bind Group for Uniforms
    _bindGroupLayout = device.createBindGroupLayout([
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

    _bindGroup = device.createBindGroup(
      layout: _bindGroupLayout!,
      entries: [
        GpuBindGroupEntry.buffer(binding: 0, buffer: _timeBuffer!),
        GpuBindGroupEntry.buffer(binding: 1, buffer: _resolutionBuffer!),
      ],
    );

    _pipelineLayout = device.createPipelineLayout([_bindGroupLayout]);

    // Setup Render Pipeline
    _pipeline = device.createRenderPipeline(
      GpuRenderPipelineDescriptor(
        layout: _pipelineLayout!,
        vertexModule: _shaderModule!,
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
        fragmentModule: _shaderModule!,
        fragmentEntryPoint: 'fsMain',
        colorTargets: [GpuColorTargetState(format: format)],
      ),
    );
  }

  @override
  bool render(GpuFrame frame) {
    final device = frame.device;

    lastWidth = frame.width.toDouble();
    lastHeight = frame.height.toDouble();

    if (_pipeline == null) {
      _initResources(device, frame.format);
    }

    // Update uTime
    _timeData[0] = elapsedSeconds;
    device.queue.writeBuffer(
      _timeBuffer!,
      _timeData.buffer.asUint8List(
        _timeData.offsetInBytes,
        _timeData.lengthInBytes,
      ),
    );

    // Update uResolution
    _resolutionData[0] = lastWidth;
    _resolutionData[1] = lastHeight;
    device.queue.writeBuffer(
      _resolutionBuffer!,
      _resolutionData.buffer.asUint8List(
        _resolutionData.offsetInBytes,
        _resolutionData.lengthInBytes,
      ),
    );

    final enc = device.createCommandEncoder();
    final pass = enc.beginRenderPass(
      colorAttachments: [
        GpuColorAttachment(
          view: frame.targetView,
          loadOp: GpuLoadOp.clear,
          storeOp: GpuStoreOp.store,
          clearValue: const GpuColor(0, 0, 0, 1),
        ),
      ],
    );

    pass.setPipeline(_pipeline!);
    pass.setBindGroup(0, _bindGroup!);
    pass.setVertexBuffer(0, _vertexBuffer);
    pass.draw(vertexCount: 6);
    pass.end();

    device.queue.submit([enc.finish()]);

    return true; // Frame successfully rendered
  }

  @override
  bool shouldUpdate(covariant ToyRenderer oldRenderer) {
    _shaderModule = oldRenderer._shaderModule;
    _vertexBuffer = oldRenderer._vertexBuffer;
    _timeBuffer = oldRenderer._timeBuffer;
    _resolutionBuffer = oldRenderer._resolutionBuffer;
    _bindGroupLayout = oldRenderer._bindGroupLayout;
    _bindGroup = oldRenderer._bindGroup;
    _pipelineLayout = oldRenderer._pipelineLayout;
    _pipeline = oldRenderer._pipeline;
    return false;
  }

  @override
  void dispose() {
    _vertexBuffer?.destroy();
    _timeBuffer?.destroy();
    _resolutionBuffer?.destroy();
    super.dispose();
  }
}
