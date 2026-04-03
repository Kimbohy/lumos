import '../core/config/app_config.dart';
import '../features/rooms/data/datasources/rooms_datasource.dart';
import '../features/rooms/data/repositories/rooms_repository_impl.dart';
import '../features/rooms/domain/repositories/rooms_repository.dart';
import '../features/rooms/domain/usecases/get_rooms.dart';
import '../features/voice_control/data/datasources/audio_recorder_datasource.dart';
import '../features/voice_control/data/datasources/n8n_datasource.dart';
import '../features/voice_control/data/repositories/voice_repository_impl.dart';
import '../features/voice_control/domain/repositories/voice_repository.dart';
import '../features/voice_control/domain/usecases/record_and_send_command.dart';
import '../features/voice_control/domain/usecases/stop_recording.dart';

class Injection {
  static AppConfig? _config;

  // Singletons
  static AudioRecorderDatasource? _audioRecorder;
  static RoomsDatasource? _roomsDatasource;
  static N8nDatasource? _n8nDatasource;

  // Initialize with configuration
  static void init(AppConfig config) {
    _config = config;
  }

  // Configuration
  static AppConfig get config {
    _config ??= AppConfig.defaultConfig;
    return _config!;
  }

  // Datasources
  static AudioRecorderDatasource get audioRecorder {
    _audioRecorder ??= AudioRecorderDatasource();
    return _audioRecorder!;
  }

  static RoomsDatasource get roomsDatasource {
    _roomsDatasource ??= RoomsDatasource(config);
    return _roomsDatasource!;
  }

  static N8nDatasource get n8nDatasource {
    _n8nDatasource ??= N8nDatasource(config);
    return _n8nDatasource!;
  }

  // Repositories
  static RoomsRepository get roomsRepository {
    return RoomsRepositoryImpl(roomsDatasource);
  }

  static VoiceRepository get voiceRepository {
    return VoiceRepositoryImpl(audioRecorder, n8nDatasource);
  }

  // Use Cases
  static GetRooms get getRooms {
    return GetRooms(roomsRepository);
  }

  static RecordAndSendCommand get recordAndSendCommand {
    return RecordAndSendCommand(voiceRepository);
  }

  static StopRecording get stopRecording {
    return StopRecording(voiceRepository);
  }

  // Reset (for testing or reconfiguration)
  static void reset() {
    _config = null;
    _audioRecorder = null;
    _roomsDatasource = null;
    _n8nDatasource = null;
  }
}
