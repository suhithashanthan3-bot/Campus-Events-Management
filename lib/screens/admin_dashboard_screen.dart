import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'add_edit_event_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _rsvps = [];
  List<Map<String, dynamic>> _users = [];
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
      // Fetch events
      final eventsResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/events'),
        headers: AuthService.getAuthHeaders(),
      );

      // Fetch RSVPs
      final rsvpsResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/rsvps'),
        headers: AuthService.getAuthHeaders(),
      );

      // Fetch users
      final usersResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/users'),
        headers: AuthService.getAuthHeaders(),
      );

      if (eventsResponse.statusCode == 200) {
        List<dynamic> events = json.decode(eventsResponse.body);
        _events = events.map<Map<String, dynamic>>((event) {
          return {
            'id': event['id'] ?? 0,
            'title': event['title'] ?? 'Untitled Event',
            'description': event['description'] ?? '',
            'date': event['date'] ?? '',
            'time': event['time'] ?? '',
            'location': event['location'] ?? '',
            'capacity': event['capacity'] ?? 0,
            'attendees': event['attendees'] ?? 0,
            'status': event['status'] ?? 'upcoming',
            'imageUrl': event['imageUrl'] ?? '',
          };
        }).toList();
      }

      if (rsvpsResponse.statusCode == 200) {
        List<dynamic> rsvps = json.decode(rsvpsResponse.body);
        _rsvps = rsvps.map<Map<String, dynamic>>((rsvp) {
          return {
            'id': rsvp['id'] ?? 0,
            'eventId': rsvp['eventId'] ?? 0,
            'userId': rsvp['userId'] ?? 0,
            'name': rsvp['name'] ?? '',
            'email': rsvp['email'] ?? '',
            'studentId': rsvp['studentId'] ?? '',
            'status': rsvp['status'] ?? 'confirmed',
            'timestamp': rsvp['timestamp'] ?? '',
          };
        }).toList();
      }

      if (usersResponse.statusCode == 200) {
        List<dynamic> users = json.decode(usersResponse.body);
        _users = users.map<Map<String, dynamic>>((user) {
          return {
            'id': user['id'] ?? 0,
            'name': user['name'] ?? '',
            'email': user['email'] ?? '',
            'role': user['role'] ?? 'student',
          };
        }).toList();
      }

    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(int eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/admin/events/$eventId'),
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        _loadData(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getEventRsvpCount(int eventId) {
    try {
      return _rsvps.where((rsvp) {
        int rsvpEventId = rsvp['eventId'] is int
            ? rsvp['eventId']
            : int.tryParse(rsvp['eventId'].toString()) ?? 0;
        String status = rsvp['status'] ?? '';
        return rsvpEventId == eventId && status == 'confirmed';
      }).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.event), text: 'Events'),
              Tab(icon: Icon(Icons.people), text: 'RSVPs'),
              Tab(icon: Icon(Icons.person), text: 'Users'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            // EVENTS TAB
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Events: ${_events.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEditEventScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      final rsvpCount = _getEventRsvpCount(event['id'] ?? 0);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              event['imageUrl'] ?? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (event['title'] ?? '?')[0].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            event['title'] ?? 'Untitled Event',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${event['date'] ?? ''} at ${event['time'] ?? ''}'),
                              Text(event['location'] ?? ''),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Description', event['description'] ?? ''),
                                  const Divider(),
                                  _buildInfoRow('Capacity', '${event['capacity'] ?? 0}'),
                                  _buildInfoRow('Attendees', '${event['attendees'] ?? 0}'),
                                  _buildInfoRow('RSVPs', '$rsvpCount confirmed'),
                                  _buildInfoRow('Status', event['status'] ?? 'upcoming'),
                                  if (event['imageUrl'] != null && event['imageUrl'].toString().isNotEmpty)
                                    _buildInfoRow('Image', event['imageUrl'].toString()),
                                ],
                              ),
                            ),
                            ButtonBar(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditEventScreen(event: event),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  label: const Text('Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteEvent(event['id'] ?? 0),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // RSVPS TAB
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Total RSVPs: ${_rsvps.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Confirmed: ${_rsvps.where((r) => r['status'] == 'confirmed').length}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Cancelled: ${_rsvps.where((r) => r['status'] == 'cancelled').length}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rsvps.length,
                    itemBuilder: (context, index) {
                      final rsvp = _rsvps[index];

                      // Find the matching event safely
                      String eventTitle = 'Unknown Event';
                      String? eventImage;
                      try {
                        final matchingEvent = _events.firstWhere(
                              (e) {
                            int eventId = e['id'] is int ? e['id'] : int.tryParse(e['id'].toString()) ?? 0;
                            int rsvpEventId = rsvp['eventId'] is int ? rsvp['eventId'] : int.tryParse(rsvp['eventId'].toString()) ?? 0;
                            return eventId == rsvpEventId;
                          },
                        );
                        eventTitle = matchingEvent['title'] ?? 'Unknown Event';
                        eventImage = matchingEvent['imageUrl'];
                      } catch (e) {
                        // No matching event found
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              eventImage ?? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: rsvp['status'] == 'confirmed'
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (rsvp['name'] ?? '?')[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: rsvp['status'] == 'confirmed'
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text(rsvp['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Event: $eventTitle'),
                              Text('Student ID: ${rsvp['studentId'] ?? ''}'),
                              Text('Email: ${rsvp['email'] ?? ''}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rsvp['status'] == 'confirmed'
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (rsvp['status'] ?? '').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // USERS TAB
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Total Users: ${_users.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Admins: ${_users.where((u) => u['role'] == 'admin').length}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Students: ${_users.where((u) => u['role'] == 'student').length}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final userRsvps = _rsvps.where((r) {
                        int userId = r['userId'] is int ? r['userId'] : int.tryParse(r['userId'].toString()) ?? 0;
                        return userId == (user['id'] ?? 0);
                      }).length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user['role'] == 'admin'
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                            child: Text(
                              (user['name'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(user['name'] ?? 'Unknown'),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user['role'] == 'admin'
                                      ? Colors.blue
                                      : Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (user['role'] ?? '').toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$userRsvps RSVPs',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}