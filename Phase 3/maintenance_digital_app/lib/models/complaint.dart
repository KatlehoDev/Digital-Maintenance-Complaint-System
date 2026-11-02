class Complaint {
  final String id;
  final String reference;
  final String title;
  final String? description;
  final String? location;
  final String status;
  final String priority;
  final DateTime? deadline;
  final DateTime createdAt;
  final String? categoryName;
  final String? residenceName;
  final String reporterId; // ADDED: Used for sending notifications to the HCM

  // Photos
  final String? reporterPhotoUrl;
  final String? progressPhotoUrl;
  final String? completionPhotoUrl;

  Complaint({
    required this.id,
    required this.reference,
    required this.title,
    this.description,
    this.location,
    required this.status,
    required this.priority,
    this.deadline,
    required this.createdAt,
    this.categoryName,
    this.residenceName,
    required this.reporterId,
    this.reporterPhotoUrl,
    this.progressPhotoUrl,
    this.completionPhotoUrl,
  });

  factory Complaint.fromJson(Map<String, dynamic> j) {
    final cat = j['categories'];
    final res = j['residences'];
    
    String? reporterUrl;
    String? progressUrl;
    String? completionUrl;

    // Safely extract images based on their 'stage'
    final imgs = j['complaint_images'];
    if (imgs is List) {
      for (var img in imgs) {
        if (img is Map) {
          final stage = img['stage'] ?? 'reporter';
          final url = img['image_url'] as String?;
          if (stage == 'reporter') reporterUrl = url;
          if (stage == 'progress') progressUrl = url;
          if (stage == 'completion') completionUrl = url;
        }
      }
    }

    return Complaint(
      id: j['id'] as String,
      reference: j['reference'] as String? ?? 'No Ref',
      title: j['title'] as String? ?? 'No Title',
      description: j['description'] as String?,
      location: j['location'] as String?,
      status: j['status'] as String? ?? 'reported',
      priority: j['priority'] as String? ?? 'medium',
      deadline: j['deadline'] != null 
          ? DateTime.tryParse(j['deadline'] as String) 
          : null,
      createdAt: j['created_at'] != null 
          ? DateTime.parse(j['created_at'] as String) 
          : DateTime.now(),
      categoryName: cat is Map ? cat['name'] as String? : null,
      residenceName: res is Map ? res['name'] as String? : null,
      reporterId: j['reporter_id'] as String? ?? '', // Safely parse reporter ID
      reporterPhotoUrl: reporterUrl,
      progressPhotoUrl: progressUrl,
      completionPhotoUrl: completionUrl,
    );
  }

  bool get isOverdue =>
      deadline != null &&
      deadline!.isBefore(DateTime.now()) &&
      status != 'verified' &&
      status != 'closed' &&
      status != 'withdrawn';
}