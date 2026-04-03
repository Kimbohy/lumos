import '../../domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.label,
    required super.pin,
  });

  factory RoomModel.fromJson(String key, Map<String, dynamic> json) {
    return RoomModel(
      id: key,
      label: json['label'] as String,
      pin: json['pin'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'pin': pin};
  }

  Room toEntity() {
    return Room(id: id, label: label, pin: pin);
  }
}
