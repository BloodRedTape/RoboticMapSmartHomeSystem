// device_screen.dart
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/tabs/devices/device.dart';
import '../../cubits/devices_cubit.dart';
import 'device_visibility_screen.dart';
import '../testing/matter_commission_fake_screen.dart';
import '../testing/homekit_pairing_fake_screen.dart';
import '../testing/zigbee_pairing_fake_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.read<DevicesCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_off),
            onPressed:
                () =>
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BlocProvider.value(value: devices, child: const DeviceVisibilityScreen()))),
            tooltip: 'Show/hide devices',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<DevicesCubit>().refresh()),
        ],
      ),
      body: BlocBuilder<DevicesCubit, List<Device>>(
        builder: (context, devices) {
          if (devices.isEmpty) {
            return const Center(child: Text('No devices found. Use debug menu to add test devices.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) => DeviceWidget(device: devices[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(context),
        tooltip: 'Add device',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final devicesCubit = context.read<DevicesCubit>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 32, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Додати пристрій',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Виберіть протокол підключення пристрою',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProtocolOption(
                  context,
                  icon: Icons.lightbulb_outline,
                  title: 'Matter',
                  subtitle: 'Сумісні з Matter пристрої',
                  color: Colors.purple,
                  logoUrl: 'https://www.smartblinds.at/media/wysiwyg/Logo_Matter.webp',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: devicesCubit,
                          child: const MatterCommissionFakeScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildProtocolOption(
                  context,
                  icon: Icons.power,
                  title: 'HomeKit',
                  subtitle: 'Apple HomeKit аксесуари',
                  color: Colors.teal,
                  logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Apple_HomeKit_logo.svg/250px-Apple_HomeKit_logo.svg.png',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: devicesCubit,
                          child: const HomeKitPairingFakeScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildProtocolOption(
                  context,
                  icon: Icons.thermostat,
                  title: 'Zigbee',
                  subtitle: 'Пристрої з протоколом Zigbee',
                  color: Colors.green,
                  logoUrl: 'https://www.blueroad.cz/user/articles/images/zigbee.jpg',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: devicesCubit,
                          child: const ZigbeePairingFakeScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProtocolOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? logoUrl,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: logoUrl != null
                  ? Image.network(logoUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 28))
                  : Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
