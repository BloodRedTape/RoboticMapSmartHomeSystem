import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/display_settings_cubit.dart';

class MapSettingsScreen extends StatelessWidget {
  const MapSettingsScreen({super.key});

  Future<void> saveSettings(BuildContext context) async {
    try {
      await context.read<DisplaySettingsCubit>().saveSettings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved'), duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<DisplaySettingsCubit>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await saveSettings(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Map Settings')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.zoom_in, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Device Icon Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Adjust the size of device icons on the map', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('0.5x', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Expanded(
                            child: BlocBuilder<DisplaySettingsCubit, DisplaySettings>(
                              builder: (context, settings) {
                                return Slider(
                                  value: settings.iconScale,
                                  min: 0.5,
                                  max: 2.0,
                                  divisions: 15,
                                  label: '${settings.iconScale.toStringAsFixed(1)}x',
                                  onChanged: (value) {
                                    context.read<DisplaySettingsCubit>().updateIconScale(value);
                                  },
                                );
                              },
                            ),
                          ),
                          Text('2.0x', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      BlocBuilder<DisplaySettingsCubit, DisplaySettings>(
                        builder: (context, settings) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                'Current: ${settings.iconScale.toStringAsFixed(1)}x',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Icons will maintain this size regardless of map zoom level',
                                style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<DisplaySettingsCubit, DisplaySettings>(
                builder: (context, displaySettings) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('Display Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Toggle visibility of map elements', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Show Device Labels'),
                            subtitle: const Text('Display names under device icons'),
                            value: displaySettings.showDeviceLabels,
                            onChanged: (value) {
                              context.read<DisplaySettingsCubit>().updateShowDeviceLabels(value);
                            },
                            secondary: const Icon(Icons.label),
                          ),
                          SwitchListTile(
                            title: const Text('Show Room Colors'),
                            subtitle: const Text('Paint rooms with assigned colors'),
                            value: displaySettings.showRoomColors,
                            onChanged: (value) {
                              context.read<DisplaySettingsCubit>().updateShowRoomColors(value);
                            },
                            secondary: const Icon(Icons.palette),
                          ),
                          SwitchListTile(
                            title: const Text('Show Room Labels'),
                            subtitle: const Text('Display room names on the map'),
                            value: displaySettings.showRoomLabels,
                            onChanged: (value) {
                              context.read<DisplaySettingsCubit>().updateShowRoomLabels(value);
                            },
                            secondary: const Icon(Icons.meeting_room),
                          ),
                          SwitchListTile(
                            title: const Text('Show Device Paths'),
                            subtitle: const Text('Display movement paths for tracked devices'),
                            value: displaySettings.showDevicePaths,
                            onChanged: (value) {
                              context.read<DisplaySettingsCubit>().updateShowDevicePaths(value);
                            },
                            secondary: const Icon(Icons.timeline),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
