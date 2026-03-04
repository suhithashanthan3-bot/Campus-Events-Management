class FeedbackModel {
  final String id;
  final String eventId;
  final String name;
  final String email;
  final int rating;
  final String comment;
  final String timestamp;

  FeedbackModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.email,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  // Convert JSON to FeedbackModel object
  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  // Convert FeedbackModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'email': email,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
    };
  }

  // Create a copy with updated fields
  FeedbackModel copyWith({
    String? id,
    String? eventId,
    String? name,
    String? email,
    int? rating,
    String? comment,
    String? timestamp,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}