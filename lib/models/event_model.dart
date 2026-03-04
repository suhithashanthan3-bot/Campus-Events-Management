class Event {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final int capacity;
  final int attendees;
  final String status;
  final String imageUrl;
  final String? assetImage;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.capacity,
    required this.attendees,
    required this.status,
    this.imageUrl = 'https://via.placeholder.com/400x200',
    this.assetImage,
  });

  // Check if event has already happened
  bool get hasPassed {
    try {
      // Parse date (format: YYYY-MM-DD)
      List<String> dateParts = date.split('-');
      if (dateParts.length == 3) {
        int year = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);
        int day = int.parse(dateParts[2]);

        DateTime eventDate = DateTime(year, month, day);
        DateTime now = DateTime.now();

        // Compare dates (ignore time)
        return eventDate.isBefore(DateTime(now.year, now.month, now.day));
      }
      return false;
    } catch (e) {
      print('Error parsing date: $e');
      return false;
    }
  }

  // ✅ NEW: Get display status based on date
  String get displayStatus {
    if (hasPassed) {
      return 'completed';
    }
    return status; // 'upcoming' from database
  }

  // Convert JSON to Event object
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      capacity: json['capacity'] ?? 0,
      attendees: json['attendees'] ?? 0,
      status: json['status'] ?? 'upcoming',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/400x200',
    );
  }

  // Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'capacity': capacity,
      'attendees': attendees,
      'status': status,
      'imageUrl': imageUrl,
    };
  }
}