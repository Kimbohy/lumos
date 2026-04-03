import '../../domain/entities/room.dart';
import '../../domain/repositories/rooms_repository.dart';
import '../datasources/rooms_datasource.dart';
import '../../../../core/utils/logger.dart';

class RoomsRepositoryImpl implements RoomsRepository {
  final RoomsDatasource _datasource;

  RoomsRepositoryImpl(this._datasource);

  @override
  Future<List<Room>> getRooms() async {
    try {
      Logger.info('Fetching rooms from repository', 'RoomsRepository');
      final roomModels = await _datasource.fetchRooms();
      final rooms = roomModels.map((model) => model.toEntity()).toList();
      Logger.info(
        'Successfully fetched ${rooms.length} rooms',
        'RoomsRepository',
      );
      return rooms;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch rooms', 'RoomsRepository', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> checkHealth() async {
    try {
      return await _datasource.checkHealth();
    } catch (e) {
      Logger.error('Health check failed', 'RoomsRepository', e);
      return false;
    }
  }
}
