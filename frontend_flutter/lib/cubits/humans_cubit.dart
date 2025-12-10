import 'package:dart_common/dart_common.dart';
import 'package:frontend_flutter/services/websocket_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HumansCubit extends Cubit<List<Human>> {
  WebSocketService ws;

  HumansCubit(this.ws) : super([]) {
    ws.humanStream.listen(_updateHumans);
  }

  void _updateHumans(List<Human> humans) {
    emit(humans);
    print('HumansCubit: humans update');

    for (final h in humans) {
      print('${h.x}, ${h.y}');
    }
  }
}
