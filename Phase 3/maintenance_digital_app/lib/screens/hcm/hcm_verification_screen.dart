import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';

class HcmVerificationScreen extends StatefulWidget {
  final Complaint complaint;
  const HcmVerificationScreen({super.key, required this.complaint});

  @override
  State<HcmVerificationScreen> createState() => _HcmVerificationScreenState();
}

class _HcmVerificationScreenState extends State<HcmVerificationScreen> {
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit(String result) async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a comment before submitting.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ComplaintService.verifyComplaint(
        complaintId: widget.complaint.id,
        result: result,
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == 'verified' ? 'Resolution Verified!' : 'Complaint Reopened!'),
            backgroundColor: result == 'verified' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2665),
        foregroundColor: Colors.white,
        title: const Text('Verification', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Grey Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Complaint ${widget.complaint.reference}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(widget.complaint.title, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 12),
                        const Text('Marked completed by maintenance staff', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                  
                  // PHOTO EVIDENCE SECTION
                  if (widget.complaint.reporterPhotoUrl != null || widget.complaint.progressPhotoUrl != null || widget.complaint.completionPhotoUrl != null) ...[
                    const SizedBox(height: 24),
                    const Text('Photo Evidence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    if (widget.complaint.reporterPhotoUrl != null) ...[
                      const Text('Original Problem:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.complaint.reporterPhotoUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[300], child: const Center(child: Text('Image not found'))),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (widget.complaint.progressPhotoUrl != null) ...[
                      const Text('Worker In-Progress:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.complaint.progressPhotoUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[300], child: const Center(child: Text('Image not found'))),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (widget.complaint.completionPhotoUrl != null) ...[
                      const Text('Finished Work:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.complaint.completionPhotoUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[300], child: const Center(child: Text('Image not found'))),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),
                  
                  const Text('Was this problem resolved?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Comments Field (Mandatory now)
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add comments (required)',
                      filled: true,
                      fillColor: const Color(0xFFE0E0E0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button 1: Verify Resolution
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7E34), // Green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _submit('verified'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Resolved Successfully', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button 2: Reopen Complaint
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB00020), // Red
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _submit('reopened'),
                      icon: const Icon(Icons.replay),
                      label: const Text('Not Resolved (Reopen)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}