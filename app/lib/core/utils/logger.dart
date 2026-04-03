import 'package:flutter/foundation.dart';

class Logger {
  static const String _prefix = '[Lumos]';

  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr DEBUG: $message');
    }
  }

  static void info(String message, [String? tag]) {
    final tagStr = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagStr INFO: $message');
  }

  static void warning(String message, [String? tag]) {
    final tagStr = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagStr WARNING: $message');
  }

  static void error(
    String message, [
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final tagStr = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagStr ERROR: $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
