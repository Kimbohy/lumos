import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/voice_command_response_model.dart';

class N8nDatasource {
  final Dio _dio;
  final AppConfig _config;

  N8nDatasource(this._config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: _config.n8nBaseUrl,
          connectTimeout: Duration(
            seconds: AppConstants.connectionTimeoutSeconds,
          ),
          receiveTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (obj) => Logger.debug(obj.toString(), 'N8N'),
      ),
    );
  }

  Future<VoiceCommandResponseModel> sendAudioCommand(
    String audioFilePath,
  ) async {
    try {
      Logger.info('Sending audio to n8n: $audioFilePath', 'N8N');

      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw ValidationException('Audio file not found: $audioFilePath');
      }

      final fileSize = await file.length();
      Logger.info('Audio file size: $fileSize bytes', 'N8N');

      // Create multipart form data
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFilePath,
          filename: audioFilePath.split('/').last,
        ),
      });

      Logger.info('Sending POST request to ${ApiEndpoints.n8nWebhook}', 'N8N');

      // Send POST request
      final response = await _dio.post(ApiEndpoints.n8nWebhook, data: formData);

      Logger.info(
        'Received response with status: ${response.statusCode}',
        'N8N',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response
        final data = response.data;
        Logger.info('Response data: $data', 'N8N');

        if (data is Map<String, dynamic>) {
          return VoiceCommandResponseModel.fromJson(data);
        } else if (data is String) {
          // Handle plain text response
          return VoiceCommandResponseModel(
            success: true,
            message: data,
            transcription: data,
          );
        } else {
          throw ServerException('Unexpected response format');
        }
      } else {
        throw ServerException(
          'Server returned error: ${response.statusCode}',
          response.statusCode.toString(),
        );
      }
    } on DioException catch (e, stackTrace) {
      Logger.error('DioException occurred', 'N8N', e, stackTrace);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          'Request timeout. Please check your connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          'Cannot connect to server. Please check if n8n is running at ${_config.n8nBaseUrl}',
        );
      } else if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final message = e.response!.data?.toString() ?? 'Unknown error';
        throw ServerException(
          'Server error ($statusCode): $message',
          statusCode.toString(),
        );
      } else {
        throw NetworkException('Network error: ${e.message}');
      }
    } catch (e, stackTrace) {
      Logger.error('Unexpected error', 'N8N', e, stackTrace);

      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Unexpected error: ${e.toString()}');
    }
  }
}
