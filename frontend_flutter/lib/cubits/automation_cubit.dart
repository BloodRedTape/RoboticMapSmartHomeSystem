import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:dart_common/dart_common.dart';

class AutomationState {
  final List<Automation> automations;
  final bool isLoading;
  final String? error;

  AutomationState({
    this.automations = const [],
    this.isLoading = false,
    this.error,
  });

  AutomationState copyWith({
    List<Automation>? automations,
    bool? isLoading,
    String? error,
  }) {
    return AutomationState(
      automations: automations ?? this.automations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AutomationCubit extends Cubit<AutomationState> {
  final String _baseUrl = 'http://localhost:5000';

  AutomationCubit() : super(AutomationState());

  Future<void> getAutomations() async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await http.get(Uri.parse('$_baseUrl/automations'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final automations = data.map((d) => Automation.fromJson(d)).toList();
        emit(state.copyWith(automations: automations, isLoading: false));
      } else {
        emit(state.copyWith(error: 'Failed to load automations', isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> createAutomation(AutomationInfo info) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/automations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(info.toJson()),
      );
      if (response.statusCode == 200) {
        getAutomations();
      } else {
        emit(state.copyWith(error: 'Failed to create automation', isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> updateAutomation(String guid, AutomationInfo info) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/automations/$guid'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(info.toJson()),
      );
      if (response.statusCode == 200) {
        getAutomations();
      } else {
        emit(state.copyWith(error: 'Failed to update automation', isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> deleteAutomation(String guid) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/automations/$guid'));
      if (response.statusCode == 200) {
        getAutomations();
      } else {
        emit(state.copyWith(error: 'Failed to delete automation', isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }
}
