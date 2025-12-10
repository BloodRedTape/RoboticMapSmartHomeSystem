import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../testing/map_import_fake_screen.dart';
import '../testing/camera_setup_fake_screen.dart';
import '../testing/camera_calibration_fake_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController serverUrlController = TextEditingController(text: 'http://localhost:5000');
  final TextEditingController wsUrlController = TextEditingController(text: 'ws://localhost:5000/ws');
  bool enablePrivacyZones = true;
  bool enableCameras = true;
  int dataRetentionDays = 90;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  void dispose() {
    serverUrlController.dispose();
    wsUrlController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('${serverUrlController.text}/api/settings'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          enablePrivacyZones = data['enable_privacy_zones'] ?? true;
          enableCameras = data['enable_cameras'] ?? true;
          dataRetentionDays = data['data_retention_days'] ?? 90;
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

  Future<void> saveSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${serverUrlController.text}/api/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'enable_privacy_zones': enablePrivacyZones,
          'enable_cameras': enableCameras,
          'data_retention_days': dataRetentionDays,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> deleteHistoricalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Historical Data'),
        content: const Text('Are you sure you want to delete all historical data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await http.delete(Uri.parse('${serverUrlController.text}/api/history'));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Historical data deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isLoading ? null : saveSettings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Server Configuration', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: serverUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.http),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: wsUrlController,
                  decoration: const InputDecoration(
                    labelText: 'WebSocket URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cloud),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Картографія', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.blue),
                  title: const Text('Імпортувати карту'),
                  subtitle: const Text('Завантажити план приміщення'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapImportFakeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Камери', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.deepPurple),
                  title: const Text('Додати камеру'),
                  subtitle: const Text('Налаштувати нову камеру для детекції'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraSetupFakeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                  title: const Text('Калібрувати камеру'),
                  subtitle: const Text('Налаштувати проєкцію координат'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraCalibrationFakeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Privacy Settings', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Privacy Zones'),
                  subtitle: const Text('Allow defining areas where only aggregated data is stored'),
                  value: enablePrivacyZones,
                  onChanged: (value) {
                    setState(() {
                      enablePrivacyZones = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable Cameras'),
                  subtitle: const Text('Allow camera-based presence detection'),
                  value: enableCameras,
                  onChanged: (value) {
                    setState(() {
                      enableCameras = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Data Retention Period'),
                  subtitle: Text('$dataRetentionDays days'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showRetentionDialog(),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Data Management', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Historical Data'),
                  subtitle: const Text('Permanently delete all stored presence and event data'),
                  onTap: deleteHistoricalData,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Export Data'),
                  subtitle: const Text('Export all data to JSON format'),
                  onTap: () async {
                    try {
                      final response = await http.get(
                        Uri.parse('${serverUrlController.text}/api/export'),
                      );
                      if (response.statusCode == 200 && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data exported successfully')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('About', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                const ListTile(
                  leading: Icon(Icons.description),
                  title: Text('License'),
                  subtitle: Text('MIT License'),
                ),
              ],
            ),
    );
  }

  void _showRetentionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Retention Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select how long to keep historical data:'),
            const SizedBox(height: 16),
            ...[ 30, 60, 90, 180, 365].map((days) {
              return RadioListTile<int>(
                title: Text('$days days'),
                value: days,
                groupValue: dataRetentionDays,
                onChanged: (value) {
                  setState(() {
                    dataRetentionDays = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
