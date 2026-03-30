import '../models/version.dart';
import 'http_client.dart';
import '../generated/version.g.dart';

class UpdateService {
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
        print(
            '\x1B[33mA new version of dart_helper is available: $latestVersion (current: $currentVersion)\x1B[0m');
        print('Please update using "dart pub global activate dart_helper"');
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
}
