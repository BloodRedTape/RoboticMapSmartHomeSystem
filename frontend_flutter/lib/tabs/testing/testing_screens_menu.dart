import 'package:flutter/material.dart';
import 'map_import_fake_screen.dart';
import 'matter_commission_fake_screen.dart';
import 'homekit_pairing_fake_screen.dart';
import 'zigbee_pairing_fake_screen.dart';
import 'camera_setup_fake_screen.dart';
import 'camera_calibration_fake_screen.dart';

class TestingScreensMenu extends StatelessWidget {
  const TestingScreensMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Екрани для тестування'),
        backgroundColor: Colors.blueGrey.shade800,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Картографічна система'),
          _buildMenuItem(
            context,
            title: 'Імпорт карти приміщення',
            subtitle: 'Вибір джерела для імпорту карти',
            icon: Icons.map,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapImportFakeScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Інтеграція пристроїв'),
          _buildMenuItem(
            context,
            title: 'Комісування Matter-пристрою',
            subtitle: 'Процес додавання світильника Matter',
            icon: Icons.lightbulb_outline,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MatterCommissionFakeScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            title: 'Спарювання HomeKit-пристрою',
            subtitle: 'Додавання розумного перемикача через PIN',
            icon: Icons.power,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeKitPairingFakeScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            title: 'Додавання Zigbee-пристрою',
            subtitle: 'Підключення датчика через координатор',
            icon: Icons.thermostat,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ZigbeePairingFakeScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Виявлення присутності'),
          _buildMenuItem(
            context,
            title: 'Налаштування підключення камери',
            subtitle: 'Додавання камери з параметрами RTSP',
            icon: Icons.videocam,
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraSetupFakeScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            title: 'Калібрування камери',
            subtitle: 'Вибір опорних точок для гомографії',
            icon: Icons.camera_alt,
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraCalibrationFakeScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
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
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
