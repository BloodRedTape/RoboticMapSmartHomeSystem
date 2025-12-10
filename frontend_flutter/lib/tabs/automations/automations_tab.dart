import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/tabs/automations/automation_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/automation_cubit.dart';

class AutomationsTab extends StatefulWidget {
  const AutomationsTab({Key? key}) : super(key: key);

  @override
  State<AutomationsTab> createState() => _AutomationsTabState();
}

class _AutomationsTabState extends State<AutomationsTab> {
  @override
  void initState() {
    super.initState();
    context.read<AutomationCubit>().getAutomations();
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.read<DevicesCubit>();

    return Scaffold(
      body: BlocBuilder<AutomationCubit, AutomationState>(
        builder: (context, state) {
          final automations = context.read<AutomationCubit>();
          if (state.isLoading && state.automations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.error != null) {
            return Center(child: Text(state.error!));
          } else if (state.automations.isEmpty) {
            return const Center(child: Text('No automations found.'));
          } else {
            return ListView.builder(
              itemCount: state.automations.length,
              itemBuilder: (context, index) {
                final automation = state.automations[index];
                return ListTile(
                  title: Text(automation.guid),
                  subtitle: Text('Commands: ${automation.info.commands.length}, Conditions: ${automation.info.eventSelect.length}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BlocProvider.value(
                              value: automations,
                              child: BlocProvider.value(value: devices, child: AutomationEditor(automation: automation)),
                            ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final automations = context.read<AutomationCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(value: automations, child: BlocProvider.value(value: devices, child: AutomationEditor())),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
