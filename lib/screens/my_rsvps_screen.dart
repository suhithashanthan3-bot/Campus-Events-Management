import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'event_detail_screen.dart';
import '../models/event_model.dart';

class MyRsvpsScreen extends StatefulWidget {
  const MyRsvpsScreen({super.key});

  @override
  State<MyRsvpsScreen> createState() => _MyRsvpsScreenState();
}

class _MyRsvpsScreenState extends State<MyRsvpsScreen> {
  List<dynamic> _myRsvps = [];
  List<dynamic> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user's RSVPs
      final rsvpResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/my-rsvps'),
        headers: AuthService.getAuthHeaders(),
      );

      // Fetch all events to get event details
      final eventsResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/events'),
      );

      if (rsvpResponse.statusCode == 200 && eventsResponse.statusCode == 200) {
        setState(() {
          _myRsvps = json.decode(rsvpResponse.body);
          _events = json.decode(eventsResponse.body);
        });
      }
    } catch (e) {
      print('Error loading RSVPs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRsvp(dynamic rsvpId, dynamic eventId) async {
    // Convert to int safely
    int rsvpIdInt = int.tryParse(rsvpId.toString()) ?? 0;
    int eventIdInt = int.tryParse(eventId.toString()) ?? 0;

    if (rsvpIdInt == 0 || eventIdInt == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid RSVP data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Registration'),
        content: const Text('Are you sure you want to cancel your registration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/rsvps/$rsvpIdInt'),
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        throw Exception('Failed to cancel');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic>? _getEventDetails(dynamic eventId) {
    try {
      String targetId = eventId.toString();
      return _events.firstWhere((event) {
        String eventIdStr = event['id'].toString();
        return eventIdStr == targetId;
      });
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRsvps = _myRsvps.where((rsvp) => rsvp['status'] == 'confirmed').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Registrations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeRsvps.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No registrations yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Events you register for will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Browse Events'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeRsvps.length,
        itemBuilder: (context, index) {
          final rsvp = activeRsvps[index];
          final event = _getEventDetails(rsvp['eventId']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: event != null
                        ? Text(event['title'][0], style: const TextStyle(fontWeight: FontWeight.bold))
                        : const Icon(Icons.event),
                  ),
                  title: Text(
                    event != null ? event['title'] : 'Event #${rsvp['eventId']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('${event['date']} at ${event['time']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(event['location'],
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Registered on ${rsvp['timestamp'].substring(0, 10)}',
                              style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
                ButtonBar(
                  children: [
                    if (event != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(
                                event: Event(
                                  id: event['id'].toString(),
                                  title: event['title'] ?? '',
                                  description: event['description'] ?? '',
                                  date: event['date'] ?? '',
                                  time: event['time'] ?? '',
                                  location: event['location'] ?? '',
                                  capacity: event['capacity'] is int
                                      ? event['capacity']
                                      : int.tryParse(event['capacity'].toString()) ?? 0,
                                  attendees: event['attendees'] is int
                                      ? event['attendees']
                                      : int.tryParse(event['attendees'].toString()) ?? 0,
                                  status: event['status'] ?? 'upcoming',
                                  imageUrl: event['imageUrl'] ?? '',
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                      ),
                    TextButton.icon(
                      onPressed: () => _cancelRsvp(rsvp['id'], rsvp['eventId']),
                      icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                      label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}