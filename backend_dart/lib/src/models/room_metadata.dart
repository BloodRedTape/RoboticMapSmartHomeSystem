class RoomMetadata {
  String guid;
  String name;

  RoomMetadata({
    required this.guid,
    required this.name,
  });

  factory RoomMetadata.fromJson(Map<String, dynamic> json) {
    return RoomMetadata(
      guid: json['guid'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'name': name,
    };
  }
}