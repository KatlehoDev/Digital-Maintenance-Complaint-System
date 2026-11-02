import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/complaint.dart';

class ComplaintService {
  static SupabaseClient get _client => Supabase.instance.client;

  // --- NOTIFICATION HELPERS ---
  
  static Future<void> _notifyAdmin(String complaintId, String message) async {
    try {
      await _client.rpc('notify_admin', params: {'comp_id': complaintId, 'msg': message});
    } catch (e) { print('Admin Notif Failed: $e'); }
  }

  static Future<void> _notifyWorker(String complaintId, String message) async {
    try {
      await _client.rpc('notify_role', params: {'target_role': 'maintenance', 'comp_id': complaintId, 'msg': message});
    } catch (e) { print('Worker Notif Failed: $e'); }
  }

  static Future<void> _notifyHcm(String complaintId, String hcmId, String message) async {
    try {
      await _client.rpc('notify_user', params: {'target_id': hcmId, 'comp_id': complaintId, 'msg': message});
    } catch (e) { print('HCM Notif Failed: $e'); }
  }

  // --- FETCH METHODS ---

  static Future<List<Complaint>> fetchMyComplaints() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from('complaints')
        .select('''
          *,
          categories(name),
          residences(name),
          complaint_images!complaint_images_complaint_id_fkey(image_url, stage)
        ''')
        .eq('reporter_id', uid)
        .neq('status', 'withdrawn') 
        .order('created_at', ascending: false);

    return (data as List).map((e) => Complaint.fromJson(e)).toList();
  }

  static Future<List<Complaint>> fetchAssignedComplaints() async {
    final uid = _client.auth.currentUser!.id;
    final assignments = await _client.from('assignments').select('complaint_id').eq('user_id', uid);
    final ids = (assignments as List).map((e) => e['complaint_id'] as String).toList();
    if (ids.isEmpty) return [];

    final data = await _client
        .from('complaints')
        .select('''
          *,
          categories(name),
          residences(name),
          complaint_images!complaint_images_complaint_id_fkey(image_url, stage)
        ''')
        .inFilter('id', ids)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Complaint.fromJson(e)).toList();
  }

  static Future<List<Complaint>> fetchJobHistory() async {
    final uid = _client.auth.currentUser!.id;
    final assignments = await _client.from('assignments').select('complaint_id').eq('user_id', uid);
    final ids = (assignments as List).map((e) => e['complaint_id'] as String).toList();
    if (ids.isEmpty) return [];

    final data = await _client
        .from('complaints')
        .select('''
          *,
          categories(name),
          residences(name),
          complaint_images!complaint_images_complaint_id_fkey(image_url, stage)
        ''')
        .inFilter('id', ids)
        .inFilter('status', ['completed', 'verified', 'closed'])
        .order('created_at', ascending: false);

    return (data as List).map((e) => Complaint.fromJson(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final data = await _client.from('categories').select('id, name').eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchResidences() async {
    final data = await _client.from('residences').select('id, name').order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  // --- UPLOAD METHODS ---

  static Future<String> _uploadPhoto({required String complaintId, required Uint8List fileBytes, required String stage}) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/$complaintId-$stage-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('complaint-photos').uploadBinary(path, fileBytes);
    return _client.storage.from('complaint-photos').getPublicUrl(path);
  }

  // --- ACTIONS ---

  static Future<void> submitComplaint({
    required String title,
    required String description,
    required String location,
    required String categoryId,
    required String residenceId,
    Uint8List? photoBytes,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final complaintId = const Uuid().v4();

    await _client.from('complaints').insert({
      'id': complaintId,
      'reporter_id': uid,
      'category_id': categoryId,
      'residence_id': residenceId,
      'title': title,
      'description': description,
      'location': location,
      'status': 'reported',
      'priority': 'medium',
    });

    if (photoBytes != null) {
      final url = await _uploadPhoto(complaintId: complaintId, fileBytes: photoBytes, stage: 'reporter');
      await _client.from('complaint_images').insert({'complaint_id': complaintId, 'image_url': url, 'stage': 'reporter'});
    }

    await _client.from('complaint_history').insert({
      'complaint_id': complaintId, 'user_id': uid, 'action': 'Complaint submitted', 'new_status': 'reported',
    });

    await _notifyAdmin(complaintId, 'New complaint reported: $title');
  }

  static Future<void> updateStatus(String complaintId, String newStatus, {String? title, String? reporterId}) async {
    final uid = _client.auth.currentUser!.id;

    await _client.from('complaints').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);

    await _client.from('complaint_history').insert({
      'complaint_id': complaintId, 'user_id': uid, 'action': 'Status changed to $newStatus', 'new_status': newStatus,
    });

    // Send notifications based on status
    if (newStatus == 'accepted') {
      await _notifyAdmin(complaintId, 'Job $complaintId accepted by maintenance.');
      if (reporterId != null) await _notifyHcm(complaintId, reporterId, 'Your complaint "$title" has been accepted by a worker.');
    } 
    else if (newStatus == 'in_progress') {
      await _notifyAdmin(complaintId, 'Job $complaintId is now in progress.');
      if (reporterId != null) await _notifyHcm(complaintId, reporterId, 'Work has started on your complaint "$title".');
    }
    else if (newStatus == 'completed') {
      await _notifyAdmin(complaintId, 'Job $complaintId completed by maintenance.');
      if (reporterId != null) await _notifyHcm(complaintId, reporterId, 'Your complaint "$title" has been marked as completed. Please verify.');
    }
    else if (newStatus == 'rejected') {
      await _notifyAdmin(complaintId, 'Job $complaintId was REJECTED by maintenance!');
      if (reporterId != null) await _notifyHcm(complaintId, reporterId, 'Your complaint "$title" was rejected by the worker and needs reassignment.');
    }
  }

  static Future<void> uploadProgressPhoto(String complaintId, Uint8List photoBytes) async {
    final url = await _uploadPhoto(complaintId: complaintId, fileBytes: photoBytes, stage: 'progress');
    await _client.from('complaint_images').insert({'complaint_id': complaintId, 'image_url': url, 'stage': 'progress'});
    await _client.from('complaint_history').insert({'complaint_id': complaintId, 'user_id': _client.auth.currentUser!.id, 'action': 'Uploaded progress photo'});
  }

  static Future<void> uploadCompletionPhoto(String complaintId, Uint8List photoBytes) async {
    final url = await _uploadPhoto(complaintId: complaintId, fileBytes: photoBytes, stage: 'completion');
    await _client.from('complaint_images').insert({'complaint_id': complaintId, 'image_url': url, 'stage': 'completion'});
  }

  static Future<void> verifyComplaint({
    required String complaintId,
    required String result,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser!.id;

    await _client.from('complaints').update({
      'status': result,
      if (result == 'verified') 'closed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);

    await _client.from('complaint_history').insert({
      'complaint_id': complaintId, 'user_id': uid, 
      'action': result == 'verified' ? 'Complainant verified resolution' : 'Complainant reopened complaint',
      'old_status': 'completed', 'new_status': result, 'comment': comment,
    });

    if (result == 'verified') {
      await _notifyAdmin(complaintId, 'Complaint $complaintId verified and closed by HCM.');
      await _notifyWorker(complaintId, 'The HCM has verified your work for complaint $complaintId. Well done!');
    } else {
      await _notifyAdmin(complaintId, 'Complaint $complaintId was REOPENED by HCM.');
      await _notifyWorker(complaintId, 'Complaint $complaintId was reopened by HCM. Please review the feedback.');
    }
  }

  static Future<void> withdrawComplaint(String complaintId, String title) async {
    await _client.from('complaints').update({'status': 'withdrawn', 'updated_at': DateTime.now().toIso8601String()}).eq('id', complaintId);
    await _client.from('complaint_history').insert({'complaint_id': complaintId, 'user_id': _client.auth.currentUser!.id, 'action': 'Complaint withdrawn by HCM', 'new_status': 'withdrawn'});
    await _notifyAdmin(complaintId, 'Complaint WITHDRAWN: $title');
  }
}