import 'package:dart_common/common/event_data.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<EventData> events = [];
  bool isLoading = false;
  String? selectedRoom;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() {
      isLoading = true;
    });

    try {
      var uri = Uri.parse('http://localhost:5000/api/events');
      final params = <String, String>{};

      if (selectedRoom != null) {
        params['room_id'] = selectedRoom!;
      }
      if (startDate != null) {
        params['start'] = startDate!.toIso8601String();
      }
      if (endDate != null) {
        params['end'] = endDate!.toIso8601String();
      }

      if (params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          events = data.map((e) => EventData.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events History'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadEvents),
        ],
      ),
      body: Column(
        children: [
          if (selectedRoom != null || startDate != null || endDate != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Filters active', style: const TextStyle(fontSize: 12))),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedRoom = null;
                        startDate = null;
                        endDate = null;
                      });
                      loadEvents();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : events.isEmpty
                    ? const Center(child: Text('No events found'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(_getEventIcon(event.type)),
                            title: Text(_getEventTitle(event.type)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.timestamp),
                                if (event.roomId != null) Text('Room: ${event.roomId}'),
                                if (event.data != null) ..._formatEventData(event.data!),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  List<Widget> _formatEventData(Map<String, dynamic> data) {
    final List<Widget> widgets = [];
    data.forEach((key, value) {
      if (key == 'x' || key == 'y') {
        widgets.add(Text('$key: ${value.toStringAsFixed(2)}'));
      } else {
        widgets.add(Text('$key: $value'));
      }
    });
    return widgets;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Events'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Room ID'),
                  onChanged: (value) {
                    selectedRoom = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(startDate?.toString() ?? 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        startDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(endDate?.toString() ?? 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        endDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  loadEvents();
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'presence_detected':
        return Icons.person;
      case 'presence_lost':
        return Icons.person_outline;
      case 'device_command':
        return Icons.settings_remote;
      case 'automation_triggered':
        return Icons.play_arrow;
      default:
        return Icons.info;
    }
  }

  String _getEventTitle(String type) {
    switch (type) {
      case 'presence_detected':
        return 'Presence Detected';
      case 'presence_lost':
        return 'Presence Lost';
      case 'device_command':
        return 'Device Command';
      case 'automation_triggered':
        return 'Automation Triggered';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
