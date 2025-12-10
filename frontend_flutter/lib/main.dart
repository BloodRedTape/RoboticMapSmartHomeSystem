import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/automation_cubit.dart';
import 'package:frontend_flutter/cubits/map_cubit.dart';
import 'package:frontend_flutter/tabs/automations/automations_tab.dart';
import 'tabs/map/map_screen.dart';
import 'tabs/devices/devices_screen.dart';
import 'tabs/events/events_screen.dart';
import 'tabs/settings/settings_screen.dart';
import 'tabs/dashboard/dashboard_screen.dart';
import 'cubits/devices_cubit.dart';
import 'cubits/humans_cubit.dart';
import 'cubits/display_settings_cubit.dart';
import 'cubits/map_blocks_cubit.dart';
import 'cubits/map_doors_cubit.dart';
import 'services/websocket_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DisplaySettingsCubit()..loadSettings()),
        BlocProvider(create: (context) => MapBlocksCubit()),
        BlocProvider(create: (context) => MapDoorsCubit()),
        BlocProvider(create: (context) => MapCubit()..loadMap()),
        BlocProvider(create: (context) => WebSocketService(url: 'ws://localhost:5000/ws')..connect()),
      ],
      child: MaterialApp(
        title: 'Smart Home Map',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => DevicesCubit(context.read<WebSocketService>())..refreshAll()),
            BlocProvider(create: (context) => HumansCubit(context.read<WebSocketService>())),
            BlocProvider(create: (context) => AutomationCubit()),
          ],
          child: const MainScreen(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [const DashboardScreen(), MapScreenWidget(), const DevicesScreen(), const AutomationsTab(), const EventsScreen(), const SettingsScreen()];

  @override
  void initState() {
    super.initState();

    context.read<WebSocketService>().deviceStream.listen((devices) {
      if (mounted) {
        context.read<DevicesCubit>().updateFromWebSocket(devices);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.devices), label: 'Devices'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Automations'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
