import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/devices_cubit.dart';
import 'edit_device_info.dart';
import 'device_icon_utils.dart';

class DeviceVisibilityScreen extends StatefulWidget {
  const DeviceVisibilityScreen({super.key});

  @override
  State<DeviceVisibilityScreen> createState() => _DeviceVisibilityScreenState();
}

class _DeviceVisibilityScreenState extends State<DeviceVisibilityScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DevicesCubit>().refreshAll();
  }

  List<Device> filterDevices(List<Device> devices) {
    if (searchQuery.isEmpty) {
      return devices;
    }
    return devices.where((device) => device.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  int getHiddenCount(List<Device> devices) => devices.where((d) => d.hidden).length;
  int getVisibleCount(List<Device> devices) => devices.where((d) => !d.hidden).length;

  @override
  Widget build(BuildContext context) {
    context.watch<DevicesCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Devices'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<DevicesCubit>().refreshAll())],
      ),
      body: BlocBuilder<DevicesCubit, List<Device>>(
        builder: (context, visibleDevices) {
          final cubit = context.read<DevicesCubit>();
          final allDevices = cubit.allDevices;
          final filteredDevices = filterDevices(allDevices);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hidden devices will not appear on the map or in the device list',
                              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Total', allDevices.length.toString(), Icons.devices, Colors.blue),
                        _buildStatCard('Visible', getVisibleCount(allDevices).toString(), Icons.visibility, Colors.green),
                        _buildStatCard('Hidden', getHiddenCount(allDevices).toString(), Icons.visibility_off, Colors.orange),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search devices...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    filteredDevices.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                searchQuery.isEmpty ? 'No devices found' : 'No devices match your search',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDevices.length,
                          itemBuilder: (context, index) {
                            final device = filteredDevices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: device.hidden ? 1 : 2,
                              child: ListTile(
                                leading: Icon(
                                  DeviceIconUtils.getDeviceIcon(device),
                                  color: device.hidden ? Colors.grey : DeviceIconUtils.getDeviceColor(device),
                                  size: 32,
                                ),
                                title: Text(
                                  device.name,
                                  style: TextStyle(
                                    color: device.hidden ? Colors.grey : Colors.black,
                                    decoration: device.hidden ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${device.attributes.length} attribute(s)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    if (device.hidden)
                                      Container(
                                        margin: EdgeInsets.only(top: 4),
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                        child: Text('Hidden from map and list', style: TextStyle(fontSize: 10, color: Colors.orange[800])),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showDeviceEditDialog(context, device),
                                      tooltip: 'Edit device',
                                    ),
                                    Switch(
                                      value: !device.hidden,
                                      onChanged: (value) async {
                                        try {
                                          await cubit.toggleDeviceVisibility(device.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(SnackBar(content: Text(value ? 'Device shown' : 'Device hidden'), duration: Duration(seconds: 1)));
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                          }
                                        }
                                      },
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeviceEditDialog(BuildContext context, Device device) async {
    final devices = context.read<DevicesCubit>();

    final result = await showDialog(
      context: context,
      builder:
          (context) => BlocProvider.value(
            value: devices,
            child: Dialog(child: Container(width: 500, padding: const EdgeInsets.all(24), child: DeviceEditForm(device: device))),
          ),
    );
    if (result == true && mounted) {
      await devices.refreshAll();
    }
  }
}
