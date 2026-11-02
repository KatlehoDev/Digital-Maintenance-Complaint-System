import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import 'update_progress_screen.dart';
import 'complete_job_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Complaint complaint;
  const JobDetailScreen({super.key, required this.complaint});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Complaint _complaint;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      // FIX: Passing the title and reporterId so the HCM gets notified
      await ComplaintService.updateStatus(
        _complaint.id, 
        status,
        title: _complaint.title,
        reporterId: _complaint.reporterId, // <-- Ensure your model has this!
      );
      if (mounted) {
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A72),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_complaint.reference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${_complaint.categoryName} - ${_complaint.priority} priority', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_complaint.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_complaint.description ?? 'No description', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  
                  if (_complaint.reporterPhotoUrl != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(_complaint.reporterPhotoUrl!, fit: BoxFit.cover),
                      ),
                    ),

                  if (_complaint.progressPhotoUrl != null) ...[
                    const Text('Your Progress Photo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(_complaint.progressPhotoUrl!, fit: BoxFit.cover),
                      ),
                    ),
                  ],

                  if (_complaint.completionPhotoUrl != null) ...[
                    const Text('Completion Photo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(_complaint.completionPhotoUrl!, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  _buildInfoRow('Location', '${_complaint.residenceName} - ${_complaint.location}'),
                  _buildInfoRow('Deadline', _complaint.deadline?.toString() ?? 'Not set', isDeadline: true),
                  
                  const Divider(height: 32, thickness: 1),
                  
                  if (_complaint.status == 'assigned')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E7E34), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: () => _updateStatus('accepted'),
                            child: const Text('Accept Job', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  if (_complaint.status == 'accepted')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001A72), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateProgressScreen(complaint: _complaint)));
                          Navigator.pop(context, true);
                        },
                        child: const Text('Start Progress & Upload Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_complaint.status == 'in_progress')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E7E34), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => CompleteJobScreen(complaint: _complaint)));
                          Navigator.pop(context, true);
                        },
                        child: const Text('Mark as completed', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                  const SizedBox(height: 12),
                  
                  if (_complaint.status == 'assigned' || _complaint.status == 'accepted')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _updateStatus('rejected'),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject Job (Decline)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isDeadline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(
            child: isDeadline && _complaint.isOverdue
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFB00000), borderRadius: BorderRadius.circular(10)),
                  child: Text('Overdue \t $value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                )
              : Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}