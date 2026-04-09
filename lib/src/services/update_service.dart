import '../models/version.dart';
import 'http_client.dart';
import '../generated/version.g.dart';
import '../utils/ansi.dart';

class UpdateService {
  static const String _packageName = 'dart_helper_cli';
  static const String _updateCommand =
      'dart pub global activate dart_helper_cli';

  final HttpClient _httpClient;

  UpdateService(this._httpClient);

  Future<void> checkForUpdates() async {
    try {
      final currentVersion = await _getCurrentVersion();
      final latestVersion = await _httpClient.getLatestVersion();

      if (latestVersion == null) {
        return;
      }

      if (currentVersion < latestVersion) {
        _printUpdateNotice(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
        );
      }
    } catch (_) {
      // Без вывода ошибок
    }
  }

  Future<Version> _getCurrentVersion() async {
    try {
      return Version.parse(appVersion) ??
          const Version(major: 0, minor: 0, patch: 0);
    } catch (_) {
      return const Version(major: 0, minor: 0, patch: 0);
    }
  }

  void _printUpdateNotice({
    required Version currentVersion,
    required Version latestVersion,
  }) {
    final lines = [
      _formatLine(
        label: 'Package',
        value: Ansi.wrap(_packageName, Ansi.boldYellow),
      ),
      _formatLine(
        label: 'Current',
        value: Ansi.wrap('$currentVersion', Ansi.white),
      ),
      _formatLine(
        label: 'Latest',
        value: Ansi.wrap('$latestVersion', Ansi.green),
      ),
      _formatLine(
        label: 'Update',
        value: Ansi.wrap(_updateCommand, Ansi.magenta),
      ),
    ];

    final visibleWidth = lines
        .map(_visibleLength)
        .fold('Update available'.length, (a, b) => a > b ? a : b);
    final border = '+-${'-' * visibleWidth}-+';
    final title = '| ${_padVisible('Update available', visibleWidth)} |';

    print('');
    print(Ansi.wrap(border, Ansi.yellow));
    print(Ansi.wrap(title, Ansi.boldYellow));
    print(Ansi.wrap(border, Ansi.yellow));
    for (final line in lines) {
      final leftBorder = Ansi.wrap('|', Ansi.yellow);
      final rightBorder = Ansi.wrap('|', Ansi.yellow);
      print('$leftBorder ${_padVisible(line, visibleWidth)} $rightBorder');
    }
    print(Ansi.wrap(border, Ansi.yellow));
    print('');
  }

  String _formatLine({
    required String label,
    required String value,
  }) {
    return '${Ansi.wrap(label.padRight(7), Ansi.cyan)} $value';
  }

  int _visibleLength(String value) {
    return Ansi.strip(value).length;
  }

  String _padVisible(String value, int width) {
    final padding = width - _visibleLength(value);
    if (padding <= 0) {
      return value;
    }
    return '$value${' ' * padding}';
  }
}
