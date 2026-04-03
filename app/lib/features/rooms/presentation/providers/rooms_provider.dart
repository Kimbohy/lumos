import 'package:flutter/foundation.dart';
import '../../domain/entities/room.dart';
import '../../domain/usecases/get_rooms.dart';
import '../../../../core/utils/logger.dart';

enum RoomsLoadingState { initial, loading, loaded, error }

class RoomsProvider extends ChangeNotifier {
  GetRooms _getRooms;

  RoomsLoadingState _state = RoomsLoadingState.initial;
  List<Room> _rooms = [];
  String? _errorMessage;

  RoomsProvider(this._getRooms);

  void updateDependency(GetRooms getRooms) {
    _getRooms = getRooms;
  }

  RoomsLoadingState get state => _state;
  List<Room> get rooms => _rooms;
  String? get errorMessage => _errorMessage;
  bool get hasRooms => _rooms.isNotEmpty;
  bool get isLoading => _state == RoomsLoadingState.loading;

  Future<void> loadRooms() async {
    try {
      Logger.info('Loading rooms', 'RoomsProvider');
      _state = RoomsLoadingState.loading;
      _errorMessage = null;
      notifyListeners();

      _rooms = await _getRooms();

      _state = RoomsLoadingState.loaded;
      Logger.info('Loaded ${_rooms.length} rooms', 'RoomsProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Failed to load rooms', 'RoomsProvider', e, stackTrace);
      _state = RoomsLoadingState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadRooms();
  }

  void reset() {
    _state = RoomsLoadingState.initial;
    _rooms = [];
    _errorMessage = null;
    notifyListeners();
  }
}
