import 'dart:async';
import 'dart:convert';

import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/services/data_storage.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class EventsController {
  final DataStorage _storage;

  EventsController(this._storage);

  Router get router {
    final router = Router();

    router.get('/api/events', _getEvents);

    return router;
  }

  Future<Response> _getEvents(Request request) async {
    final queryParams = request.url.queryParameters;
    final roomId = queryParams['room_id'];
    final start = queryParams['start'];
    final end = queryParams['end'];

    Iterable<EventData> filteredEvents = _storage.eventList;

    if (roomId != null && roomId.isNotEmpty) {
      filteredEvents = filteredEvents.where((e) => e.roomId == roomId);
    }

    if (start != null && start.isNotEmpty) {
      final startDt = DateTime.tryParse(start);
      if (startDt != null) {
        filteredEvents = filteredEvents.where(
          (e) => DateTime.tryParse(e.timestamp)?.isAtSameMomentAs(startDt) == true || DateTime.tryParse(e.timestamp)?.isAfter(startDt) == true,
        );
      }
    }

    if (end != null && end.isNotEmpty) {
      final endDt = DateTime.tryParse(end);
      if (endDt != null) {
        filteredEvents = filteredEvents.where(
          (e) => DateTime.tryParse(e.timestamp)?.isAtSameMomentAs(endDt) == true || DateTime.tryParse(e.timestamp)?.isBefore(endDt) == true,
        );
      }
    }

    print("[API] Returning ${filteredEvents.length} events");

    return Response.ok(jsonEncode(filteredEvents.map((e) => e.toJson()).toList()), headers: {'Content-Type': 'application/json'});
  }
}
