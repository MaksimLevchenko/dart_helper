class Ansi {
  static bool enabled = true;

  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String gray = '\x1B[90m';
  static const String boldYellow = '\x1B[1;33m';
  static const String clearLine = '\x1B[K';

  static final RegExp _ansiPattern = RegExp(r'\x1B\[[0-9;]*[A-Za-z]');

  static String wrap(String text, String code) {
    if (!enabled) {
      return text;
    }

    return '$code$text$reset';
  }

  static String sequence(String code) {
    return enabled ? code : '';
  }

  static String strip(String value) {
    return value.replaceAll(_ansiPattern, '');
  }
}
