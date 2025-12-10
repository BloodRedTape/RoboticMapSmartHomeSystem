import 'dart:async';
import 'dart:convert';
import 'package:dart_common/common/device.dart';
import 'package:dart_common/common/human.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends Cubit<bool> {
  WebSocketChannel? _channel;
  final String url;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  final _humanController = StreamController<List<Human>>.broadcast();
  final _deviceController = StreamController<List<Device>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<List<Human>> get humanStream => _humanController.stream;
  Stream<List<Device>> get deviceStream => _deviceController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  WebSocketService({required this.url}) : super(false);

  void connect() {
    if (_isDisposed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _connectionController.add(true);

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          _connectionController.add(false);
          _scheduleReconnect();
        },
      );

      emit(true);
    } catch (e) {
      _connectionController.add(false);
      _scheduleReconnect();
      emit(false);
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final type = json['type'] as String?;

      switch (type) {
        case 'human_update':
          final presenceList = (json['data'] as List).map((p) => Human.fromJson(p)).toList();
          _humanController.add(presenceList);
          break;
        case 'device_update':
          final deviceList = (json['data'] as List).map((d) => Device.fromJson(d)).toList();
          print('device update');
          _deviceController.add(deviceList);
          break;
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _humanController.close();
    _deviceController.close();
    _connectionController.close();
  }
}
