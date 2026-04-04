import '../models/version.dart';
import 'http_client.dart';
import '../generated/version.g.dart';

class UpdateService {
  static const String _reset = '\x1B[0m';
  static const String _titleColor = '\x1B[1;33m';
  static const String _borderColor = '\x1B[33m';
  static const String _labelColor = '\x1B[36m';
  static const String _currentColor = '\x1B[37m';
  static const String _latestColor = '\x1B[32m';
  static const String _commandColor = '\x1B[35m';
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
        value: '$_titleColor$_packageName$_reset',
      ),
      _formatLine(
        label: 'Current',
        value: '$_currentColor$currentVersion$_reset',
      ),
      _formatLine(
        label: 'Latest',
        value: '$_latestColor$latestVersion$_reset',
      ),
      _formatLine(
        label: 'Update',
        value: '$_commandColor$_updateCommand$_reset',
      ),
    ];

    final visibleWidth = lines
        .map(_visibleLength)
        .fold('Update available'.length, (a, b) => a > b ? a : b);
    final border = '+-${'-' * visibleWidth}-+';
    final title = '| ${_padVisible('Update available', visibleWidth)} |';

    print('');
    print('$_borderColor$border$_reset');
    print('$_titleColor$title$_reset');
    print('$_borderColor$border$_reset');
    for (final line in lines) {
      print('$_borderColor|$_reset ${_padVisible(line, visibleWidth)} $_borderColor|$_reset');
    }
    print('$_borderColor$border$_reset');
    print('');
  }

  String _formatLine({
    required String label,
    required String value,
  }) {
    return '$_labelColor${label.padRight(7)}$_reset $value';
  }

  int _visibleLength(String value) {
    return value.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').length;
  }

  String _padVisible(String value, int width) {
    final padding = width - _visibleLength(value);
    if (padding <= 0) {
      return value;
    }
    return '$value${' ' * padding}';
  }
}
