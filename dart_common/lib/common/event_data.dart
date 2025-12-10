class EventData {
  String id;
  String type;
  String timestamp;
  String? roomId;
  Map<String, dynamic>? data;

  EventData({
    required this.id,
    required this.type,
    required this.timestamp,
    this.roomId,
    this.data,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] as String,
      roomId: json['room_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp,
      'room_id': roomId,
      'data': data,
    };
  }
}
