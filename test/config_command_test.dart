import 'dart:io';

import 'package:dart_helper_cli/src/cli/help_printer.dart';
import 'package:dart_helper_cli/src/commands/config_command.dart';
import 'package:dart_helper_cli/src/services/config_service.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigCommand', () {
    late Directory tempDir;
    late File configFile;
    late ConfigService configService;
    late ConfigCommand command;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dart_helper_config_cmd_');
      configFile = File('${tempDir.path}${Platform.pathSeparator}config.json');
      configService = ConfigService(configFile: configFile);
      command = ConfigCommand(configService, HelpPrinter());
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('supports set add remove and clear for exclude patterns', () async {
      await command.execute(
        args: ['check.exclude-pattern', 'set', '*.g.dart', '*.freezed.dart'],
      );
      var config = await configService.readConfig();
      expect(config.checkExcludePatterns, ['*.g.dart', '*.freezed.dart']);

      await command.execute(
        args: ['check.exclude-pattern', 'add', '*.gen.dart', '*.g.dart'],
      );
      config = await configService.readConfig();
      expect(
        config.checkExcludePatterns,
        ['*.g.dart', '*.freezed.dart', '*.gen.dart'],
      );

      await command.execute(
        args: ['check.exclude-pattern', 'remove', '*.freezed.dart'],
      );
      config = await configService.readConfig();
      expect(config.checkExcludePatterns, ['*.g.dart', '*.gen.dart']);

      await command.execute(args: ['check.exclude-pattern', 'clear']);
      config = await configService.readConfig();
      expect(config.checkExcludePatterns, isEmpty);
    });

    test('throws for invalid list action', () async {
      expect(
        command.execute(args: ['check.exclude-folder', 'replace', 'build']),
        throwsArgumentError,
      );
    });
  });
}
