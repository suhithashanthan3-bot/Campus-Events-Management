import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../models/rsvp_model.dart';
import '../models/feedback_model.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {

  static String get baseUrl {
    if (kIsWeb) {
      // For web - use localhost (works on any computer)
      return 'http://127.0.0.1:5000';
    } else if (Platform.isAndroid) {
      // For Android emulator - use special address
      return 'http://10.0.2.2:5000';
    } else {
      // For everything else (iOS, desktop)
      return 'http://127.0.0.1:5000';
    }
  }

  // Headers for API requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // GET all events
  Future<List<Event>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET single event by ID
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Event not found');
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==================== RSVP ENDPOINTS ====================

  // POST new RSVP
  Future<Map<String, dynamic>> createRsvp({
    required String eventId,
    required String name,
    required String email,
    required String studentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rsvps'),
        headers: headers,
        body: json.encode({
          'eventId': eventId,
          'name': name,
          'email': email,
          'studentId': studentId,
          'status': 'confirmed',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create RSVP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET all RSVPs for a user
  Future<List<dynamic>> getUserRsvps(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rsvps?studentId=$studentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load RSVPs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==================== FEEDBACK ENDPOINTS ====================

  // POST new feedback
  Future<Map<String, dynamic>> createFeedback({
    required String eventId,
    required String name,
    required String email,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: headers,
        body: json.encode({
          'eventId': eventId,
          'name': name,
          'email': email,
          'rating': rating,
          'comment': comment,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET all feedback for an event
  Future<List<dynamic>> getEventFeedback(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedback?eventId=$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  // Check if API is reachable
  Future<bool> checkApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}