import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Fetch the latest notifications for the logged-in user
  static Future<List<Map<String, dynamic>>> fetchMyNotifications() async {
    final uid = _client.auth.currentUser!.id;
    
    final data = await _client
        .from('notifications')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(20); // Fetch latest 20

    return List<Map<String, dynamic>>.from(data);
  }

  /// Get the count of unread notifications
  static Future<int> getUnreadCount() async {
    final uid = _client.auth.currentUser!.id;
    
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Mark a specific notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}