import '../entities/room.dart';
import '../repositories/rooms_repository.dart';

class GetRooms {
  final RoomsRepository repository;

  GetRooms(this.repository);

  Future<List<Room>> call() async {
    return await repository.getRooms();
  }
}
