import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/automation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/map_cubit.dart';
import 'package:frontend_flutter/tabs/automations/attribute_picker.dart';

class EventSelectWidget extends StatelessWidget {
  final EventSelect eventSelect;
  final ValueChanged<EventSelect> onChanged;
  final VoidCallback? onRemove;

  const EventSelectWidget({Key? key, required this.eventSelect, required this.onChanged, this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (eventSelect is SwitchStateSelect) {
      child = SwitchStateSelectWidget(select: eventSelect as SwitchStateSelect, onChanged: onChanged);
    } else if (eventSelect is HumanCountSelect) {
      child = HumanCountSelectWidget(select: eventSelect as HumanCountSelect, onChanged: onChanged);
    } else if (eventSelect is HumanLocationSelect) {
      child = HumanLocationSelectWidget(select: eventSelect as HumanLocationSelect, onChanged: onChanged);
    } else if (eventSelect is EventSelectAnd) {
      child = EventSelectAndWidget(select: eventSelect as EventSelectAnd, onChanged: onChanged);
    } else if (eventSelect is EventSelectOr) {
      child = EventSelectOrWidget(select: eventSelect as EventSelectOr, onChanged: onChanged);
    } else if (eventSelect is HumanDeviceDistanceSelect) {
      child = HumanDeviceDistanceSelectWidget(select: eventSelect as HumanDeviceDistanceSelect, onChanged: onChanged);
    } else {
      child = Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(eventSelect.toString())));
    }

    return Row(children: [Expanded(child: child), if (onRemove != null) IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onRemove)]);
  }
}

class EventSelectAndWidget extends StatelessWidget {
  final EventSelectAnd select;
  final ValueChanged<EventSelectAnd> onChanged;

  const EventSelectAndWidget({Key? key, required this.select, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Всі умови (І)', style: Theme.of(context).textTheme.titleMedium),
            ...select.selects.asMap().entries.map((entry) {
              final index = entry.key;
              final childSelect = entry.value;
              return EventSelectWidget(
                eventSelect: childSelect,
                onChanged: (newEventSelect) {
                  final newSelects = List<EventSelect>.from(select.selects);
                  newSelects[index] = newEventSelect;
                  onChanged(EventSelectAnd(selects: newSelects));
                },
                onRemove: () {
                  final newSelects = List<EventSelect>.from(select.selects);
                  newSelects.removeAt(index);
                  onChanged(EventSelectAnd(selects: newSelects));
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
                          final newSelects = List<EventSelect>.from(select.selects)..add(newSelect);
                          onChanged(EventSelectAnd(selects: newSelects));
                          Navigator.pop(context);
                        },
                      ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Додати умову'),
            ),
          ],
        ),
      ),
    );
  }
}

class EventSelectOrWidget extends StatelessWidget {
  final EventSelectOr select;
  final ValueChanged<EventSelectOr> onChanged;

  const EventSelectOrWidget({Key? key, required this.select, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Будь-яка умова (АБО)', style: Theme.of(context).textTheme.titleMedium),
            ...select.selects.asMap().entries.map((entry) {
              final index = entry.key;
              final childSelect = entry.value;
              return EventSelectWidget(
                eventSelect: childSelect,
                onChanged: (newEventSelect) {
                  final newSelects = List<EventSelect>.from(select.selects);
                  newSelects[index] = newEventSelect;
                  onChanged(EventSelectOr(selects: newSelects));
                },
                onRemove: () {
                  final newSelects = List<EventSelect>.from(select.selects);
                  newSelects.removeAt(index);
                  onChanged(EventSelectOr(selects: newSelects));
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
                          final newSelects = List<EventSelect>.from(select.selects)..add(newSelect);
                          onChanged(EventSelectOr(selects: newSelects));
                          Navigator.pop(context);
                        },
                      ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Додати умову'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddConditionSheet extends StatelessWidget {
  final ValueChanged<EventSelect> onSelected;
  final String? eventType;

  const AddConditionSheet({Key? key, required this.onSelected, this.eventType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<({IconData icon, String title, EventSelect Function() create})> options = [
      (
        icon: Icons.power_settings_new,
        title: 'Стан перемикача',
        create: () => const SwitchStateSelect(isOn: true, attributeGuid: '')
      ),
      (
        icon: Icons.person,
        title: 'Кількість людей в кімнаті',
        create: () => const HumanCountSelect(roomGuid: '', targetCount: 0, operator: '=')
      ),
      (
        icon: Icons.location_on,
        title: 'Зміна розташування людини',
        create: () => const HumanLocationSelect(roomGuid: null)
      ),
      (
        icon: Icons.social_distance,
        title: 'Відстань людина-пристрій',
        create: () => const HumanDeviceDistanceSelect(deviceAttributeGuid: '', distance: 0, operator: '<', humanMatcher: 'any')
      ),
      (icon: Icons.call_split, title: 'Блок І', create: () => const EventSelectAnd(selects: [])),
      (icon: Icons.format_list_bulleted, title: 'Блок АБО', create: () => const EventSelectOr(selects: []))
    ];

    return Wrap(
      children: options
          .where((option) {
            if (eventType == null) return true; // Show all if no event type is selected
            final EventSelect tempSelect = option.create();
            // Special handling for AND/OR blocks
            if (tempSelect is EventSelectAnd || tempSelect is EventSelectOr) {
              return true;
            }
            // Filter other event selects based on eventType
            return tempSelect.supportsEventType(eventType!);
          })
          .map(
            (option) => ListTile(
              leading: Icon(option.icon),
              title: Text(option.title),
              onTap: () {
                onSelected(option.create());
                Navigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }
}

class SwitchStateSelectWidget extends StatelessWidget {
  final SwitchStateSelect select;
  final ValueChanged<SwitchStateSelect> onChanged;

  const SwitchStateSelectWidget({Key? key, required this.select, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Text('Перемикач змінився на '),
            Switch(
              value: select.isOn,
              onChanged: (value) {
                onChanged(SwitchStateSelect(isOn: value, attributeGuid: select.attributeGuid));
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AttributePicker(
                text: 'Оберіть перемикач',
                filter: (attr) => attr.type == 'switch',
                onChanged: (value) {
                  if (value != null) {
                    onChanged(SwitchStateSelect(isOn: select.isOn, attributeGuid: value));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HumanCountSelectWidget extends StatefulWidget {
  final HumanCountSelect select;
  final ValueChanged<HumanCountSelect> onChanged;

  const HumanCountSelectWidget({Key? key, required this.select, required this.onChanged}) : super(key: key);

  @override
  State<HumanCountSelectWidget> createState() => _HumanCountSelectWidgetState();
}

class _HumanCountSelectWidgetState extends State<HumanCountSelectWidget> {
  late TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(text: widget.select.targetCount.toString());
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<MapCubit>().state.mapData?.rooms.values.toList() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Кількість людей в кімнаті'),
            DropdownButtonFormField<String>(
              value: widget.select.roomGuid.isEmpty ? null : widget.select.roomGuid,
              decoration: const InputDecoration(labelText: 'Кімната'),
              hint: const Text('Оберіть кімнату'),
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  widget.onChanged(HumanCountSelect(roomGuid: value, targetCount: widget.select.targetCount, operator: widget.select.operator));
                }
              },
              items:
                  rooms.map((room) {
                    return DropdownMenuItem(value: room.guid, child: Text(room.name));
                  }).toList(),
            ),
            Row(
              children: [
                DropdownButton<String>(
                  value: widget.select.operator,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(HumanCountSelect(roomGuid: widget.select.roomGuid, targetCount: widget.select.targetCount, operator: value));
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: '>', child: Text('>')),
                    DropdownMenuItem(value: '<', child: Text('<')),
                    DropdownMenuItem(value: '=', child: Text('=')),
                  ],
                ),
                Expanded(
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Кількість'),
                    onChanged: (value) {
                      final count = int.tryParse(value);
                      if (count != null) {
                        widget.onChanged(HumanCountSelect(roomGuid: widget.select.roomGuid, targetCount: count, operator: widget.select.operator));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HumanLocationSelectWidget extends StatelessWidget {
  final HumanLocationSelect select;
  final ValueChanged<HumanLocationSelect> onChanged;

  const HumanLocationSelectWidget({Key? key, required this.select, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<MapCubit>().state.mapData?.rooms.values.toList() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Коли розташування людини змінилось в кімнаті:'),
            DropdownButton<String?>(
              value: select.roomGuid,
              hint: const Text('Будь-яка кімната'),
              onChanged: (value) {
                onChanged(HumanLocationSelect(roomGuid: value));
              },
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Будь-яка кімната')),
                ...rooms.map((room) {
                  return DropdownMenuItem<String?>(value: room.guid, child: Text(room.name));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HumanDeviceDistanceSelectWidget extends StatefulWidget {
  final HumanDeviceDistanceSelect select;
  final ValueChanged<HumanDeviceDistanceSelect> onChanged;

  const HumanDeviceDistanceSelectWidget({Key? key, required this.select, required this.onChanged}) : super(key: key);

  @override
  State<HumanDeviceDistanceSelectWidget> createState() => _HumanDeviceDistanceSelectWidgetState();
}

class _HumanDeviceDistanceSelectWidgetState extends State<HumanDeviceDistanceSelectWidget> {
  late TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController(text: widget.select.distance.toString());
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Коли'),
                DropdownButton<String>(
                  value: widget.select.humanMatcher,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(
                        HumanDeviceDistanceSelect(
                          deviceAttributeGuid: widget.select.deviceAttributeGuid,
                          distance: widget.select.distance,
                          operator: widget.select.operator,
                          humanMatcher: value,
                        ),
                      );
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'any', child: Text('будь-яка людина')),
                    DropdownMenuItem(value: 'all', child: Text('всі люди')),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                DropdownButton<String>(
                  value: widget.select.operator,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(
                        HumanDeviceDistanceSelect(
                            deviceAttributeGuid: widget.select.deviceAttributeGuid,
                            distance: widget.select.distance,
                            operator: value,
                            humanMatcher: widget.select.humanMatcher),
                      );
                    }
                  },
                  items: const [DropdownMenuItem(value: '>', child: Text('далі ніж')), DropdownMenuItem(value: '<', child: Text('ближче ніж'))],
                ),
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Відстань (м)'),
                    onChanged: (value) {
                      final distance = double.tryParse(value);
                      if (distance != null) {
                        widget.onChanged(
                          HumanDeviceDistanceSelect(
                            deviceAttributeGuid: widget.select.deviceAttributeGuid,
                            distance: distance,
                            operator: widget.select.operator,
                            humanMatcher: widget.select.humanMatcher,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const Text('від'),
            AttributePicker(
              text: 'Оберіть пристрій',
              filter: (attribute) => attribute is LocationAttribute,
              onChanged: (value) {
                if (value != null) {
                  widget.onChanged(HumanDeviceDistanceSelect(
                    deviceAttributeGuid: value,
                    distance: widget.select.distance,
                    operator: widget.select.operator,
                    humanMatcher: widget.select.humanMatcher,
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

