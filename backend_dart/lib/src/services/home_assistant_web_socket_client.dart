import 'dart:async';
import 'package:backend_dart/src/models/home_assistant/ha_models.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';

class HomeAssistantWebSocketClient {
  late HomeAssistantWsApi _api;
  bool _isConnected = false;
  final Map<String, HaEntityState> _entityStates = {};
  List<HaEntityRegistry> _entityRegistryCache = [];
  CallbackHandle? _stateSubscription;
  void Function()? _onStateChanged;

  Future<void> connectAsync(String baseUrl, String token, bool verify) async {
    if (_isConnected) {
      print("Already connected to Home Assistant");
      return;
    }

    try {
      _api = HomeAssistantWsApi(
        baseUrl: baseUrl,
        onError: (error) => print("Home Assistant WebSocket error: $error"),
        onDone: () {
          print("Home Assistant WebSocket disconnected");
          _isConnected = false;
        },
      );

      bool connected = await _api.connect(unsafe: !verify);
      if (!connected) {
        throw Exception("Failed to establish WebSocket connection.");
      }

      Message authResponse = await _api.send('auth', {'access_token': token}, replyTypes: ['auth_ok', 'auth_invalid']);
      if (authResponse.type == 'auth_ok') {
        _isConnected = true;
        print("Connected to Home Assistant WebSocket API");

        await _loadInitialStates();
        _subscribeToStateChanges();
      } else {
        throw Exception("Authentication failed: ${authResponse.type}");
      }
    } catch (e) {
      print("Failed to connect to Home Assistant: $e");
      rethrow;
    }
  }

  Future<void> disconnectAsync() async {
    if (_isConnected) {
      _entityStates.clear();
      _stateSubscription = null;
      await _api.close();
      _isConnected = false;
      print("Disconnected from Home Assistant");
    }
  }

  Future<void> _loadInitialStates() async {
    try {
      print("Loading initial states from Home Assistant...");
      Message response = await _api.send('get_states', {});
      if (response.type == 'result' && response.data['result'] is List) {
        final states = (response.data['result'] as List).map((e) => HaEntityState.fromJson(e as Map<String, dynamic>)).toList();

        for (var state in states) {
          _entityStates[state.entityId] = state;
        }
        print("Loaded ${_entityStates.length} entity states");
      }
    } catch (e) {
      print("Failed to load initial states: $e");
    }
  }

  void _subscribeToStateChanges() {
    _stateSubscription = _api.sendCallback('subscribe_events', {'event_type': 'state_changed'}, (message) {
      if (message.type == 'event' && message.data['event'] is Map<String, dynamic>) {
        final event = message.data['event'] as Map<String, dynamic>;
        final eventData = event['data'] as Map<String, dynamic>;
        final stateEvent = HaStateChangedEvent.fromJson(eventData);

        if (stateEvent.newState != null) {
          _entityStates[stateEvent.entityId] = stateEvent.newState!;
        } else {
          _entityStates.remove(stateEvent.entityId);
        }

        if (_onStateChanged != null) {
          _onStateChanged!();
        }
      }
    }, once: false);
  }

  void setStateChangeCallback(void Function() callback) {
    _onStateChanged = callback;
  }

  List<HaEntityState> getStatesAsync() {
    _ensureConnected();
    return _entityStates.values.toList();
  }

  Future<List<HaEntityRegistry>> getEntityRegistryAsync() async {
    if (_entityRegistryCache.isNotEmpty) return _entityRegistryCache;

    _ensureConnected();

    try {
      Message response = await _api.send('config/entity_registry/list', {});
      if (response.type == 'result' && response.data['result'] is List) {
        _entityRegistryCache = (response.data['result'] as List).map((e) => HaEntityRegistry.fromJson(e as Map<String, dynamic>)).toList();
      }
      return _entityRegistryCache;
    } catch (e) {
      print("Failed to get entity registry from Home Assistant: $e");
      return [];
    }
  }

  Future<List<HaDeviceRegistry>> getDeviceRegistryAsync() async {
    _ensureConnected();

    try {
      Message response = await _api.send('config/device_registry/list', {});
      if (response.type == 'result' && response.data['result'] is List) {
        return (response.data['result'] as List).map((e) => HaDeviceRegistry.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print("Failed to get device registry from Home Assistant: $e");
      return [];
    }
  }

  Future<bool> callServiceAsync(String domain, String service, [Map<String, dynamic>? serviceData]) async {
    _ensureConnected();

    try {
      await _api.send('call_service', {'domain': domain, 'service': service, 'service_data': serviceData ?? {}});
      print("Called service $domain.$service");
      return true;
    } catch (e) {
      print("Failed to call service $domain.$service: $e");
      return false;
    }
  }

  void _ensureConnected() {
    if (!_isConnected) {
      throw StateError("Not connected to Home Assistant. Call connectAsync first.");
    }
  }
}
