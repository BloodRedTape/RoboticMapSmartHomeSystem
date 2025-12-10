import 'package:dart_common/dart_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/automation_cubit.dart';
import 'package:frontend_flutter/tabs/automations/command_widget.dart';
import 'package:frontend_flutter/tabs/automations/event_widget.dart';
import 'package:dart_common/common/automation/events.dart';

class AutomationEditor extends StatefulWidget {
  final Automation? automation;

  const AutomationEditor({Key? key, this.automation}) : super(key: key);

  @override
  State<AutomationEditor> createState() => _AutomationEditorState();
}

class _AutomationEditorState extends State<AutomationEditor> {
  late AutomationInfo _automationInfo;

  @override
  void initState() {
    super.initState();
    _automationInfo = widget.automation?.info ?? AutomationInfo(eventSelect: [], commands: [], elseCommands: []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.automation == null ? 'Створити автоматизацію' : 'Редагувати автоматизацію'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (!_automationInfo.isComplete) return;
              final cubit = context.read<AutomationCubit>();
              if (widget.automation == null) {
                await cubit.createAutomation(_automationInfo);
              } else {
                await cubit.updateAutomation(widget.automation!.guid, _automationInfo);
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _automationInfo.eventType,
                decoration: const InputDecoration(labelText: 'Тип події'),
                hint: const Text('Оберіть тип події'),
                onChanged: (String? newValue) {
                  setState(() {
                    _automationInfo.eventType = newValue;
                  });
                },
                items: <String>[
                  HumanLocationChangedEvent.staticType,
                  HumanCountChangedEvent.staticType,
                  SwitchChangedEvent.staticType,
                  SensorChangedEvent.staticType,
                ].map<DropdownMenuItem<String>>((String value) {
                  String displayName = value;
                  if (value == HumanLocationChangedEvent.staticType) {
                    displayName = '$value (Зміна розташування людини)';
                  } else if (value == HumanCountChangedEvent.staticType) {
                    displayName = '$value (Зміна кількості людей)';
                  } else if (value == SwitchChangedEvent.staticType) {
                    displayName = '$value (Зміна стану перемикача)';
                  } else if (value == SensorChangedEvent.staticType) {
                    displayName = '$value (Зміна показань сенсора)';
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(displayName),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Умови'),
              ..._automationInfo.eventSelect.asMap().entries.map((entry) {
                final index = entry.key;
                final eventSelect = entry.value;
                return EventSelectWidget(
                  eventSelect: eventSelect,
                  onChanged: (newEventSelect) {
                    setState(() {
                      _automationInfo.eventSelect[index] = newEventSelect;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _automationInfo.eventSelect.removeAt(index);
                    });
                  },
                );
              }),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => AddConditionSheet(
                          onSelected: (newSelect) {
                            setState(() {
                              _automationInfo.eventSelect.add(newSelect);
                            });
                          },
                          eventType: _automationInfo.eventType,
                        ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Додати умову'),
              ),
              const SizedBox(height: 16),
              Text('Дії'),
              ..._automationInfo.commands.asMap().entries.map((entry) {
                final index = entry.key;
                final command = entry.value;
                return CommandWidget(
                  command: command,
                  onChanged: (newCommand) {
                    setState(() {
                      _automationInfo.commands[index] = newCommand;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _automationInfo.commands.removeAt(index);
                    });
                  },
                );
              }),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => AddActionSheet(
                          onSelected: (newCommand) {
                            setState(() {
                              _automationInfo.commands.add(newCommand);
                            });
                            Navigator.pop(context);
                          },
                        ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Додати дію'),
              ),
              const SizedBox(height: 16),
              Text('Альтернативні дії'),
              ..._automationInfo.elseCommands.asMap().entries.map((entry) {
                final index = entry.key;
                final command = entry.value;
                return CommandWidget(
                  command: command,
                  onChanged: (newCommand) {
                    setState(() {
                      _automationInfo.elseCommands[index] = newCommand;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _automationInfo.elseCommands.removeAt(index);
                    });
                  },
                );
              }),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => AddActionSheet(
                          onSelected: (newCommand) {
                            setState(() {
                              _automationInfo.elseCommands.add(newCommand);
                            });
                            Navigator.pop(context);
                          },
                        ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Додати альтернативну дію'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddActionSheet extends StatelessWidget {
  final ValueChanged<Command> onSelected;

  const AddActionSheet({Key? key, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ListTile(
          leading: const Icon(Icons.power),
          title: const Text('Керування перемикачем'),
          onTap: () {
            onSelected(SwitchCommand(guid: '', attributeGuid: '', state: 'on'));
          },
        ),
        ListTile(
          leading: const Icon(Icons.sunny),
          title: const Text('Керування яскравістю'),
          onTap: () {
            onSelected(BrightnessCommand(guid: '', attributeGuid: '', brightness: 0));
          },
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('Керування кольором'),
          onTap: () {
            onSelected(ColorCommand(guid: '', attributeGuid: '', rgbColor: [255, 255, 255]));
          },
        ),
        ListTile(
          leading: const Icon(Icons.rotate_right),
          title: const Text('Поворот на кут'),
          onTap: () {
            onSelected(RotateByAngleCommand(guid: '', attributeGuid: '', angle: 0));
          },
        ),
        ListTile(
          leading: const Icon(Icons.navigation),
          title: const Text('Поворот до місця'),
          onTap: () {
            onSelected(RotateToLocationAttributeCommand(guid: '', attributeGuid: '', locationAttributeGuid: ''));
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Поворот до найближчої людини'),
          onTap: () {
            onSelected(RotateToNearestHumanCommand(guid: '', attributeGuid: ''));
          },
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: const Text('Прибирання кімнати пилососом'),
          onTap: () {
            onSelected(VacuumCleanRoomCommand(guid: '', attributeGuid: '', roomId: ''));
          },
        ),
        ListTile(
          leading: const Icon(Icons.pause_circle),
          title: const Text('Пауза/продовження пилососа'),
          onTap: () {
            onSelected(VacuumPauseResumeCommand(guid: '', attributeGuid: '', paused: true));
          },
        ),
        ListTile(
          leading: const Icon(Icons.speed),
          title: const Text('Потужність всмоктування пилососа'),
          onTap: () {
            onSelected(VacuumFanSpeedCommand(guid: '', attributeGuid: '', fanSpeed: ''));
          },
        ),
        ListTile(
          leading: const Icon(Icons.window),
          title: const Text('Керування шторами'),
          onTap: () {
            onSelected(CoverCommand(guid: '', attributeGuid: '', action: 'open'));
          },
        ),
        ListTile(
          leading: const Icon(Icons.vertical_align_center),
          title: const Text('Позиція штор'),
          onTap: () {
            onSelected(CoverPositionCommand(guid: '', attributeGuid: '', position: 50));
          },
        ),
      ],
    );
  }
}
