import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/room_model.dart';

class RoomsDatasource {
  final Dio _dio;
  final AppConfig _config;

  RoomsDatasource(this._config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: _config.flaskBaseUrl,
          connectTimeout: Duration(
            seconds: AppConstants.connectionTimeoutSeconds,
          ),
          receiveTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => Logger.debug(obj.toString(), 'Flask'),
      ),
    );
  }

  Future<List<RoomModel>> fetchRooms() async {
    try {
      Logger.info('Fetching rooms from Flask', 'RoomsDatasource');

      final response = await _dio.get(ApiEndpoints.flaskRooms);

      Logger.info(
        'Received response with status: ${response.statusCode}',
        'RoomsDatasource',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        Logger.info('Parsing ${data.length} rooms', 'RoomsDatasource');

        final rooms = data.entries
            .map(
              (entry) => RoomModel.fromJson(
                entry.key,
                entry.value as Map<String, dynamic>,
              ),
            )
            .toList();

        Logger.info(
          'Successfully parsed ${rooms.length} rooms',
          'RoomsDatasource',
        );
        return rooms;
      } else {
        throw ServerException(
          'Failed to fetch rooms: ${response.statusCode}',
          response.statusCode.toString(),
        );
      }
    } on DioException catch (e, stackTrace) {
      Logger.error('DioException occurred', 'RoomsDatasource', e, stackTrace);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Request timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          'Cannot connect to Flask bridge at ${_config.flaskBaseUrl}',
        );
      } else if (e.response != null) {
        throw ServerException(
          'Server error: ${e.response!.statusCode}',
          e.response!.statusCode.toString(),
        );
      } else {
        throw NetworkException('Network error: ${e.message}');
      }
    } catch (e, stackTrace) {
      Logger.error('Unexpected error', 'RoomsDatasource', e, stackTrace);

      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Unexpected error: ${e.toString()}');
    }
  }

  Future<bool> checkHealth() async {
    try {
      Logger.info('Checking Flask health', 'RoomsDatasource');

      final response = await _dio.get(ApiEndpoints.flaskHealth);

      return response.statusCode == 200;
    } catch (e) {
      Logger.error('Health check failed', 'RoomsDatasource', e);
      return false;
    }
  }
}
