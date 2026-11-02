import 'dart:async'; // <-- ONLY ADDED THIS
import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart';
import '../widget/status_chip.dart';
import 'job_detail_screen.dart';

class MaintenanceHome extends StatefulWidget {
  const MaintenanceHome({super.key});
  @override
  State<MaintenanceHome> createState() => _MaintenanceHomeState();
}

class _MaintenanceHomeState extends State<MaintenanceHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Complaint> _activeJobs = [];
  List<Complaint> _history = [];
  bool _isLoading = true;

  String _searchQuery = '';
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  int _unreadCount = 0;
  
  Timer? _notificationTimer; // <-- ONLY ADDED THIS

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
    
    // <-- ONLY ADDED THIS TIMER BLOCK
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel(); // <-- ONLY ADDED THIS
    _tabController.dispose();     // <-- ONLY ADDED THIS
    _searchCtrl.dispose();        // <-- ONLY ADDED THIS
    super.dispose();
  }

  // ... EVERYTHING ELSE BELOW IS EXACTLY YOUR ORIGINAL CODE
  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final active = await ComplaintService.fetchAssignedComplaints();
      final hist = await ComplaintService.fetchJobHistory();
      if (mounted) {
        setState(() {
          _activeJobs = active;
          _history = hist;
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
    } catch (e) {}
  }

  void _showNotifications() async {
    final notifications = await NotificationService.fetchMyNotifications();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20), height: 400,
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

  @override
  Widget build(BuildContext context) {
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
            : const Text('My Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'My Jobs'), Tab(text: 'History')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJobList(_activeJobs, isHistory: false),
                _buildJobList(_history, isHistory: true),
              ],
            ),
    );
  }

  Widget _buildJobList(List<Complaint> jobs, {required bool isHistory}) {
    final filteredJobs = jobs.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery) || 
             c.reference.toLowerCase().contains(_searchQuery) ||
             (c.location?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: filteredJobs.isEmpty
          ? ListView(children: [
              const SizedBox(height: 120),
              Center(child: Text(isHistory ? 'No history found.' : 'No jobs found.', style: const TextStyle(color: Colors.grey))),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredJobs.length,
              itemBuilder: (context, i) => _buildJobCard(filteredJobs[i], isHistory),
            ),
    );
  }

  Widget _buildJobCard(Complaint c, bool isHistory) {
    Color sideColor = Colors.grey;
    if (c.isOverdue) {
      sideColor = Colors.red;
    } else if (c.status == 'in_progress') {
      sideColor = Colors.purple;
    } else if (c.status == 'accepted') {
      sideColor = Colors.orange;
    } else if (c.status == 'completed') {
      sideColor = Colors.blue;
    } else if (c.status == 'verified' || c.status == 'closed') {
      sideColor = Colors.green;
    }

    return GestureDetector(
      onTap: () async {
        if (!isHistory) {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(complaint: c)),
          );
          if (changed == true) _fetchData();
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
                width: 8,
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2A2665))),
                      const SizedBox(height: 4),
                      Text('${c.residenceName} - ${c.location}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusPill(c),
                          _buildDeadlinePill(c),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(Complaint c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2665), width: 1.2),
      ),
      child: Text(
        c.status.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2A2665)),
      ),
    );
  }

  Widget _buildDeadlinePill(Complaint c) {
    String text = "Not set";
    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF2A2665);
    
    if (c.deadline != null) {
      if (c.isOverdue) {
        text = 'Overdue - ${c.deadline!.hour.toString().padLeft(2, '0')}:${c.deadline!.minute.toString().padLeft(2, '0')}';
        bgColor = const Color(0xFFB00000);
        textColor = Colors.white;
      } else {
        text = 'Due ${c.deadline!.day}/${c.deadline!.month}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: bgColor == Colors.transparent ? Border.all(color: const Color(0xFF2A2665), width: 1.2) : null,
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}