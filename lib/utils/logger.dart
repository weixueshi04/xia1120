import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(message, error: error, stackTrace: stackTrace);
    }
  }

  static void debug(String message) {
    log('🔍 $message');
  }

  static void info(String message) {
    log('ℹ️ $message');
  }

  static void success(String message) {
    log('✅ $message');
  }

  static void warning(String message) {
    log('⚠️ $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    log('❌ $message', error: error, stackTrace: stackTrace);
  }

  static void chat(String message) {
    log('💬 $message');
  }
}