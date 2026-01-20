// logging.dart
import 'dart:io';

import 'package:logger/logger.dart';


class Log {
  static Logger? _logger;

  static Future<void> init() async {
    _logger = Logger(
      printer: PrettyPrinter(),
      output: MultiOutput([ConsoleOutput()]),
    );
  }

  static Logger get logger {
    if (_logger == null) {
      throw Exception('Logger is not initialized. Call Log.init() first.');
    }
    return _logger!;
  }


}
