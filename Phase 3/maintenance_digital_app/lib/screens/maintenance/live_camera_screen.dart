
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() =>
      _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  CameraController? _controller;
  bool _loading = true;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera was detected.');
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);

    try {
      final photo = await controller.takePicture();

      if (!mounted) return;
      Navigator.pop<XFile>(context, photo);
    } catch (e) {
      if (!mounted) return;

      setState(() => _capturing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture photo: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a Photo'),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Unable to open camera.\n\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  )
                : controller != null &&
                        controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      )
                    : const Text('Camera is unavailable.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ||
                _error != null ||
                _capturing
            ? null
            : _capturePhoto,
        tooltip: 'Capture photo',
        child: _capturing
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}
