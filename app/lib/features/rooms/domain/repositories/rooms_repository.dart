import '../entities/room.dart';

abstract class RoomsRepository {
  /// Fetch all available rooms from the Flask bridge
  Future<List<Room>> getRooms();

  /// Check if the Flask bridge is reachable
  Future<bool> checkHealth();
}
