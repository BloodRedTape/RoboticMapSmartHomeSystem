// Remember to add new command widgets here when new commands are introduced.
import 'package:dart_common/dart_common.dart';
import 'package:flutter/material.dart';
import 'package:frontend_flutter/tabs/automations/attribute_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CommandWidget extends StatelessWidget {
  final Command command;
  final ValueChanged<Command> onChanged;
  final VoidCallback onRemove;

  const CommandWidget({Key? key, required this.command, required this.onChanged, required this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (command is SwitchCommand) {
      child = SwitchCommandWidget(command: command as SwitchCommand, onChanged: onChanged);
    } else if (command is BrightnessCommand) {
      child = BrightnessCommandWidget(command: command as BrightnessCommand, onChanged: onChanged);
    } else if (command is ColorCommand) {
      child = ColorCommandWidget(command: command as ColorCommand, onChanged: onChanged);
    } else if (command is RotateByAngleCommand) {
      child = RotateByAngleCommandWidget(command: command as RotateByAngleCommand, onChanged: onChanged);
    } else if (command is RotateToLocationAttributeCommand) {
      child = RotateToLocationAttributeCommandWidget(command: command as RotateToLocationAttributeCommand, onChanged: onChanged);
    } else if (command is RotateToNearestHumanCommand) {
      child = RotateToNearestHumanCommandWidget(command: command as RotateToNearestHumanCommand, onChanged: onChanged);
    } else if (command is VacuumCleanRoomCommand) {
      child = VacuumCleanRoomCommandWidget(command: command as VacuumCleanRoomCommand, onChanged: onChanged);
    } else if (command is VacuumPauseResumeCommand) {
      child = VacuumPauseResumeCommandWidget(command: command as VacuumPauseResumeCommand, onChanged: onChanged);
    } else if (command is VacuumFanSpeedCommand) {
      child = VacuumFanSpeedCommandWidget(command: command as VacuumFanSpeedCommand, onChanged: onChanged);
    } else if (command is CoverCommand) {
      child = CoverCommandWidget(command: command as CoverCommand, onChanged: onChanged);
    } else if (command is CoverPositionCommand) {
      child = CoverPositionCommandWidget(command: command as CoverPositionCommand, onChanged: onChanged);
    } else {
      child = Card(child: ListTile(title: Text(command.type), subtitle: Text(command.attributeGuid)));
    }

    return Row(children: [Expanded(child: child), IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onRemove)]);
  }
}

class RotateToNearestHumanCommandWidget extends StatelessWidget {
  final RotateToNearestHumanCommand command;
  final ValueChanged<RotateToNearestHumanCommand> onChanged;

  const RotateToNearestHumanCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Повернути до найближчої людини'),
            CommandTargetAttributePicker(
              text: 'Оберіть атрибут обертання',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(RotateToNearestHumanCommand(guid: command.guid, attributeGuid: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RotateByAngleCommandWidget extends StatelessWidget {
  final RotateByAngleCommand command;
  final ValueChanged<RotateByAngleCommand> onChanged;

  const RotateByAngleCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Повернути на заданий кут'),
            CommandTargetAttributePicker(
              text: 'Оберіть атрибут обертання',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(RotateByAngleCommand(guid: command.guid, attributeGuid: value, angle: command.angle));
                }
              },
            ),
            Slider(
              value: command.angle,
              min: -180,
              max: 180,
              divisions: 360,
              label: command.angle.round().toString(),
              onChanged: (value) {
                onChanged(RotateByAngleCommand(guid: command.guid, attributeGuid: command.attributeGuid, angle: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RotateToLocationAttributeCommandWidget extends StatelessWidget {
  final RotateToLocationAttributeCommand command;
  final ValueChanged<RotateToLocationAttributeCommand> onChanged;

  const RotateToLocationAttributeCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Повернути до заданої локації'),
            CommandTargetAttributePicker(
              text: 'Оберіть атрибут обертання',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(RotateToLocationAttributeCommand(guid: command.guid, attributeGuid: value, locationAttributeGuid: command.locationAttributeGuid));
                }
              },
            ),
            AttributePicker(
              text: 'Оберіть цільовий атрибут локації',
              filter: (attribute) => attribute is LocationAttribute,
              onChanged: (value) {
                if (value != null) {
                  onChanged(RotateToLocationAttributeCommand(guid: command.guid, attributeGuid: command.attributeGuid, locationAttributeGuid: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ColorCommandWidget extends StatelessWidget {
  final ColorCommand command;
  final ValueChanged<ColorCommand> onChanged;

  const ColorCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color.fromRGBO(command.rgbColor[0], command.rgbColor[1], command.rgbColor[2], 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Встановити колір світла'),
            CommandTargetAttributePicker(
              text: 'Оберіть світло',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(ColorCommand(guid: command.guid, attributeGuid: value, rgbColor: command.rgbColor));
                }
              },
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    Color pickerColor = color;
                    return AlertDialog(
                      title: const Text('Оберіть колір'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: pickerColor,
                          onColorChanged: (Color color) {
                            pickerColor = color;
                          },
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Підтвердити'),
                          onPressed: () {
                            final newRgb = [pickerColor.red, pickerColor.green, pickerColor.blue];
                            onChanged(ColorCommand(guid: command.guid, attributeGuid: command.attributeGuid, rgbColor: newRgb));
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                child: const Center(child: Text('Натисніть, щоб змінити колір', style: TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 2)]))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrightnessCommandWidget extends StatelessWidget {
  final BrightnessCommand command;
  final ValueChanged<BrightnessCommand> onChanged;

  const BrightnessCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Встановити яскравість світла'),
            CommandTargetAttributePicker(
              text: 'Оберіть світло',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(BrightnessCommand(guid: command.guid, attributeGuid: value, brightness: command.brightness));
                }
              },
            ),
            Slider(
              value: command.brightness.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: command.brightness.round().toString(),
              onChanged: (value) {
                onChanged(BrightnessCommand(guid: command.guid, attributeGuid: command.attributeGuid, brightness: value.toInt()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SwitchCommandWidget extends StatelessWidget {
  final SwitchCommand command;
  final ValueChanged<SwitchCommand> onChanged;

  const SwitchCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Керувати перемикачем'),
            CommandTargetAttributePicker(
              text: 'Оберіть перемикач',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(SwitchCommand(guid: command.guid, attributeGuid: value, state: command.state));
                }
              },
            ),
            DropdownButton<String>(
              value: command.state,
              items: const [
                DropdownMenuItem(value: 'on', child: Text('Увімкнути')),
                DropdownMenuItem(value: 'off', child: Text('Вимкнути')),
                DropdownMenuItem(value: 'toggle', child: Text('Перемкнути')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(SwitchCommand(guid: command.guid, attributeGuid: command.attributeGuid, state: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CoverCommandWidget extends StatelessWidget {
  final CoverCommand command;
  final ValueChanged<CoverCommand> onChanged;

  const CoverCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Керувати жалюзями'),
            CommandTargetAttributePicker(
              text: 'Оберіть жалюзі',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(CoverCommand(guid: command.guid, attributeGuid: value, action: command.action));
                }
              },
            ),
            DropdownButton<String>(
              value: command.action,
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Відкрити')),
                DropdownMenuItem(value: 'close', child: Text('Закрити')),
                DropdownMenuItem(value: 'stop', child: Text('Зупинити')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(CoverCommand(guid: command.guid, attributeGuid: command.attributeGuid, action: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CoverPositionCommandWidget extends StatelessWidget {
  final CoverPositionCommand command;
  final ValueChanged<CoverPositionCommand> onChanged;

  const CoverPositionCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Встановити позицію жалюзі'),
            CommandTargetAttributePicker(
              text: 'Оберіть жалюзі',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(CoverPositionCommand(guid: command.guid, attributeGuid: value, position: command.position));
                }
              },
            ),
            Slider(
              value: command.position.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '${command.position}%',
              onChanged: (value) {
                onChanged(CoverPositionCommand(guid: command.guid, attributeGuid: command.attributeGuid, position: value.toInt()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VacuumCleanRoomCommandWidget extends StatelessWidget {
  final VacuumCleanRoomCommand command;
  final ValueChanged<VacuumCleanRoomCommand> onChanged;

  const VacuumCleanRoomCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Пилососити кімнату'),
            CommandTargetAttributePicker(
              text: 'Оберіть пилосос',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(VacuumCleanRoomCommand(guid: command.guid, attributeGuid: value, roomId: command.roomId));
                }
              },
            ),
            AttributePicker(
              text: 'Оберіть кімнату',
              filter: (attribute) => false,
              onChanged: (value) {
                if (value != null) {
                  onChanged(VacuumCleanRoomCommand(guid: command.guid, attributeGuid: command.attributeGuid, roomId: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VacuumPauseResumeCommandWidget extends StatelessWidget {
  final VacuumPauseResumeCommand command;
  final ValueChanged<VacuumPauseResumeCommand> onChanged;

  const VacuumPauseResumeCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Призупинити або продовжити прибирання'),
            CommandTargetAttributePicker(
              text: 'Оберіть пилосос',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(VacuumPauseResumeCommand(guid: command.guid, attributeGuid: value, paused: command.paused));
                }
              },
            ),
            DropdownButton<bool>(
              value: command.paused,
              items: const [
                DropdownMenuItem(value: true, child: Text('Призупинити')),
                DropdownMenuItem(value: false, child: Text('Продовжити')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(VacuumPauseResumeCommand(guid: command.guid, attributeGuid: command.attributeGuid, paused: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VacuumFanSpeedCommandWidget extends StatelessWidget {
  final VacuumFanSpeedCommand command;
  final ValueChanged<VacuumFanSpeedCommand> onChanged;

  const VacuumFanSpeedCommandWidget({Key? key, required this.command, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Встановити потужність всмоктування'),
            CommandTargetAttributePicker(
              text: 'Оберіть пилосос',
              command: command,
              onChanged: (value) {
                if (value != null) {
                  onChanged(VacuumFanSpeedCommand(guid: command.guid, attributeGuid: value, fanSpeed: command.fanSpeed));
                }
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Потужність'),
              controller: TextEditingController(text: command.fanSpeed),
              onChanged: (value) {
                onChanged(VacuumFanSpeedCommand(guid: command.guid, attributeGuid: command.attributeGuid, fanSpeed: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}
