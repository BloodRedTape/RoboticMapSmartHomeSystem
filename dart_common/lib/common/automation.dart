import 'package:dart_common/common/automation/event_selects.dart';
export 'package:dart_common/common/automation/event_selects.dart';
import 'package:dart_common/common/commands.dart';
export 'package:dart_common/common/commands.dart';

class AutomationInfo {
  List<EventSelect> eventSelect = [];
  List<Command> commands = [];
  List<Command> elseCommands = [];
  String? eventType;

  AutomationInfo({required this.eventSelect, required this.commands, this.elseCommands = const [], this.eventType});

  factory AutomationInfo.fromJson(Map<String, dynamic> json) {
    return AutomationInfo(
      eventSelect: (json['event_select'] as List).map((e) => EventSelect.fromJson(e as Map<String, dynamic>)).toList(),
      commands: (json['commands'] as List).map((e) => Command.fromJson(e as Map<String, dynamic>)).toList(),
      elseCommands: (json['else_commands'] as List?)?.map((e) => Command.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      eventType: json['event_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_select': eventSelect.map((e) => e.toJson()).toList(),
      'commands': commands.map((e) => e.toJson()).toList(),
      'else_commands': elseCommands.map((e) => e.toJson()).toList(),
      'event_type': eventType,
    };
  }

  bool get isComplete {
    return commands.isNotEmpty && eventSelect.isNotEmpty;
  }
}

class Automation {
  String guid;
  AutomationInfo info;

  Automation({required this.guid, required this.info});

  factory Automation.fromJson(Map<String, dynamic> json) {
    return Automation(guid: json['guid'], info: AutomationInfo.fromJson(json['info']));
  }

  Map<String, dynamic> toJson() {
    return {'guid': guid, 'info': info.toJson()};
  }
}
