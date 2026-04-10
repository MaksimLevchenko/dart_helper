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

    test('supports set add remove and clear for reverse ports', () async {
      await command.execute(
        args: ['reverse.ports', 'set', '8080', '8081', '8082'],
      );
      var config = await configService.readConfig();
      expect(config.reversePorts, [8080, 8081, 8082]);

      await command.execute(
        args: ['reverse.ports', 'add', '8090', '8080'],
      );
      config = await configService.readConfig();
      expect(config.reversePorts, [8080, 8081, 8082, 8090]);

      await command.execute(
        args: ['reverse.ports', 'remove', '8081'],
      );
      config = await configService.readConfig();
      expect(config.reversePorts, [8080, 8082, 8090]);

      await command.execute(args: ['reverse.ports', 'clear']);
      config = await configService.readConfig();
      expect(config.reversePorts, isEmpty);
    });

    test('throws for invalid reverse port values', () async {
      expect(
        command.execute(args: ['reverse.ports', 'set', 'abc']),
        throwsArgumentError,
      );

      expect(
        command.execute(args: ['reverse.ports', 'add', '70000']),
        throwsArgumentError,
      );
    });

    test('throws for invalid list action', () async {
      expect(
        command.execute(args: ['check.exclude-folder', 'replace', 'build']),
        throwsArgumentError,
      );
    });
  });
}
