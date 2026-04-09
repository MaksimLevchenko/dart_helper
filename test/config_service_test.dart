import 'dart:io';

import 'package:dart_helper_cli/src/models/cli_config.dart';
import 'package:dart_helper_cli/src/services/config_service.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigService', () {
    late Directory tempDir;
    late File configFile;
    late ConfigService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dart_helper_config_');
      configFile = File('${tempDir.path}${Platform.pathSeparator}config.json');
      service = ConfigService(configFile: configFile);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns defaults when config file is missing', () async {
      final config = await service.readConfig();

      expect(config.fluttergenEnabled, isTrue);
      expect(config.useFvmByDefault, isFalse);
      expect(config.updateChecksEnabled, isTrue);
      expect(config.checkExcludePatterns, isEmpty);
      expect(config.colorEnabled, isTrue);
    });

    test('writes and reads all config values', () async {
      final expected = CliConfig(
        fluttergenEnabled: false,
        useFvmByDefault: true,
        updateChecksEnabled: false,
        checkDetailsByDefault: false,
        checkInteractiveByDefault: true,
        getAllTreeByDefault: false,
        checkExcludePatterns: const ['*.g.dart', '*.freezed.dart'],
        checkExcludeFolders: const ['generated', 'build'],
        colorEnabled: false,
      );

      await service.writeConfig(expected);
      final actual = await service.readConfig();

      expect(actual.fluttergenEnabled, expected.fluttergenEnabled);
      expect(actual.useFvmByDefault, expected.useFvmByDefault);
      expect(actual.updateChecksEnabled, expected.updateChecksEnabled);
      expect(actual.checkDetailsByDefault, expected.checkDetailsByDefault);
      expect(
        actual.checkInteractiveByDefault,
        expected.checkInteractiveByDefault,
      );
      expect(actual.getAllTreeByDefault, expected.getAllTreeByDefault);
      expect(actual.checkExcludePatterns, expected.checkExcludePatterns);
      expect(actual.checkExcludeFolders, expected.checkExcludeFolders);
      expect(actual.colorEnabled, expected.colorEnabled);
    });

    test('throws for invalid config values', () async {
      configFile.createSync(recursive: true);
      configFile.writeAsStringSync('{"color":"auto"}');

      expect(service.readConfig(), throwsFormatException);
    });
  });
}
