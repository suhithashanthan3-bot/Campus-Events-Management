class Rsvp {
  final String id;
  final String eventId;
  final String name;
  final String email;
  final String studentId;
  final String status;
  final String timestamp;

  Rsvp({
    required this.id,
    required this.eventId,
    required this.name,
    required this.email,
    required this.studentId,
    required this.status,
    required this.timestamp,
  });

  // Convert JSON to Rsvp object
  factory Rsvp.fromJson(Map<String, dynamic> json) {
    return Rsvp(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      studentId: json['studentId'] ?? '',
      status: json['status'] ?? 'pending',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  // Convert Rsvp to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'email': email,
      'studentId': studentId,
      'status': status,
      'timestamp': timestamp,
    };
  }

  // Create a copy with updated fields
  Rsvp copyWith({
    String? id,
    String? eventId,
    String? name,
    String? email,
    String? studentId,
    String? status,
    String? timestamp,
  }) {
    return Rsvp(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}