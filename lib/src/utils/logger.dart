import 'ansi.dart';

class Logger {
  static void info(String message) =>
      _printWithPrefix('INFO', message, Ansi.cyan);

  static void success(String message) =>
      _printWithPrefix('SUCCESS', message, Ansi.green);

  static void warning(String message) =>
      _printWithPrefix('WARNING', message, Ansi.yellow);

  static void error(String message) =>
      _printWithPrefix('ERROR', message, Ansi.red);

  static void command(String message) =>
      _printWithPrefix('CMD', message, Ansi.magenta);

  static void _printWithPrefix(String prefix, String message, String color) {
    final timestamp = _getTimestamp();
    print('${Ansi.wrap('[$timestamp] [$prefix]', color)} $message');
  }

  static String _getTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}
