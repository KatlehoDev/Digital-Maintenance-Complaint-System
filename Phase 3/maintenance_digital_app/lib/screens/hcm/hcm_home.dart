import 'dart:async'; // <-- ONLY ADDED THIS
import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart';
import 'report_complaint_screen.dart';
import 'hcm_complaint_detail.dart';
import 'hcm_verification_screen.dart';

class HcmHome extends StatefulWidget {
  const HcmHome({super.key});
  @override
  State<HcmHome> createState() => _HcmHomeState();
}

class _HcmHomeState extends State<HcmHome> {
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  int _unreadCount = 0;
  
  Timer? _notificationTimer; // <-- ONLY ADDED THIS

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _loadUnreadCount();
    
    // <-- ONLY ADDED THIS TIMER BLOCK
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel(); // <-- ONLY ADDED THIS
    _searchCtrl.dispose();        // <-- ONLY ADDED THIS
    super.dispose();
  }

  // ... EVERYTHING ELSE BELOW IS EXACTLY YOUR ORIGINAL CODE
  Future<void> _fetchComplaints() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final data = await ComplaintService.fetchMyComplaints();
      if (mounted) {
        setState(() {
          _complaints = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted && count != _unreadCount) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      print('Failed to load unread count: $e');
    }
  }

  Future<void> _openReport() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ReportComplaintScreen()),
    );
    if (created == true) {
      _fetchComplaints(); 
    }
  }

  void _showNotifications() async {
    final notifications = await NotificationService.fetchMyNotifications();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2A2665))),
              const SizedBox(height: 16),
              Expanded(
                child: notifications.isEmpty
                    ? const Center(child: Text('No new notifications.'))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, i) {
                          final n = notifications[i];
                          final isRead = n['is_read'] as bool;
                          return ListTile(
                            leading: Icon(isRead ? Icons.notifications_none : Icons.notifications_active, color: isRead ? Colors.grey : const Color(0xFF2A2665)),
                            title: Text(n['message'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(n['created_at'].toString().substring(0, 16)),
                            onTap: () async {
                              if (!isRead) {
                                await NotificationService.markAsRead(n['id']);
                                Navigator.pop(context);
                                _loadUnreadCount();
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
    _loadUnreadCount();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reported': return const Color(0xFF0084D6);
      case 'assigned': return const Color(0xFFE28743);
      case 'in_progress': return const Color(0xFFE28743);
      case 'completed': return const Color(0xFF1E7E34);
      case 'verified': return const Color(0xFF1E7E34);
      case 'closed': return const Color(0xFF1E7E34);
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredComplaints = _complaints.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery) ||
             c.reference.toLowerCase().contains(_searchQuery) ||
             (c.location?.toLowerCase().contains(_searchQuery) ?? false) ||
             (c.residenceName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2665),
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Search...', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              )
            : const Text('My Complaints', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications), onPressed: _showNotifications),
              if (_unreadCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) { _isSearching = false; _searchQuery = ''; _searchCtrl.clear(); } 
                else { _isSearching = true; }
              });
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async => AuthService.signOut()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReport,
        backgroundColor: const Color(0xFF2A2665),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : filteredComplaints.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No complaints found.', style: TextStyle(color: Colors.grey, fontSize: 16))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, i) {
                      final c = filteredComplaints[i];
                      return GestureDetector(
                        onTap: () async {
                          if (c.status == 'completed') {
                            final verified = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => HcmVerificationScreen(complaint: c)),
                            );
                            if (verified == true) _fetchComplaints();
                          } else {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => HcmComplaintDetail(complaint: c)),
                            );
                            if (changed == true) _fetchComplaints();
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 6,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(c.status),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      bottomLeft: Radius.circular(11),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${c.reference} * ${c.title}', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2A2665))),
                                        const SizedBox(height: 8),
                                        Text('${c.residenceName}, Room ${c.location}', 
                                          style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                        const SizedBox(height: 16),
                                        Text('Status: ${c.status.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}',
                                          style: TextStyle(
                                            fontSize: 13, 
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(c.status),
                                          )),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}