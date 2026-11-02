import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart'; // Added for Web camera
import '../../services/complaint_service.dart';

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});
  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _residences = [];
  String? _categoryId;
  String? _residenceId;
  Uint8List? _photoBytes;
  bool _loading = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final cats = await ComplaintService.fetchCategories();
      final res = await ComplaintService.fetchResidences();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _residences = res;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _initializing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Add Photo Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2A2665)),
              title: const Text('Take a Photo (Camera)'),
              onTap: () {
                Navigator.pop(context);
                if (kIsWeb) {
                  _openWebCamera();
                } else {
                  _pickPhoto(ImageSource.camera);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2A2665)),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  // Opens a live webcam using the camera package
  Future<void> _openWebCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera found.')));
        return;
      }
      
      final result = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => WebCameraCaptureScreen(cameras: cameras)),
      );

      if (result != null) {
        setState(() => _photoBytes = result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera error: $e')));
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1600, preferredCameraDevice: CameraDevice.rear);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open camera: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a category')));
      return;
    }
    if (_residenceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a residence')));
      return;
    }
    
    setState(() => _loading = true);
    try {
      await ComplaintService.submitComplaint(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        categoryId: _categoryId!,
        residenceId: _residenceId!,
        photoBytes: _photoBytes,
      );
      
      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully!'), backgroundColor: Color(0xFF1E7E34)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
      setState(() => _loading = false);
    }
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2665),
        foregroundColor: Colors.white,
        title: const Text('New Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: _inputStyle('Title'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: _inputStyle('Category'),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                    items: _categories.map((c) => DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text(c['name'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _residenceId,
                    decoration: _inputStyle('Location / Residence'),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                    items: _residences.map((r) => DropdownMenuItem<String>(
                      value: r['id'] as String,
                      child: Text(r['name'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() => _residenceId = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: _inputStyle('Room Number / Specific Location'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Location required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: _inputStyle('Description'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Description required' : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: _photoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_photoBytes!, fit: BoxFit.cover),
                      )
                    : CustomPaint(
                        painter: SimpleDashedBorderPainter(color: Colors.grey.shade400, strokeWidth: 2.0, gap: 5.0),
                        child: const Center(
                          child: Text('[+] Attach / Capture photo', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 32),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2665),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// NEW WIDGET: Live Web Camera Screen
// ---------------------------------------------------------
class WebCameraCaptureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const WebCameraCaptureScreen({super.key, required this.cameras});

  @override
  State<WebCameraCaptureScreen> createState() => _WebCameraCaptureScreenState();
}

class _WebCameraCaptureScreenState extends State<WebCameraCaptureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the front-facing camera (or first available)
    _controller = CameraController(widget.cameras.first, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final bytes = await image.readAsBytes();
      if (mounted) Navigator.pop(context, bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take Photo'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Center(child: CameraPreview(_controller)),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class SimpleDashedBorderPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;

  SimpleDashedBorderPainter({this.strokeWidth = 1.0, this.color = Colors.black, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    final double width = size.width;
    final double height = size.height;

    for (double i = 0; i < width; i += gap * 2) {
      canvas.drawLine(Offset(i, 0), Offset(i + gap, 0), paint);
      canvas.drawLine(Offset(i, height), Offset(i + gap, height), paint);
    }
    for (double i = 0; i < height; i += gap * 2) {
      canvas.drawLine(Offset(0, i), Offset(0, i + gap), paint);
      canvas.drawLine(Offset(width, i), Offset(width, i + gap), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}