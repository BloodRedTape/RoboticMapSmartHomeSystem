import 'dart:convert';
import 'dart:io';

import 'package:dart_common/common/automation.dart';
import 'package:uuid/uuid.dart';
import '../models/automation.dart';

class AutomationManager {
  final String _filePath;
  List<AutomationRuntime> _automations = [];

  AutomationManager(this._filePath) {
    _loadAutomations();
  }

  Future<void> _loadAutomations() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _automations = jsonList.map((json) => AutomationRuntime(automation: Automation.fromJson(json))).toList();
      }
    } catch (e) {
      print('Error loading automations: $e');
    }
  }

  Future<void> _saveAutomations() async {
    try {
      final file = File(_filePath);
      final jsonList = _automations.map((runtime) => runtime.automation.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving automations: $e');
    }
  }

  List<Automation> getAutomations() {
    return _automations.map((r) => r.automation).toList();
  }

  Automation createAutomation(AutomationInfo info) {
    final newAutomation = AutomationRuntime(automation: Automation(guid: Uuid().v4(), info: info));
    _automations.add(newAutomation);
    _saveAutomations();
    return newAutomation.automation;
  }

  Automation? updateAutomation(String guid, AutomationInfo info) {
    final index = _automations.indexWhere((a) => a.automation.guid == guid);
    if (index != -1) {
      _automations[index].automation.info = info;
      _saveAutomations();
      return _automations[index].automation;
    }
    return null;
  }

  void deleteAutomation(String guid) {
    _automations.removeWhere((a) => a.automation.guid == guid);
    _saveAutomations();
  }
}
