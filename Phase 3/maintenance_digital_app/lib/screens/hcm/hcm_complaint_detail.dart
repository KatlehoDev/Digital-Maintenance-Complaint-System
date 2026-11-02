import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import 'hcm_verification_screen.dart';

class HcmComplaintDetail extends StatelessWidget {
  final Complaint complaint;
  const HcmComplaintDetail({super.key, required this.complaint});

  Future<void> _withdraw(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw Complaint?'),
        content: const Text('This will remove the complaint from the system. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Withdraw')
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ComplaintService.withdrawComplaint(complaint.id, complaint.title);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsVerification = complaint.status == 'completed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2665),
        foregroundColor: Colors.white,
        title: Text('Complaint ${complaint.reference}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Grey Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Text('${complaint.residenceName}, Room ${complaint.location}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Text('Reported : ${complaint.createdAt.day} ${_getMonthName(complaint.createdAt.month)}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Priority : ${complaint.priority.toUpperCase()}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Text('Status : ${complaint.status.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}', 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2A2665))),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Description Section
            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(8)),
              child: Text(complaint.description ?? 'No description provided.', style: const TextStyle(fontSize: 14)),
            ),

            // PHOTOS SECTION
            if (complaint.reporterPhotoUrl != null || complaint.progressPhotoUrl != null || complaint.completionPhotoUrl != null) ...[
              const SizedBox(height: 24),
              const Text('Photos & Evidence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (complaint.reporterPhotoUrl != null) ...[
                const Text('Your Original Report:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(complaint.reporterPhotoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
              ],
              
              if (complaint.progressPhotoUrl != null) ...[
                const Text('Worker In-Progress Photo:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(complaint.progressPhotoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
              ],
              
              if (complaint.completionPhotoUrl != null) ...[
                const Text('Worker Completion Photo:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(complaint.completionPhotoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
            ],

            const SizedBox(height: 32),
            
            // Status Timeline
            const Text('Status Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _buildTimelineItem('Reported', true, isFirst: true, isLast: false),
            _buildTimelineItem('Assigned', ['assigned', 'in_progress', 'completed', 'verified', 'closed'].contains(complaint.status), isFirst: false, isLast: false),
            _buildTimelineItem('In Progress', ['in_progress', 'completed', 'verified', 'closed'].contains(complaint.status), isFirst: false, isLast: false),
            _buildTimelineItem('Completed', ['completed', 'verified', 'closed'].contains(complaint.status), isFirst: false, isLast: true),

            const SizedBox(height: 40),

            // VERIFY BUTTON (Only shows if completed)
            if (needsVerification) ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7E34),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final verified = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => HcmVerificationScreen(complaint: complaint)),
                    );
                    if (verified == true && context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Verify Resolution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Withdraw Button
            if (complaint.status != 'verified' && complaint.status != 'closed' && complaint.status != 'withdrawn') ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _withdraw(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Withdraw Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildTimelineItem(String title, bool isComplete, {required bool isFirst, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: isComplete ? const Color(0xFF2A2665) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2, 
                height: 40, 
                color: isComplete ? const Color(0xFF2A2665) : Colors.grey[300]
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Text(title, style: TextStyle(
            fontWeight: isComplete ? FontWeight.bold : FontWeight.normal, 
            fontSize: 15,
            color: isComplete ? Colors.black : Colors.grey
          )),
        )
      ],
    );
  }
}