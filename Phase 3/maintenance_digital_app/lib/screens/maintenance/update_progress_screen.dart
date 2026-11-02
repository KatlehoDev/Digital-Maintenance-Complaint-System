import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';

class UpdateProgressScreen extends StatefulWidget {
  final Complaint complaint;
  const UpdateProgressScreen({super.key, required this.complaint});

  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  final _notesCtrl = TextEditingController();
  Uint8List? _photoBytes;
  bool _loading = false;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      if (_photoBytes != null) {
        await ComplaintService.uploadProgressPhoto(widget.complaint.id, _photoBytes!);
      }
      await ComplaintService.updateStatus(widget.complaint.id, 'in_progress');
      
      if (mounted) {
        // CLEAR THE FORM BUT STAY ON THE SCREEN
        setState(() {
          _notesCtrl.clear();
          _photoBytes = null;
          _loading = false;
        });

        // SHOW SUCCESS MESSAGE
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress saved successfully!'), 
            backgroundColor: Color(0xFF1E7E34)
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A72),
        foregroundColor: Colors.white,
        title: const Text('Update progress', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Isolated water supply...',
                filled: true,
                fillColor: const Color(0xFFE0E0E0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Photo (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _photoBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_photoBytes!, fit: BoxFit.cover))
                    : const Center(child: Text('Take or choose a photo', style: TextStyle(color: Colors.grey))),
              ),
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001A72),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _loading ? null : _save,
                child: _loading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Save updates', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}